# 03 — Employee Chat (WhatsApp-style) Design

Goal: every employee can chat with every other employee inside the app, one-to-one and in groups, with the core WhatsApp experience. This means a chat list with unread counts, ✓ / ✓✓ / blue ✓✓ ticks, typing…, online / last seen, photos, files, voice notes, reply, delete, reactions and push notifications.

This is a **design + checklist**, not code.

---

## 1. Decisions needed before we start

> **Answered.** See [05-decisions.md](05-decisions.md). Final choices: Employees + Admins; anyone can chat/create groups; encryption at rest with a server-held key (a bot will read messages later); keep forever; voice notes but no calls; DigitalOcean Spaces; limits of 20 MB images, 100 MB files/video, 15 min voice. The table below is the original proposal.

| # | Question | Recommendation |
|---|---|---|
| D1 | Who can chat? Employees only, or employees + admins? | Employees + Administrators (admins can message drivers). Customers are **not** included. |
| D2 | Can any employee start a chat with any other employee? | Yes, everyone sees everyone (small team). |
| D3 | Who can create groups? | Any employee. An admin can add/remove anyone. |
| D4 | End-to-end encryption like WhatsApp? | **Not in v1.** Use TLS in transit plus server-side storage. E2E (Signal protocol) is a large separate project and blocks server features like search and admin oversight. |
| D5 | Message retention? | Keep forever in v1. Add an auto-delete policy later if needed. |
| D6 | Calls (voice/video)? | **Out of scope.** Would need WebRTC + TURN servers. Can be a later phase. |
| D7 | Where do media files live? | v1: the server's `uploads/chat/` (same as other uploads). Later: move to S3/Spaces/Cloud storage if volume grows. |
| D8 | Max file size? | Images 10 MB, video 25 MB, documents 25 MB, voice 5 min. |

## 2. Feature list (WhatsApp parity checklist)

**MVP (Phase 4)**
- [ ] Chats tab with a list of conversations: avatar, name, last message preview, time, unread badge, sorted by latest
- [ ] New chat: pick from employee contacts (search by name)
- [ ] 1-to-1 text messages, sent instantly over socket
- [ ] Ticks: ✓ sent (server saved), ✓✓ delivered (on recipient device), blue ✓✓ read
- [ ] Typing… indicator
- [ ] Online / last seen in the chat header
- [ ] Date separators ("Today", "Yesterday", date), message time, bubbles left/right
- [ ] Load older messages when scrolling up (pagination)
- [ ] Push notification when the app is in the background or closed; tap opens that chat
- [ ] Unread count badge on the Chats tab
- [ ] Messages queued while offline and sent when reconnected

**Rich messages (Phase 5)**
- [ ] Photos (camera/gallery) with caption, thumbnail + full-screen viewer
- [ ] Videos (short), documents (PDF etc.) with download
- [ ] Voice notes (hold to record, playback with progress)
- [ ] Share location (current GPS, opens maps), useful for drivers
- [ ] Reply to a message (swipe or long-press), quoted preview
- [ ] Forward a message
- [ ] Delete for me / delete for everyone ("This message was deleted"), time-limited
- [ ] Edit a sent text (time-limited, shows "edited")
- [ ] Emoji reactions
- [ ] Copy text, emoji keyboard
- [ ] Link-clickable text

**Groups (Phase 6)**
- [ ] Create group (name, photo, members)
- [ ] Group info screen: members, add/remove, make admin, leave group, change name/photo
- [ ] System messages ("Ali added Sara", "Group name changed")
- [ ] Sender name + colour on bubbles in groups
- [ ] Read receipts per member ("Read by" in message info)
- [ ] @mentions (optional)

**Polish (Phase 7)**
- [ ] Search chats and messages
- [ ] Pin, mute, archive chats
- [ ] Local message cache so chats open instantly and work offline (read-only)
- [ ] Contact info screen with shared media
- [ ] Starred messages (optional)

## 3. Database (MySQL, Sequelize migrations)

```
conversations
  id (PK), type ENUM('direct','group'), title NULL, avatarUrl NULL,
  createdBy FK users.id, lastMessageId NULL, lastMessageAt DATETIME,
  directKey VARCHAR UNIQUE NULL   -- "minUserId:maxUserId" stops duplicate 1-to-1 chats
  isActive, createdAt, updatedAt

conversation_participants
  id, conversationId FK, userId FK, role ENUM('admin','member'),
  joinedAt, leftAt NULL, lastReadMessageId NULL, lastDeliveredMessageId NULL,
  mutedUntil NULL, isPinned BOOL, isArchived BOOL, clearedAt NULL
  UNIQUE(conversationId, userId)

messages
  id (BIGINT PK), conversationId FK, senderId FK users.id NULL (NULL = system),
  type ENUM('text','image','video','audio','file','location','system'),
  body TEXT NULL, replyToMessageId NULL, forwarded BOOL,
  clientMessageId VARCHAR  -- made on the phone; stops duplicates on retry
  editedAt NULL, deletedForEveryoneAt NULL, createdAt
  INDEX(conversationId, id)   UNIQUE(senderId, clientMessageId)

message_attachments
  id, messageId FK, url, thumbnailUrl NULL, mimeType, fileName, sizeBytes,
  durationMs NULL, width NULL, height NULL, latitude NULL, longitude NULL

message_reactions
  messageId FK, userId FK, emoji VARCHAR(16), createdAt   PK(messageId,userId)

message_hidden            -- "delete for me"
  messageId FK, userId FK   PK(messageId,userId)

users  (+ columns)
  lastSeenAt DATETIME NULL
```

Notes:
- **Read state is stored per participant** (`lastReadMessageId`), not per message. That makes it cheap: unread count = messages after that id. For group "Read by" lists we can work it out from participants' `lastReadMessageId`, so no per-message receipt table is needed.
- Online state lives in **Redis** (`presence:<userId>` = number of open sockets, with expiry), not MySQL. Write `lastSeenAt` to MySQL on the last disconnect.
- Multiple devices per user: change `users.fcmToken` into a `user_devices` table (userId, fcmToken, platform, lastActiveAt) so phone and tablet both get pushes. Optional, but recommended.

## 4. REST API (`/api/chat/*`, JWT protected, Employee + Administrator only)

All ids are encrypted in and out, like the rest of the API.

| Method & path | Purpose |
|---|---|
| `POST /chat/contacts` | Employees (+ admins) you can chat with: id, name, photo, online, lastSeen |
| `POST /chat/conversations/list` | Your conversations with last message, unread count, pinned/muted/archived. Paged by `lastMessageAt`. |
| `POST /chat/conversations/direct` | Get or create a 1-to-1 chat with `userId` (uses `directKey`) |
| `POST /chat/conversations/group/create` | Create a group: title, memberIds, avatar |
| `POST /chat/conversations/detail` | Conversation info + participants |
| `POST /chat/conversations/update` | Rename, change photo (group admins) |
| `POST /chat/conversations/members/add` · `/remove` · `/role` | Manage group members |
| `POST /chat/conversations/leave` | Leave a group |
| `POST /chat/conversations/settings` | mute / pin / archive / clear chat for me |
| `POST /chat/messages/list` | Messages in a conversation, `beforeId` cursor, 30 per page |
| `POST /chat/messages/send` | Send (REST fallback; normal path is socket) |
| `POST /chat/upload` | multipart upload (field `file`) → returns attachment info. Makes image thumbnails. |
| `POST /chat/messages/edit` · `/delete` · `/react` · `/forward` | Message actions |
| `POST /chat/messages/read` | Mark read up to `messageId` |
| `POST /chat/search` | Search messages you can see |

Every endpoint must check that the caller is a **participant** of the conversation.

## 5. Real-time (socket.io)

**Rebuild `utils/socketService.js`:**
- Authenticate in the handshake: the app sends `auth: { token }` and the server verifies it with the same JWT as `jwt.protect`. Reject anything else. Stop trusting `?userId=`.
- Each socket joins room `user:<id>`, so all of a user's devices get events and `emitToUser` works for many devices.
- Presence: on connect, add one to `presence:<id>` in Redis; on disconnect, subtract one. At 0, set `lastSeenAt` and broadcast offline.
- If we ever run more than one Node process: add `@socket.io/redis-adapter` (Redis is already there).
- Production: the reverse proxy (nginx) must allow WebSocket upgrade on the socket.io path.

**Events**

| Direction | Event | Payload | Notes |
|---|---|---|---|
| app → server | `message:send` | conversationId, clientMessageId, type, body, attachmentIds, replyToId | Server saves it and **acks** with the saved message (✓ sent) |
| server → app | `message:new` | full message | Sent to the other participants' `user:<id>` rooms |
| app → server | `message:delivered` | conversationId, upToMessageId | Sent when the message arrives on the device |
| app → server | `message:read` | conversationId, upToMessageId | Sent when the chat is open and visible |
| server → app | `receipt:update` | conversationId, userId, deliveredUpTo, readUpTo | Sender updates ticks |
| app → server | `typing` | conversationId, isTyping | Throttled; server relays it and never saves it |
| server → app | `typing` | conversationId, userId, isTyping | |
| server → app | `presence` | userId, online, lastSeenAt | Sent to that user's contacts |
| server → app | `message:updated` / `message:deleted` / `reaction` | … | edits, deletes, reactions |
| server → app | `conversation:updated` | conversation | New group, rename, members changed |

**Push (FCM):** when a message is saved, send FCM to every participant who is not muted. It goes to all of their devices. Even if they are online, the app shows nothing for the chat that is currently open. Use a **data** payload: `type=chat`, `conversationId`, `messageId`, sender name and preview, so the app can show a proper notification and deep-link. Use a notification tag per conversation, so several messages collapse into one notification.

## 6. Flutter app

**New packages (need approval before install):**

| Package | For |
|---|---|
| `socket_io_client` | real-time connection |
| `flutter_local_notifications` | show chat notifications in the foreground, grouped per chat |
| `cached_network_image` | avatars, photo thumbnails |
| `record` + `just_audio` | voice notes |
| `video_player` | video messages (Phase 5) |
| `emoji_picker_flutter` | emoji keyboard |
| `drift` (or `sqflite`) | local message cache / offline (Phase 7) |
| `uuid` | `clientMessageId` |
| `photo_view` | zoomable full-screen image viewer |

Already installed: `image_picker`, `file_picker`, `geolocator`, `firebase_messaging`, `url_launcher`.

**App structure**
```
lib/chat/
  data/  chat_api.dart (REST), chat_socket.dart (connect/reconnect/events),
         chat_repository.dart (merges REST + socket + local cache), models/
  state/ ChangeNotifier/Bloc per conversation list & per chat; outbox queue for offline sends
  ui/    ChatsTab, NewChatScreen, NewGroupScreen, ChatScreen, MessageBubble,
         AttachmentSheet, VoiceRecorderButton, MediaViewer, GroupInfoScreen,
         ContactInfoScreen, MessageInfoScreen
```

**Screens**
- **Bottom bar:** becomes `Home · Jobs · Chats · Alerts · Settings` (5 tabs), with an unread badge on Chats.
- **Chats tab:** search bar, list, floating "new chat" button, archived row.
- **Chat screen:**
  - Header: avatar, name, online / "last seen …" / "typing…".
  - Messages: list that starts from the bottom, bubbles with time + ticks, date chips, swipe to reply.
  - Long-press menu: reply, copy, forward, react, edit, delete, info.
  - Input bar: emoji, text, attach (camera, gallery, document, location), and mic/send.
- **Theme:** use the app colours (`colors.primaryNew` teal, `colors.secondarynew` green) and the white top bar style, so chat matches the rest of the app.

**Lifecycle**
- Connect the socket after login, or when the app comes to the foreground.
- Disconnect when it goes to the background, after a short delay. Push covers the background.
- On reconnect, fetch missed messages with `messages/list?afterId=` for each open chat.

## 7. Security & limits

- Only participants can read a conversation's messages or files. Media URLs should go through an auth check, **not** a public static folder, so `uploads/chat` is not openly downloadable.
- Rate-limit sending (e.g. 20 messages / 10 s per user) and uploads.
- Check MIME type and size on upload. Strip EXIF GPS from photos unless shared as a location.
- Clean message text on display (the app renders it as plain text, never HTML).
- An admin "view conversations" ability, if wanted, must be an explicit decision (privacy).
