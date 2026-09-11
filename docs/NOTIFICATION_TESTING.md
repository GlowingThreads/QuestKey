# Quest reminder notifications: on-device test checklist

Reminders are scheduled by `QuestListProvider.saveQuest` through
`NotificationService` (`flutter_local_notifications`, inexact alarms) and fire
**30 minutes before** a quest's due time. These checks need a **physical
Android device or emulator**; they cannot be automated in `flutter test`.

Test on at least one Android 13+ device (runtime notification permission) and,
if possible, one Android 12 or lower device (no runtime permission).

## Setup

- [ ] Install a fresh build: `flutter run` (or install the release APK).
- [ ] Note the device's timezone (Settings → System → Date & time). Reminder
      times below are local wall-clock times.

## 1. Permission prompt (Android 13+)

- [ ] Create a hero if none exists, open the **Create** tab.
- [ ] Tick **Remind me when due**. The system notification-permission dialog
      appears (only the first time the box is ticked; not at app start).
- [ ] Tap **Allow**. The box stays ticked, no SnackBar.

## 2. Reminder fires while the app is in the background

- [ ] Fill in a title/description, pick a due time **35 minutes** from now
      (reminder = due − 30 min = ~5 minutes from now), keep **Remind me**
      ticked, tap **Create Quest**.
- [ ] Press Home to background the app (do not swipe it away yet).
- [ ] Within roughly 5–7 minutes (inexact alarms may be delayed slightly) a
      "Quest Reminder" notification appears: *"<title>" is due soon…*.
- [ ] Repeat with the app swiped away from Recents: the reminder still fires.

## 3. Reminder time already in the past

- [ ] Create a quest due **10 minutes** from now with **Remind me** ticked.
- [ ] On submit a SnackBar says no reminder was scheduled.
- [ ] Open the quest again from the Quest Log: the **Remind me** box is
      unticked (the flag was stored as `false`).
- [ ] No notification arrives.

## 4. Editing a quest

- [ ] Create a quest due 40 minutes out with reminder on.
- [ ] Edit it, untick **Remind me**, save. Wait past the reminder time: **no**
      notification.
- [ ] Edit it again, tick **Remind me**, move the due time to 35 minutes out,
      save. Exactly **one** notification arrives at the new time (the old one
      was cancelled and rescheduled, not duplicated).

## 5. Completing cancels the reminder

- [ ] Create a quest due 35 minutes out with reminder on.
- [ ] On the Home or Quest Log tab swipe it **right** to complete it.
- [ ] Wait past the reminder time: **no** notification.

## 6. Deleting cancels the reminder

- [ ] Create a quest due 35 minutes out with reminder on.
- [ ] Swipe it **left** to delete it.
- [ ] Wait past the reminder time: **no** notification.

## 7. Reminder survives a reboot

- [ ] Create a quest due **45 minutes** out with reminder on.
- [ ] Reboot the device (`adb reboot` or power menu). Unlock it after boot.
- [ ] Do **not** open the app. At ~15 minutes after creation the reminder
      fires. This exercises `RECEIVE_BOOT_COMPLETED` and
      `ScheduledNotificationBootReceiver` in the manifest.

## 8. Permission denied is handled gracefully

- [ ] Uninstall/reinstall (or clear app data) to reset the permission.
- [ ] Tick **Remind me**, tap **Don't allow** in the system dialog.
- [ ] The box unticks itself and a SnackBar explains that notifications are
      off and can be enabled in system settings. Saving the quest works and
      schedules nothing.
- [ ] Enable notifications in Settings → Apps → Quest Key → Notifications,
      return to the app, tick the box again: it stays ticked without a crash.

## 9. Release build (after Phase 4)

- [ ] Repeat checks 1, 2 and 5 on `flutter build apk --release` output. R8
      must not strip the notification icon (`@mipmap/ic_launcher`) or the
      plugin's receivers; a missing icon shows up as a notification that never
      appears.

## Troubleshooting

- Reminder never fires: check `adb logcat | grep -i notif`, confirm the app
  is not in a battery-restricted bucket (Settings → Apps → Quest Key →
  Battery → Unrestricted), and that the device's Do Not Disturb is off.
- Fires at the wrong hour: the timezone lookup fell back to UTC. Look for
  `NotificationService: could not determine local timezone` in logcat.
