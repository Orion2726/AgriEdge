# AgriEdge P2P Disease Alert Protocol — Implementation Plan

Status: **§9 phases 1-5 implemented** (`app/lib/core/p2p/`). Phase 6 (Wi-Fi
Direct / Multipeer high-throughput upgrade path) is not built. This document
turns the architecture described in
`AgriEdge_Inventive_Disclosure_Context_Aware_Agricultural_P2P_Network.docx`
into a concrete design for this codebase, scoped to the app's existing
**nearby disease alerts** feature. It also documents what was deliberately
borrowed from, and deliberately rejected from, the IETF draft
`draft-sharma-oepb-00` ("Offline Emergency Peer-to-Peer Broadcast Protocol",
June 2026) — see the comparison at the end of this document.

## What's actually verified vs. not

This environment has no physical BLE hardware and no second device, so the
one thing that can't be verified here is **real over-the-air peer discovery
and exchange** — §9 phase 1's two-device test. Everything else has real
automated coverage:

- **Packet codec, signing, relevance scoring, local storage, TTL/dedup,
  aggregation clustering**: 30 passing unit tests (`app/test/p2p/`), run
  against a real in-memory SQLite database via `AppDatabase.forTesting()`
  — not mocked.
- **Compiles and links on a real platform**: built and launched on iOS
  Simulator with the `bluetooth_low_energy` native plugin linked in via
  CocoaPods; app launches without crashing.
- **`BleTransport.start()` itself**: exercised directly against the real
  `bluetooth_low_energy` platform channel (not mocked) via a throwaway
  verification entrypoint. This caught a real bug — see below — now fixed
  and re-verified.

**Bug found and fixed during verification**: `start()` originally called
`startAdvertising()`/`startDiscovery()` without checking adapter state
first. On iOS Simulator (no real BLE radio, state stuck at `unsupported`),
both calls hang forever — no exception, no timeout, nothing. Fixed by
waiting for `poweredOn` with an 8-second timeout before either call,
throwing a clear `StateError` naming the actual adapter state on failure.
Re-verified: now fails in exactly 8 seconds with
`Bluetooth did not reach poweredOn within 0:00:08.000000 (state:
BluetoothLowEnergyState.unsupported)` instead of hanging — this is also
exactly the error a real-device tester would see if Bluetooth is off or the
permission prompt was declined, so it's not just a simulator workaround.

**Library choice note**: the plan originally didn't commit to a specific BLE
package. `flutter_blue_plus` (the obvious first choice) turned out to
support **central role only** — it can scan for peers but can't make the
phone advertise itself as discoverable, which silently breaks symmetric
phone-to-phone discovery (two phones running it could each scan, but
neither would be visible to the other). Switched to `bluetooth_low_energy`,
which implements both central and peripheral roles on Android and iOS.

## 0. Why this is scoped to disease alerts only

The disclosure describes a general-purpose carrier for disease alerts, prices, MSP,
soil observations and advisories. Building a generic P2P transport *and* a
generic context engine *and* wiring five feature types into it in one pass is a
large amount of new surface area (new native platform code, new background-execution
constraints, new security design) to ship untested. This plan builds the protocol
for **disease alerts only** — the one feature in the app that already has a
server-side analog to mirror (`backend/src/routes/alerts.js`'s grid clustering,
the local `DiseaseAlerts` Drift table) — and leaves the packet format generic
enough (a `type` byte, §3) that prices/MSP/soil can reuse the same transport later
without protocol changes.

## 1. The hard constraint this plan is built around: there is no real cross-OS P2P radio

This is the part the disclosure doesn't engage with, and it determines almost
every other decision below.

- **BLE** is the only radio both platforms expose with roughly equivalent, mutually
  interoperable central+peripheral (GATT) APIs. It is low-throughput (realistically
  low kB/s for advertisement-based discovery, tens of kB/s for an active GATT
  connection) and both OSes restrict background scanning/advertising.
- **Wi-Fi Direct** is Android-only. There is no public Wi-Fi Direct API on iOS.
- **Multipeer Connectivity** is iOS-only (and macOS/tvOS). It cannot talk to
  an Android device.
- **Google Nearby Connections** has SDKs for both, but under the hood it still
  composes BLE + Wi-Fi Direct + Wi-Fi hotspot per-platform — it doesn't solve the
  iOS Wi-Fi Direct gap, it just hides the composition. Still worth evaluating as
  a pre-built option (§8) instead of hand-rolling.
- **Local Wi-Fi LAN** (mDNS/Bonjour + sockets) works cross-platform cleanly, but
  only when both devices already share an access point — which doesn't hold in
  the disclosure's core scenario (two farmers meeting in a field with no router).
- **Background execution**: iOS does not allow general background BLE peer
  discovery the way the disclosure assumes ("device carries a packet, meets a
  peer later"). Background BLE on iOS only wakes the app for *previously bonded*
  peripherals advertising a *specific known service UUID* — broad background
  "scan for any AgriEdge phone nearby" is not available. Android is less
  restrictive but increasingly aggressive about background scanning too (Doze,
  background location permission requirements for BLE scan results).
  OEPB's own spec admits this directly: *"No always-on smartphone operation:
  foreground service required."* Assume the same here.

**Design consequence**: this is built as a **foreground-session, BLE-first**
protocol. "Two farmers meet" means the app is open on both phones (e.g. at a
village market, a cooperative meeting, a extension-worker visit) — not an
always-on background mesh. Wi-Fi Direct (Android) / Multipeer (iOS) are added
later as a **same-platform high-throughput upgrade path** when both peers
happen to run the same OS, not as the baseline.

## 2. Transport Abstraction Layer (the "OS-agnostic network stack")

Borrowed directly from OEPB's TAL concept: present every radio as one uniform
Dart interface so the context/relevance engine (§4) never touches
platform-specific code.

```
lib/core/p2p/
  transport/
    p2p_transport.dart          # abstract interface, below
    ble_transport.dart          # cross-platform baseline
    wifi_direct_transport.dart  # Android-only upgrade path
    multipeer_transport.dart    # iOS-only upgrade path
    transport_manager.dart      # picks/combines transports per peer
  packet/
    p2p_packet.dart             # wire format (§3)
    packet_codec.dart           # encode/decode
  relevance/
    relevance_engine.dart       # scoring (§4)
    relevance_profile.dart      # this device's crop/location profile
  store/
    p2p_packet_store.dart       # Drift table + dedupe/TTL (§5)
  aggregation/
    local_aggregator.dart       # regional event fusion (§6)
  sync/
    p2p_gateway_sync.dart       # bridges into existing SyncManager (§7)
  security/
    device_identity.dart        # keypair, signing (§9)
  p2p_alert_service.dart        # public facade the disease_alerts feature calls
```

```dart
abstract class P2pTransport {
  String get transportId; // 'ble' | 'wifi_direct' | 'multipeer'
  bool get isAvailable;   // platform/hardware support check

  Stream<PeerId> get peerDiscovered;
  Stream<PeerId> get peerLost;

  /// Uniform datagram send — implementations chunk internally if the
  /// underlying radio has a smaller MTU (BLE GATT characteristic writes are
  /// typically ~185-512 bytes depending on negotiated MTU).
  Future<void> send(PeerId peer, Uint8List datagram);

  Stream<ReceivedDatagram> get incoming;

  Future<void> start();
  Future<void> stop();
}

class ReceivedDatagram {
  const ReceivedDatagram({required this.from, required this.bytes});
  final PeerId from;
  final Uint8List bytes;
}
```

`TransportManager` holds a `List<P2pTransport>`, starts whichever are
`isAvailable` on the current platform (BLE always; Wi-Fi Direct only on
Android; Multipeer only on iOS), de-duplicates peers seen on multiple
transports by exchanging a stable device ID in the handshake, and prefers the
highest-throughput available transport per peer for actual payload transfer —
mirroring OEPB's "per-transport Trickle instance, shared dedup cache" pattern,
except here it's "per-transport link, shared peer identity."

**BLE library: `bluetooth_low_energy`**, not `flutter_blue_plus` —
`flutter_blue_plus` only implements BLE **central** role (it can scan, but
can't make the device advertise/be discovered), which silently breaks
symmetric phone-to-phone discovery. `bluetooth_low_energy` implements both
`CentralManager` and `PeripheralManager` on Android and iOS — see the
verification notes at the top of this doc. `wifi_direct_transport.dart` /
`multipeer_transport.dart` (phase 6) remain unbuilt; Google Nearby
Connections bindings or native platform channels (iOS Multipeer has no
mature Flutter plugin) are still the candidates when that phase happens.

## 3. Packet format

OEPB's lesson here is worth taking directly: **keep the header fixed and tiny,
keep payload small, make the dedup ID deterministic.** The disclosure's "bytes
to several MB" payload range is not realistic for a BLE-first transport.

```
┌─────────────────────────────────────────────────────────────┐
│ version (1B) │ type (1B) │ ttlHops (1B) │ flags (1B)         │  4
│ createdAtEpochSeconds (4B)                                   │  4
│ nonce (8B)                                                   │  8
│ packetId (16B)  -- SHA-256(type‖createdAt‖nonce‖payload)[:16]│  16
├─────────────────────────────────────────────────────────────┤  = 32B header
│ payload (CBOR, ≤160B target)                                 │
├─────────────────────────────────────────────────────────────┤
│ signature (64B, Ed25519) — present iff flags.SIGNED           │  optional +64B
└─────────────────────────────────────────────────────────────┘
```

- `type`: `0x01 DISEASE_ALERT` for this phase; reserve `0x02..0x05` for
  price/MSP/soil/advisory later, matching the disclosure's multi-type vision
  without committing to their design yet.
- `ttlHops`: unlike OEPB (hop-count TTL for a <5-second broadcast window),
  this needs **time-based** TTL too, since packets persist for days — payload
  carries an explicit `expiresAt` field; `ttlHops` just bounds worst-case
  replication fan-out per physical encounter.
- `packetId`: deterministic, same rationale as OEPB — two devices that
  independently relay the same observation must agree on one ID so dedup
  actually works, and it must exclude mutable relay-path fields.
- Payload fields for `DISEASE_ALERT` (CBOR map): `cropId`, `label` (disease
  class), `confidence`, `severity`, `latE6`/`lngE6` (microdegree ints, like
  OEPB's WGS84 microdegree convention — avoids float encoding overhead),
  `observedAt`, `expiresAt`, `sourceDeviceId`.

## 4. Relevance / forwarding engine

Concretizes the disclosure's `R = wG·G + wC·C + wS·S + wT·T + wQ·Q − wD·D`
against this app's actual data:

- **G (geographic)**: haversine distance (reuse the exact function already in
  `backend/src/routes/alerts.js`) between the packet's lat/lng and this
  device's last-known location (from the existing `geolocator` integration
  used by soil reports / disease detections), decayed over a configurable
  radius (reuse `MIN_CLUSTER_SIZE`/`GRID_DEGREES`-style constants).
- **C (crop relevance)**: 1.0 if `cropId` is in the user's registered crop
  profile (new: a simple local preference, `List<String>` of crop ids the
  farmer grows — doesn't exist yet, needs a small settings addition), else a
  low baseline (not zero — a neighboring farmer growing a different crop may
  still want to know an outbreak is nearby).
- **S (severity)**: carried directly in the packet payload.
- **T (freshness)**: `1 - (now - observedAt) / (expiresAt - observedAt)`.
- **Q (confidence)**: the disease model's own softmax confidence, already
  computed by `TFLiteDiseaseService` — this is free, it's already on the
  packet.
- **D (duplication/cost)**: 1.0 if this device has already forwarded this
  `packetId` to this specific peer before (tracked in the packet store, §5),
  else 0.

Weights start as constants (`wG=0.3, wC=0.25, wS=0.2, wT=0.15, wQ=0.1`),
forward iff `R >= threshold` (configurable, default 0.4) — exactly the
disclosure's model, just with concrete sources for each term instead of
"implementation parameters."

## 5. Local packet store (Drift)

```dart
class P2pPackets extends Table {
  TextColumn get packetId => text()();        // hex, primary key
  IntColumn get type => integer()();
  TextColumn get cropId => text()();
  TextColumn get label => text()();
  RealColumn get confidence => real()();
  TextColumn get severity => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  DateTimeColumn get observedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  TextColumn get sourceDeviceId => text()();
  TextColumn get receivedFromPeerId => text().nullable()();
  TextColumn get forwardedToPeerIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get aggregationGroupId => text().nullable()();
  BoolColumn get syncedToBackend => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {packetId};
}
```

Dedup check on receive: `packetId` already present → drop (OEPB's exact
pattern, just persistent instead of a 24h in-memory cache, since store-carry-
forward needs it to survive app restarts). Expiry: a periodic sweep
(reuse the existing `SyncManager` periodic-job pattern) deletes rows past
`expiresAt`.

## 6. Local aggregation

Directly reuses the existing grid-cell clustering algorithm from
`backend/src/routes/alerts.js`, ported to Dart and run against the local
`P2pPackets` table instead of the backend's SQLite `detections` table: same
`GRID_DEGREES` cell bucketing, same `MIN_CLUSTER_SIZE` threshold, same
centroid/earliest-timestamp output shape — so a locally-aggregated event and a
backend-aggregated `DiseaseAlerts` row are structurally the same thing and can
share one Dart model and one list UI (`disease_alerts_screen.dart` already
exists and already renders `DiseaseAlerts`-shaped data).

## 7. Gateway sync — reusing the existing SyncManager

No new sync mechanism needed. Register a `p2p_alerts` job with the existing
`SyncManager` (`core/sync/sync_manager.dart`), same pattern as every other
domain: when online, POST accumulated un-synced `P2pPackets` rows to a new
`POST /api/p2p-events` backend endpoint (mirrors `POST /api/detections`),
mark `syncedToBackend = true`. Pull direction: extend the existing
`GET /api/alerts/nearby` response (or poll it more aggressively) so backend-
validated/enriched alerts flow back down and can be handed to the P2P layer
for further local propagation — this is the disclosure's "opportunistic
gateway" concept, and it's a small addition to code that already exists.

## 8. Security

Adopt OEPB's concrete design rather than the disclosure's "future extension":

- **Device identity**: Ed25519 keypair generated on first launch, private key
  in platform secure storage (`flutter_secure_storage`, backed by iOS Keychain
  / Android Keystore). Public key doubles as `sourceDeviceId`.
- **Signing**: sign `(type, createdAt, nonce, packetId, payload)` — same field
  selection rationale as OEPB (excludes mutable/relay fields, includes
  `packetId` for immutability binding).
- **Relay-trust asymmetry**: a relay forwards signed packets whose signature
  it has *not* verified (keeps forwarding cheap/fast, matches OEPB) — the
  **consuming** app layer (the alerts screen, the local aggregator) verifies
  before showing anything to a farmer or folding it into an aggregate.
  Unsigned packets are still forwarded (so a phone with a dead crypto
  implementation doesn't break the mesh) but are flagged as "unverified" in
  the UI, never silently trusted.
- **Rate limiting**: cap accepted packets per source device per time window
  (OEPB's numbers — 30/60s general, stricter for anything self-reported
  without corroboration — are a reasonable starting point) to bound a
  malicious or buggy peer's ability to flood the mesh.
- **No CANCEL mechanism in phase 1** — the disclosure doesn't describe one and
  disease alerts aren't a false-alarm-retraction-critical use case the way
  OEPB's EVAC/SOS classes are; revisit if misreporting turns out to be a real
  problem.

## 9. Phased build order

1. **Foreground BLE proof of concept, 2 devices.** `BleTransport` only,
   `TransportManager` with a single backend. No relevance engine yet — forward
   everything. Confirms peer discovery + datagram exchange actually works on
   real hardware before building anything on top. Matches the disclosure's own
   §15 validation plan and its "3-5 Android smartphones" prototype plan.
2. **Packet store + relevance engine.** Wire §3-§5. Confirms selective
   forwarding behaves like the disclosure's worked example (Farmer A→B
   forwards, B→C doesn't).
3. **Local aggregation.** Wire §6, reusing the ported clustering function.
4. **Gateway sync.** Wire §7 into the existing `SyncManager`.
5. **Security.** Wire §8. Do this before any real-device pilot leaves a
   controlled test group — unsigned/unverified packets reaching real farmers
   is a trust/misinformation risk, not just a protocol nicety.
6. **High-throughput upgrade path.** `WifiDirectTransport` (Android) /
   `MultipeerTransport` (iOS) for same-platform peers, once BLE-only is
   proven. This is additive — the relevance engine and packet store don't
   change, only `TransportManager`'s transport selection.

## 10. Validation metrics

Reuse the disclosure's §15 list directly — it's a sound experimental plan and
doesn't need reinventing: delivery ratio, end-to-end delivery delay,
transmissions-per-delivered-packet, duplicate rate, expired-packet rate,
battery consumption, local storage usage. Add one OEPB-inspired metric:
**suppression rate** (packets not forwarded due to relevance threshold vs.
duplicate detection, broken out separately) — useful for tuning the weights
in §4 the same way OEPB tuned its Trickle `k` constant against simulation
data before committing to a default.

## 11. What this deliberately does NOT adopt from OEPB

- **Trickle suppression** — redundancy counting makes sense for a <5s flood
  broadcast; it has no clear meaning for packets that persist for days and get
  carried across asynchronous encounters. Relevance-threshold suppression
  (the disclosure's actual contribution) stays.
- **Stateless relay** — the disclosure's core idea *is* that relays are
  stateful (they store, score, and selectively carry). Adopting OEPB's
  stateless-relay model would just make this OEPB with worse latency
  characteristics for a use case OEPB wasn't designed for.
- **5-class WFQ taxonomy** — disease alerts don't currently need discrete
  priority classes with fixed bandwidth shares; the continuous relevance score
  already orders a single device's limited forwarding opportunities. Revisit
  if prices/MSP/soil get added later and genuinely compete for airtime.
- **Sub-100ms latency target** — not a goal here at all; store-carry-forward
  over hours/days is the explicit point.
