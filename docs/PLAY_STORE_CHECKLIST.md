# Play Store internal-testing checklist

Everything below has to be provided in the Play Console or produced by hand;
none of it lives in the repository. Items marked **(blocking)** stop the
release from being reviewed or rolled out.

## Build inputs still missing from the repo

- [ ] **(blocking)** Real image assets in `assets/images/` (see
      `assets/REQUIRED_ASSETS.md`). The app builds without them but every
      screen shows broken images.
- [ ] **(blocking)** Launcher icon sources in `assets/icon/` and a run of
      `dart run flutter_launcher_icons` (see `assets/icon/README.md`).
      Until then the app ships with the default Flutter icon.
- [ ] **(blocking)** Upload keystore + `android/key.properties`
      (`docs/RELEASE.md`). Debug-signed bundles are rejected.
- [ ] Verified on a device: install release APK, create hero + quest, kill
      and relaunch, data persists, reminder fires
      (`docs/NOTIFICATION_TESTING.md`).

## Play Console: app setup

- [ ] **(blocking)** Google Play developer account (one-time registration
      fee; identity verification can take days: start early).
- [ ] App name "Quest Key", default language, app or game = **App**,
      free or paid = **Free**.
- [ ] Package name is fixed at `com.glowingthreads.quest_key` once the first
      bundle is uploaded. It cannot be changed afterwards.
- [ ] Internal testers list (email addresses of up to 100 testers).

## Store listing

- [ ] Short description (max 80 characters), e.g. "Turn your to-do list into
      RPG quests. Earn XP, level up your hero."
- [ ] Full description (max 4000 characters).
- [ ] **(blocking)** App icon: 512×512 PNG, 32-bit, ≤ 1 MB (export from the
      same source as `assets/icon/app_icon.png`).
- [ ] **(blocking)** Feature graphic: 1024×500 PNG or JPEG, no alpha.
- [ ] **(blocking)** Phone screenshots: at least 2 (up to 8), 16:9 or 9:16,
      each side 320–3840 px. Suggested set: Home (hero card + quest list),
      Quest Log, Create Quest, Hero page with stats, level-up popup.
      Take them from an emulator with the real assets installed.
- [ ] Optional: 7-inch and 10-inch tablet screenshots (the layout is
      portrait phone only; if you skip these, deselect tablets in device
      catalog or expect a "designed for phones" note).
- [ ] App category (Productivity), contact email (required; shown publicly),
      optional website.

## Policy declarations (App content section)

- [ ] **(blocking) Privacy policy URL.** Required for every app that
      declares permissions such as `POST_NOTIFICATIONS`. It must be a public
      URL (a GitHub Pages page is fine) that states, truthfully for this
      app:
      - Quest Key stores the hero and quest data **only on the device**
        (SharedPreferences).
      - It sends **nothing to any server** and has no network permission or
        analytics/crash SDKs.
      - Notifications are local reminders scheduled on the device.
      - Uninstalling the app deletes all data; "Clear Hero Data" in the
        Info tab deletes it in-app.
      - Contact email for questions.
- [ ] **(blocking) Data safety form.** Answer as follows (matches the code:
      no network code, no third-party SDKs that collect data):
      - "Does your app collect or share any of the required user data
        types?" → **No**.
      - Data is not encrypted in transit (nothing is transmitted) - the
        form skips this when nothing is collected.
      - Users can request deletion → describe the in-app "Clear Hero Data"
        button and uninstall.
      - Note: local-only data that never leaves the device does **not**
        count as "collected" under Play's definition, which is why "No" is
        correct.
- [ ] **(blocking) Content rating questionnaire (IARC).** Category:
      Utility/Productivity. The app has no violence, no user-generated
      content shared online, no purchases, no gambling, no ads; expect a
      "Everyone" / PEGI 3 rating.
- [ ] **(blocking) Target audience and content.** Target age group: 13+ (or
      18+) so the app is *not* designated as primarily child-directed, which
      would trigger Families policy requirements. Confirm "not appealing to
      children" unless you intend to comply with the Families policy.
- [ ] **Ads declaration**: the app contains no ads.
- [ ] **News app**: No. **COVID-19 app**: No. **Financial features**: No.
      **Health**: No. **Government app**: No.
- [ ] **App access**: "All functionality is available without special
      access" (no login).
- [ ] **Permissions**: `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`
      need no separate declaration form, but the notification usage should
      be described in the privacy policy (above). There is no
      `SCHEDULE_EXACT_ALARM`, `INTERNET`, location, camera or storage
      permission.

## Release

- [ ] Release name and release notes for the internal-testing release (what
      testers should try: create hero, create quest with reminder, complete
      quest, level up).
- [ ] After upload, check the Play Console pre-launch report for crashes on
      Google's test devices (this runs automatically for internal testing).
- [ ] Before production: add at least the 12-tester / 14-day closed test
      that Play now requires for **personal** developer accounts created
      after Nov 2023 (not required for organisation accounts).
