# 01 — Current State Audit (Employee features)

In the backend the role is called **Employee** (`roles.id = 2`). In the app the code calls them **Driver** (`lib/pages/driver/`). After login, `roleTitle == "Employee"` sends the user to `DriverMainScreen` (Home / Jobs / Notifications / Settings).

Backend paths are shown with the `/api` prefix used in development. In production the same routes have **no** `/api` prefix (see `routes/routes.js`).

Legend: ✅ works · ⚠️ works with problems · ❌ broken / not wired up

---

## A. Features the employee uses

| # | Feature (app) | App code | Backend endpoint | Status | Notes |
|---|---|---|---|---|---|
| 1 | Login as employee | `LoginScreen.dart`, `general_repository.dart` login | `POST /api/auth/...` | ✅ | FCM token is sent at login and saved on `users.fcmToken`. |
| 2 | Job list: Active | `DriverHome.dart`, `DriverJobsScreen.dart` → `getBookingsForDriver()` | `POST /api/booking/list` → `listForEmployee` | ⚠️ | Only returns assignments with status exactly `"Assigned"`. A job reassigned to you gets status `"Reassigned"`, so it **disappears** from both lists. |
| 3 | Job list: Completed | same | same | ❌ | Filters on `bookingAssignments.status === "Completed"`, which **nothing ever sets**. Always empty. |
| 4 | Job detail | `BookingDetailDriver.dart` | none; uses data from the list | ⚠️ | "Car Model" shows `vehicleColour`. Uses `.first` on registrations/vehicles, so a booking without them would crash. `listForEmployee` inner-joins Registration + Vehicle, so such bookings are hidden from the list anyway. |
| 5 | Start job (pickup checkpoint + photos) | `BookingDetailDriver._showStartPopup` → `submitCheckpoint()` | `POST /api/booking/checkpoints/create` (multipart, up to 5 `pictures`) | ⚠️ | Saves the checkpoint and sets `bookings.status = "Started"`. Problems are listed below the table. |
| 6 | End job (dropoff checkpoint + photos) | same | same | ⚠️ | Sets `bookings.status = "Completed"`, but **not** the assignment status, which is the cause of #3. The "not today" message shows the *start* date. |
| 7 | View car location (maps) | `driver_helpers.openBookingLocation` | `POST /api/booking/detail/location` | ❌ | Returns `bookings.latitude/longitude`. These are only written by `POST /api/booking/create/location`, which **no screen calls**. Always "No location found". |
| 8 | WhatsApp the customer | `BookingDetailDriver._launchWhatsApp` | none (device only) | ⚠️ | Uses the raw `phoneNo`. Without a country code, WhatsApp opens the wrong number or fails. |
| 9 | Notifications list / read / clear | `NotificationsScreenDriver.dart` | `POST /api/notification/list`, `/update`, `/delete` | ⚠️ | The endpoints work, but almost nothing creates employee notifications (see #10). Tapping a notification only finds bookings in `Globals.reservedParkings`. |
| 10 | Push when a job is assigned / reassigned / cancelled / reminder | none | `bookingAssignment.create/update`, `utils/cornJob.js` | ❌ | All `sendFcmNotification` / `sendSocketNotification` calls for employees are **commented out**. |
| 11 | Edit profile / photo | `EditProfile.dart` (shared) | `POST /api/users/update/profile`, `/update/image` | ✅ | Shared with customers. |
| 12 | Change password | Settings → `MyRoutes.forgot` | `POST /api/users/update/password` exists | ⚠️ | The app sends the user to the *forgot password* (OTP) flow, not a change-password form. |
| 13 | Delete account | Settings (shared) | `POST /api/users/delete` | ⚠️ | No role check. An employee can delete their own account and leave assigned jobs pointing at a deleted user. Should be hidden for employees. |
| 14 | Logout | Settings (shared) | none | ⚠️ | Clears local storage only. `users.fcmToken` stays on the server, so a logged-out phone **still gets pushes**. `Globals.user` is not cleared. |

### Checkpoint (Start/End) problems in detail
- **Backend:**
  - Does not check that the caller is actually assigned to the booking.
  - Does not check order: you can drop off without a pickup, or record duplicates.
  - `files.forEach` crashes if the request has no files.
- **Frontend:**
  - `submitCheckpoint` is not awaited, so failures are not caught.
  - The photo list is shared between Start and End and never cleared.
  - Location is typed by hand. `geolocator` is already in `pubspec.yaml` but unused.
  - The date check uses the phone's date only.
  - After success it pushes `/driverhome`, which is fine with the new shell.

## B. Admin features that manage employees

| # | Feature (app) | App code | Backend endpoint | Status | Notes |
|---|---|---|---|---|---|
| 15 | List employees (+ their assignments) | `DriverListScreen.dart`, `AdminHome.dart` | `POST /api/users/list/employees` (admin only) | ✅ | |
| 16 | Create employee | `AddEditDriverScreen.dart` → `signupv2` | auth signup | ✅ | Check the new user really gets role 2 (Employee). |
| 17 | Edit employee | `AddEditDriverScreen.dart` → `updateDriver` | `POST /api/users/update` | ✅ | |
| 18 | Delete / deactivate employee | `DriverListScreen.dart` | none dedicated | ❌ | The call is commented out in the app. No "deactivate employee" endpoint. |
| 19 | Assign employee to booking | `admin/ViewAllScreen.dart` → `assignDriver` | `POST /api/booking/assignment/create` | ✅ | No notification is sent (see #10). |
| 20 | Reassign booking to another employee | none | `POST /api/booking/assignment/update` | ❌ (no UI) | The endpoint exists. Sets status `"Reassigned"`, which breaks #2. |
| 21 | See checkpoints + photos for a booking | `BookingDetailUser.dart` (images) | `POST /api/booking/assignment/list` includes checkpoints | ✅ | |

## C. Backend building blocks we can reuse

- **socket.io 4.8.** `utils/socketService.js` is connected to the HTTP server, but:
  - Identity comes from `?userId=` in the query, with **no JWT check**.
  - It keeps one socket per user in an in-memory `Map`, so a second device replaces the first, and it breaks with more than one server process.
  - No rooms, no events beyond `emitToUser`.
- **Redis (`ioredis`).** Already connected in `app.js`. Can be used for presence/online status and the socket.io Redis adapter.
- **Firebase Admin.** `utils/notificationsHelper.sendFcmNotification` works and removes dead tokens. It sends `notification` only, with no `data` payload, so a tap can't deep-link.
- **multer uploads.** `utils/fileUpload` writes to `uploads/<folder>`.
- **Database.** MySQL via Sequelize, schema changes via `migrations/`. `app.js` also runs `sequelize.sync()`.
- **IDs are encrypted** in API responses (`encryptHelper`) and decrypted on input (`crypto.decrypt`). Every new endpoint must follow the same pattern.
- **App packages already installed:**
  - `image_picker`, `file_picker`, `geolocator`, `firebase_messaging`.
  - **No** socket client, audio recorder or local database yet.
