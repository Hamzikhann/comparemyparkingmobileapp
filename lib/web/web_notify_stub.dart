// Phone build: no-ops (see web_notify.dart).

bool get webPageInBackground => false;

/// First click on the page: ask for notification permission, enable sound.
void webUnlockAlerts() {}

void webShowNotification(String title, String body,
    {String? tag, void Function()? onClick}) {}

void webSetUnreadCount(int count) {}

void webBeep() {}
