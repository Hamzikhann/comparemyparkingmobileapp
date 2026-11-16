# 02 — Required Fixes for Existing Employee Features

What has to change so the current employee features are correct and complete. Numbers like (#3) point to rows in [01-current-state-audit.md](01-current-state-audit.md).

BE = backend (`E:\parkpilotNode`), FE = Flutter app (`E:\ParkingApp`).

---

## Priority 1: the job flow is broken

| ID | Side | Change | Fixes |
|---|---|---|---|
| F1 | BE | In `bookingCheckpoint.controoler.js`, on `type == "dropoff"` also set the booking's assignment to `status = "Completed"`. On `"pickup"`, set it to `"Started"` (or keep `"Assigned"` and use `bookings.status`; pick one source of truth). | #3, #6 |
| F2 | BE | `listForEmployee`: treat `Assigned`, `Reassigned` and `Started` as **active**, and `Completed` as **completed**. Better still, return one list with a clear `jobStatus` field. Use `required: false` on Registration/Vehicle so bookings missing them still show. | #2, #3 |
| F3 | BE | Checkpoint create: check that the caller is the assigned employee; allow `pickup` only once and before `dropoff`; handle no files (`req.files || []`); return clear 4xx errors. | #5, #6 |
| F4 | FE | `BookingDetailDriver`: await `submitCheckpoint`, close the popup on success, clear photos between Start/End, use separate controllers for Start vs End, require location + at least one photo, fix the End "not today" message (use `endDate`). | #5, #6 |
| F5 | FE | Job detail: "Car Model" should show the model field (check the vehicle model name in the API) and colour as its own row. Replace `.first` with safe access. | #4 |

## Priority 2: location and notifications

| ID | Side | Change | Fixes |
|---|---|---|---|
| F6 | FE | When the employee submits a checkpoint (pickup = car collected and parked, dropoff = car returned), get GPS with `geolocator` and call `POST /api/booking/create/location` (already exists). Also auto-fill the checkpoint "Location" field from GPS + reverse geocode, or keep it manual with GPS as extra data. Needs Android/iOS location permission text. | #7 |
| F7 | BE | Store the GPS on the **checkpoint** too (add `latitude`, `longitude` columns to `bookingCheckPoints`), so pickup and dropoff positions are both kept. `detail/location` returns the latest. Migration needed. | #7 |
| F8 | BE | Re-enable notifications, written as one helper that does FCM + socket + DB row: on assign (to employee + customer), on reassign (old + new employee), on cancel (cron), and a day-before reminder (cron). Add a FCM `data` payload (`type`, `bookingId`) so a tap can deep-link. | #9, #10 |
| F9 | FE | Handle notification taps (foreground, background, terminated) and open the right job. Show an unread badge on the Notifications tab. Refresh the job list when an "assignment" push arrives. | #9, #10 |

## Priority 3: account and admin

| ID | Side | Change | Fixes |
|---|---|---|---|
| F10 | BE | New `POST /api/auth/logout` (or `/users/fcm/clear`) that sets `fcmToken = null` for that user/device. | #14 |
| F11 | FE | Logout: call F10, clear `Globals.user` + storage, go to the login screen. Use one shared logout function everywhere. | #14 |
| F12 | FE | Settings for employees: hide "Delete Account"; add a real **Change Password** form (old + new) using `POST /api/users/update/password`. | #12, #13 |
| F13 | BE | `POST /api/users/delete`: block self-delete for Employee/Administrator, or require an admin. Add `POST /api/users/deactivate` (admin) that sets `isActive = "N"` and frees open assignments. | #13, #18 |
| F14 | FE | Admin: wire up Deactivate employee in `DriverListScreen`. Add a **Reassign** action on assigned bookings that calls `POST /api/booking/assignment/update`. | #18, #20 |
| F15 | FE | WhatsApp link: normalise the phone to international format (e.g. UK `07…` → `447…`) before building the URL. | #8 |

## Nice to have (not required to ship)

- `POST /api/booking/assignment/detail` already exists. The app could load a fresh job detail (with package + checkpoints) instead of reusing list data.
- Employee "today" view: jobs grouped by date and time, sorted soonest first.
- Show the checkpoint history (pickup/dropoff photos) on the employee's job detail.
- Server-side date check for start/end (the phone's clock can be wrong).

## Things to confirm with the business (affect F1/F2)

1. Which statuses exist for a job (Assigned → Started → Completed / Cancelled), and is `bookings.status` or `bookingAssignments.status` the source of truth?
2. Can a booking have two employees (one for pickup, one for return)? The current model assumes one assignment per booking.
3. Should the customer also be notified when the driver starts or ends the job?
