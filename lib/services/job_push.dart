import 'package:flutter/foundation.dart';

/// Bumped whenever a job-related push arrives while the app is open, so the
/// employee screens can refresh their job list and unread badge.
final ValueNotifier<int> jobPushTick = ValueNotifier<int>(0);

/// Push `type` values sent by the backend for jobs (utils/jobNotifications.js).
const String jobPushType = 'Job';
