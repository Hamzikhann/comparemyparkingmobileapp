import 'package:flutter/foundation.dart';

class OfflineNotifier extends ValueNotifier<bool> {
  OfflineNotifier(super.value);

  void setOfflineStatus(bool status) {
    value = status;
  }

  bool getOfflineStatus() {
    return value;
  }
}

OfflineNotifier offlineNotifier = OfflineNotifier(false);
