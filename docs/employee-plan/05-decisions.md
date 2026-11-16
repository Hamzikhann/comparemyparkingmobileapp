# 05 — Decisions (agreed 2026-11-11)

These answers replace the open questions and recommendations in 02 and 03. Where another file says something different, **this file wins**.

## Chat

| # | Topic | Decision | Impact on the plan |
|---|---|---|---|
| D1 | Who can chat | **Employees + Administrators.** Customers are not included. | `/chat/*` allows the `Employee` and `Administrator` roles only. Admins get a Chats entry in their app too. |
| D2/D3 | Starting chats / groups | **Anyone can message anyone and create groups.** Admins can add/remove members of any group. | No extra permission levels beyond group admin/member, plus a global admin override. |
| D4 | Encryption | **Encrypted at rest with a server-held key**, plus HTTPS/WSS in transit. A **message-reading bot/API will be added after deployment**, so the server must be able to decrypt. | See "Encryption design" below. True end-to-end encryption is **not** used. |
| D5 | Retention | **Keep forever.** Users can delete their own messages. | No cleanup job. |
| D6 | Calls | **Voice notes yes; no voice or video calls.** | No WebRTC. Voice notes stay in Phase 5. |
| D7 | Media storage | **DigitalOcean Spaces from day one.** | Private bucket, uploads with short-lived signed URLs. See "Storage design". Needs a Spaces bucket + access keys (Phase 0). |
| D8 | File limits | **Images 20 MB, files/video 100 MB, voice notes 15 min.** | Large files must upload **directly from the phone to Spaces** (not through Node). Show upload progress, allow cancel/retry. Compress images before upload; consider video compression. |
| P | Flutter packages | **All approved; chosen by us for a stable, smooth app.** | See "Packages" below. |

### Encryption design (D4)
- **In transit:** HTTPS for the API and WSS for socket.io (production already uses HTTPS).
- **Message text at rest:**
  - `messages.body` is stored encrypted with **AES-256-GCM**. Each message gets its own random IV.
  - The stored value is `keyVersion:iv:ciphertext:authTag`.
- **Keys:**
  - The key lives in a server env var (`CHAT_DATA_KEY_v1`), never in the database or the app.
  - `keyVersion` allows key rotation later without re-encrypting old messages at once.
- **Media at rest:** a private Spaces bucket with server-side encryption. Files are only reachable through signed URLs that expire after a few minutes, handed out after a participant check.
- **Search (Phase 7):** encrypted text can't be searched with SQL `LIKE`. Options: decrypt + search per conversation on the server, or a separate search index (decide in Phase 7).
- **Future bot/API (after deployment):**
  - An internal, separately authenticated service account that decrypts through one `chatCrypto.decrypt()` module.
  - Every bot read is written to an **audit log** (who, which conversation, when).
  - The app's privacy text should tell employees that company systems can process chat messages.
- **Not covered:** someone with both server access and the env key can read messages. That is the accepted trade-off for the bot.

### Storage design (D7 + D8)
- Bucket layout: `chat/<conversationId>/<yyyy>/<mm>/<uuid>.<ext>`, plus `chat-thumbs/…` for image/video thumbnails.
- Upload flow:
  1. The app calls `POST /chat/upload/init` (type, size, mime). The server checks the limits and returns a **pre-signed PUT URL**.
  2. The app uploads straight to Spaces, with a progress bar.
  3. The app calls `POST /chat/upload/complete`. The server checks the object exists and makes the thumbnail.
  4. The message is then sent with that attachment id.
- Download flow: the message carries the attachment id. The app asks for a signed GET URL (cached until it expires).
- Backend package: `@aws-sdk/client-s3` + `@aws-sdk/s3-request-presigner` (Spaces is S3-compatible). Needs approval when we start.

### Packages (Flutter), approved
| Package | Why | Phase |
|---|---|---|
| `socket_io_client` | real-time messages, ticks, typing, online | 4 |
| `flutter_local_notifications` | chat notifications in the foreground, grouped per chat | 4 |
| `cached_network_image` | fast avatars/photos, less data use | 4 |
| `uuid` | `clientMessageId`, stops duplicate sends | 4 |
| `emoji_picker_flutter` | emoji keyboard | 4 |
| `record` + `just_audio` | voice notes (up to 15 min) | 5 |
| `video_player` | play video messages | 5 |
| `photo_view` | pinch-to-zoom photo viewer | 5 |
| `flutter_image_compress` | already installed; shrink photos before upload | 5 |
| `video_compress` | shrink videos before uploading 100 MB-class files | 5 (if needed) |
| `drift` | local message cache: instant open + offline reading | 7 |

Versions must match the project's Flutter 3.41.9 / Gradle 8.10.2 / AGP 8.7.0 setup. Build files are **not** upgraded without asking.

### Presence (online / last seen), Phase 3
- Kept **in memory** in the Node process (`utils/chatPresence.js`), not Redis. The backend runs as one process, so this is exact and never goes stale after a restart. A Redis counter would show users "online" forever after a crash.
- If the backend is ever run as several processes, move presence to Redis **together with** `@socket.io/redis-adapter` (Phase 7).

## Jobs (employee flow)

| Topic | Decision | Impact |
|---|---|---|
| Source of truth | **`bookingAssignments.status`**: `Assigned → Started → Completed` (or `Cancelled`). `bookings.status` is kept in sync from it. | F1/F2: checkpoints update the assignment status first, then the booking. Reassignment keeps status `Assigned` for the new employee (no separate `Reassigned` status, or a history table if an audit trail is needed). |
| Employees per booking | **One employee per booking** (does both pickup and return). | No schema change. |
| Customer notifications | **When the car is collected (Start) and when it is returned (End).** Not on assignment. | F8: notify the customer on pickup + dropoff checkpoints. On assign/reassign, only the employee(s) are notified. |
| Car location (F6/F7) | **The customer shares their pickup point** (saved on `bookings.latitude/longitude`). The employee's Location button opens it in maps. **Only for Meet and Greet bookings.** Replaces the checkpoint-GPS idea; no migration. | Customer: "Share pickup location" button on Meet and Greet bookings. Employee: Location button only on Meet and Greet jobs. Backend: only the booking's customer/admin can set it, only the assigned employee/customer/admin can read it, and non-Meet-and-Greet is rejected. |

## Project setup

| Topic | Decision |
|---|---|
| Stripe key | **Leave the live key as is.** We won't touch booking/payment flows in this work. Don't make real payments while testing. |
| Git branches | **Decide at commit time.** Ask before creating branches or committing. |
| Test data | **We write a seed script** for the **local** database only: 1 admin, 3+ employees, sample bookings assigned to them. |

## Still needed from you before the matching phase starts

- **Phase 3 (chat backend):** DigitalOcean Spaces bucket name, region/endpoint, access key + secret, for local and production.
- **Phase 4 (chat app):** confirmation that the iOS APNs key is set up in Firebase. Android pushes already work.
- **Phase 7:** the production server's reverse proxy (nginx?) access, for the WebSocket upgrade config.
