# Employee App — Audit & Build Plan

Plan for the **employee (driver)** side of the Compare My Parking app: what works today, what is broken or missing, and how we build an in-app **WhatsApp-style chat** between employees.

- Frontend: Flutter app, `E:\ParkingApp` (branch `ios`)
- Backend: Node/Express + Sequelize (MySQL) + socket.io, `E:\parkpilotNode`
- Audit date: 2026-11-11. No code was changed during the audit.

## Files

| File | What it covers |
|---|---|
| [01-current-state-audit.md](01-current-state-audit.md) | Every employee feature the app offers, the backend endpoint behind it, and whether it actually works end to end |
| [02-required-fixes.md](02-required-fixes.md) | The list of backend and frontend changes needed to make the existing employee features correct and complete |
| [03-chat-system-design.md](03-chat-system-design.md) | Design for the WhatsApp-style employee chat: features, database tables, API, socket events, push, Flutter screens and packages |
| [04-phased-plan.md](04-phased-plan.md) | The work split into phases, with tasks, owners (BE/FE) and "done when" checks |
| [05-decisions.md](05-decisions.md) | **Agreed decisions** (chat scope, encryption, storage, limits, packages, job statuses). These override 02/03 where they differ. |

## Summary

**Existing employee features:** the screens exist and mostly talk to real endpoints, but the core job flow is broken in three places:

1. **Completed jobs never show as completed.** Ending a job sets `bookings.status = "Completed"`, but the job list sorts by `bookingAssignments.status`, which is never changed from `"Assigned"`. Finished jobs stay in *Active* forever and *Completed* is always empty.
2. **"View Location" can never show anything.** It reads the booking's latitude/longitude, but no screen in the app ever saves them.
3. **Employees are never told about new jobs.** The push/socket notifications on assignment are commented out in the backend.

There are also several smaller bugs and security gaps (see 02).

**Chat:** nothing exists yet for messaging. We do have useful building blocks already: socket.io 4.8 and Redis on the backend, Firebase push working in the app, and file uploads (multer + image_picker/file_picker). The socket layer has to be rebuilt properly (it is unauthenticated and holds one socket per user), and we need new tables, endpoints and screens.

## Phase overview

| Phase | Goal | Size |
|---|---|---|
| 0 | Decisions + setup | S |
| 1 | Fix the broken employee job flow | M |
| 2 | Finish missing employee features | M |
| 3 | Chat backend foundation | L |
| 4 | Chat MVP in the app (1-to-1 text, ticks, typing, online, push) | L |
| 5 | Media & rich messages (photos, files, voice notes, reply, delete, reactions) | L |
| 6 | Group chats | M |
| 7 | Polish, offline cache, search, production rollout | M |

S = a few days, M = about 1–2 weeks, L = 2–3+ weeks (one developer per side). Rough guide only.
