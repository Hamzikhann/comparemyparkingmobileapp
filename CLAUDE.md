# Compare My Parking: mobile app (Flutter)

Context for Claude Code. Written 2026-11-17 on the Windows dev PC, carried over from that machine's session memory.
Treat it as background: verify against the code before relying on a detail.

## What this is

- Flutter app for Compare My Parking (UK airport parking). Roles: customer (`User` / `GuestUser`), `Employee` (drivers/jockeys), `Administrator`.
- Package ids: Android `com.stn00.parkingapp22`; iOS bundle `com.comparemyparking` (Apple team BC93M26DDS). Repo: https://github.com/Hamzikhann/comparemyparkingmobileapp, branch `main` (pushed from the Windows PC's local branch `ios` on 2026-11-17).
- Other repos (separate):
  - **Backend** "parkpilotNode": Node/Express + Sequelize, MySQL (DigitalOcean managed), Redis, Socket.IO, Stripe, Firebase push. Live at https://comparemyairportparking.com; nginx proxies only `/api/*` to Node and strips `/api`. Production runs with `NODE_ENV` not `development`, so routes are mounted without `/api` behind nginx and `/upload` etc. require a token.
  - **Website** "airportparking-frontend-next": Next.js, includes the admin panel.
- `lib/data/api/config.dart`: `useLocalBackend` (false = live). Chat socket path on live is `/api/socket.io`; uploaded files at `/api/uploads/...`. The domain stanstedairportparking247.com is dead and was removed; don't reintroduce it.
- Stripe key in `lib/main.dart` is the LIVE key on purpose (user decision).

## How the user wants to work

- **Never commit or push** any repo until the user explicitly says so.
- Work phase by phase; after coding, the user tests on a phone before the next step.
- Ask before changing build files (Gradle, Podfile, Xcode project settings) or installing anything.
- Keep token use low: no unnecessary searches or re-reads.
- Don't run seed scripts against the live database. Production migrations: `npx sequelize-cli db:migrate --env production` (the `test` env has no port and times out). The user runs SQL in MySQL Workbench (DB `compareparkingdbnew`).

## Toolchain

- **Flutter 3.41.9 exactly** (matches pubspec.lock and the project's Gradle 8.10.2 / AGP 8.7.0 / Kotlin 2.1.0). Newer Flutter needs build-file upgrades the user declined.
- Mac (iOS builds): see `docs/mac-build-setup.md` (and the PDF next to it).
- Windows PC notes: release builds need lower Gradle memory:
  `GRADLE_OPTS='-Dorg.gradle.jvmargs="-Xmx3g -XX:MaxMetaspaceSize=768m -XX:ReservedCodeCacheSize=256m" -Dkotlin.compiler.execution.strategy=in-process'`.
  No `android/key.properties` there, so release APKs are debug-signed (test only). Store builds need the Play upload keystore.
- Tests: `test/customer_flow_test.dart` (pure Dart), `test/live_api_test.dart` (read-only checks against a backend).

## What has been built (state on 2026-11-17)

**Employee app + chat** (plan in `docs/employee-plan/`, decisions in `05-decisions.md`): phases 1-6 done and phone-tested (jobs, checkpoints, chat 1:1 + groups, media, voice notes, reactions, edit/delete, forward, push). Phase 7a (local chat cache, pin/mute/archive, search, contact info, shared media) coded. Chat code in `lib/chat/`. Chat media is stored on the server's local disk until full testing; DigitalOcean Spaces later.

**Customer flow aligned with the website** (search -> package details -> book -> pay):
- Airports from `GET /api/site-config`, package details from `/api/search/v5/package/:id`; checkout uses `/api/auth/v1/signup` (no password; existing email logs into that account, as on the website).
- Booking date change: server computes the price (`/api/booking/change/quote`, `/change/payment-intent`); rule = flat change fee (default £20) + per extra day (default £15) only when the new stay is longer; fees per airport in admin. Helpers in `lib/data/booking_flow.dart`.

**2026-11-16/17 fixes** (app + backend + website):
- Bus Tracking button on bookings: shows when `busTrackingLink` is set. Backend copies the airport's link (admin Airports page field, airports.busTrackingLink) onto every new non-Meet-and-Greet booking; Stansted seeded by migration `20261116000000-airport-bus-tracking-link.js`.
- Push token: app sends it on start and on Firebase refresh (`lib/services/push_token.dart`, `POST /api/users/fcm-token`); logout clears it only if it's still that phone's. One token per user (latest phone wins).
- Notifications list uses the user from the login token. A 500 on that screen was still unexplained on 2026-11-17 (waiting for the server log).
- Security: payment list/detail and booking detail no longer leak other customers' data to `GuestUser`; public signups ignore `roleId`; checkout accounts get random passwords (was `guest123`); `/auth/verify` no longer returns the code; users can only update their own account.
- App forgot password: login screen link -> `lib/pages/ResetPasswordScreen.dart` -> emailed 6-digit code (`/api/auth/v2/forgot/password`, `/v2/forgot/verify`, `/v2/reset/password`; codes in Redis, 10 min, 5 tries) -> new password -> logged straight in. Website keeps its emailed-link reset.
- Claim external booking (Home screen, by registration): "already claimed" (external API 409) now shows a dialog and creates no duplicate.
- App errors show the server's `message` instead of Dio's generic text (`lib/data/api/api_service.dart`).
- Admin logout buttons in the app use `logoutAndGoToLogin` (`lib/services/auth_actions.dart`).
- Website admin: Create Employee modal on Users page; Edit User fixed (title/name/phone); employee deactivate.

## Deliberately NOT done (user decisions, don't re-propose as new findings)

- Password hashing: passwords are plain text; user will decide later.
- Checkout logs an existing customer email in without a password (website flow is intended; keep for now).
- Normal signup with an existing email logs into it; booking create takes `userId` from the request body.
- Bulk-upload bookings don't get the bus tracking link.

## Next steps (as of 2026-11-17)

1. User deploys backend + website, runs the pending migration and the `guest123` SQL, then tests the latest APK with the team.
2. Store builds: iOS on the Mac (`flutter build ipa`, TestFlight), Android app bundle with the Play upload keystore. Raise the version in `pubspec.yaml` first (was `1.0.1+8`).
3. Before iOS release: APNs key in Firebase, Apple Pay merchant `merchant.com.comparemyparking`, push capability.
