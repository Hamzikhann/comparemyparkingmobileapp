# 04 — Phased Plan

Each phase ends with something we can test on a phone. BE = backend (`parkpilotNode`), FE = Flutter app. Task IDs F1–F15 are explained in [02-required-fixes.md](02-required-fixes.md). Chat details are in [03-chat-system-design.md](03-chat-system-design.md).

---

## Phase 0: Decisions & setup (S)

- [x] Business questions in 02 answered (see [05-decisions.md](05-decisions.md))
- [x] Chat decisions D1–D8 answered (see 05)
- [x] Flutter packages approved (see 05)
- [ ] Seed script for test data on the **local** backend: 1 admin, at least 3 employee accounts, a few bookings assigned to them
- [x] Stripe: leave the live key; no booking/payment work in this project
- [ ] Branch strategy: decide at commit time
- [ ] DigitalOcean Spaces bucket + keys (needed before Phase 3 media work)

**Done when:** decisions are written down and the local setup has test employees + bookings.

## Phase 1: Fix the broken employee job flow (M)

| Task | Side |
|---|---|
| F1: dropoff sets assignment `Completed` (pickup → `Started`) | BE |
| F2: `listForEmployee` returns correct active/completed lists, includes `Reassigned`, no inner-join loss | BE |
| F3: checkpoint validation (assigned employee, order, no-files crash) | BE |
| F4: Start/End popup fixes (await, close, clear photos, validation, End date message) | FE |
| F5: job detail fields (car model vs colour, safe `.first`) | FE |

**Done when:** an employee can Start, then End, a job on the phone. The job moves from Active to Completed. Photos show for the admin and customer. Bad requests get clear errors.

## Phase 2: Finish missing employee features (M)

| Task | Side |
|---|---|
| F6/F7: GPS captured at checkpoints → "View Location" works | FE + BE (migration) |
| F8: notifications on assign / reassign / cancel / reminder, with FCM data payload | BE |
| F9: notification tap opens the job; unread badge; auto refresh | FE |
| F10/F11: proper logout (clear FCM token on server + app state) | BE + FE |
| F12/F13: employee settings (change password form, no self-delete), admin deactivate | FE + BE |
| F14: admin Deactivate employee + Reassign booking in the app | FE |
| F15: WhatsApp phone number formatting | FE |

**Done when:** an admin assigns a job, the employee's phone gets a push, the tap opens the job, the employee finishes it with GPS + photos, and the admin can see where the car is. Logged-out phones get no pushes.

## Phase 3: Chat backend foundation (L)

- [ ] Migrations: `conversations`, `conversation_participants`, `messages`, `message_attachments`, `message_reactions`, `message_hidden`, `users.lastSeenAt` (optional: `user_devices`)
- [ ] Sequelize models + associations
- [ ] Rebuild `socketService`: JWT handshake auth, `user:<id>` rooms, Redis presence
- [ ] REST: contacts, conversations list/direct/detail, messages list/send/read
- [ ] Socket events: `message:send` (with ack), `message:new`, `message:delivered`, `message:read`, `receipt:update`, `typing`, `presence`
- [ ] FCM chat push with data payload, respecting mute
- [ ] Participant permission check on every endpoint/event; rate limiting
- [ ] Postman collection + a small socket test script (two fake users chatting)

**Done when:** two test users can chat through the script/Postman: messages saved, delivered/read updates, typing and presence events arrive, and push is sent when the other user is offline.

## Phase 4: Chat MVP in the app (L)

- [ ] Install approved packages (`socket_io_client`, `flutter_local_notifications`, `cached_network_image`, `uuid`, `emoji_picker_flutter`)
- [ ] `chat_socket.dart`: connect after login, reconnect, background/foreground handling
- [ ] Chats tab in the employee bottom bar with unread badge
- [ ] Chat list screen, New chat (contacts) screen
- [ ] Chat screen: bubbles, ticks, date separators, typing, online/last seen, pagination, emoji
- [ ] Outbox: send while offline, retry, no duplicates (`clientMessageId`)
- [ ] Push: foreground local notification, tap opens chat, no alert for the chat that is open
- [ ] Android + iOS notification permission / channel setup

**Done when:** on two real phones, two employees chat 1-to-1 in real time, ticks go ✓ → ✓✓ → blue, typing and online work, and a closed app gets a push that opens the right chat.

## Phase 5: Media & rich messages (L)

- [ ] BE: `/chat/upload` (auth-protected download, thumbnails, size/MIME limits), edit/delete/react/forward endpoints + socket events
- [ ] FE: attachment sheet (camera, gallery, document, location)
- [ ] FE: photo/video messages + full-screen viewer; document download/open
- [ ] FE: voice notes (`record` + `just_audio`): hold to record, slide to cancel, playback
- [ ] FE: reply (swipe), forward, delete for me/everyone, edit, reactions, copy, clickable links

**Done when:** every message type in 03 §2 "Rich messages" works between two phones, including after reopening the app.

## Phase 6: Group chats (M)

- [ ] BE: group create/update/members/leave + system messages + `conversation:updated` event
- [ ] FE: New group (pick members, name, photo), group chat bubbles with sender names, Group info screen (add/remove/admin/leave), message info "Read by"

**Done when:** a group of 3+ employees can chat with media, members can be added and removed, and everyone sees the system messages.

## Phase 7: Polish & production rollout (M)

- [ ] Local cache (`drift`) so the chat list and recent messages open instantly and offline
- [ ] Search chats and messages; pin / mute / archive; contact info with shared media
- [ ] Performance: message list with thousands of messages, image memory, battery (socket in background)
- [ ] Production: nginx WebSocket upgrade config, socket.io Redis adapter if more than one process, uploads folder backup, monitoring/logging
- [ ] Set `AppConfig.useLocalBackend = false` and test against staging/production
- [ ] Store release: Android/iOS permission texts (microphone, camera, location, notifications), privacy policy update for chat

**Done when:** the feature runs on the production server for the real team with no crashes for a week.

---

## Suggested order and dependencies

```
Phase 0 ─► Phase 1 ─► Phase 2
   │
   └────► Phase 3 ─► Phase 4 ─► Phase 5 ─► Phase 6 ─► Phase 7
```

Phases 1–2 (job flow) and Phase 3 (chat backend) can run **in parallel** if one person works on the backend and another on the app. Phase 4 needs Phase 3 done first. Phase 2's notification work (F8/F9) shares the FCM data-payload and deep-link code with chat, so build that code once, in a reusable way.
