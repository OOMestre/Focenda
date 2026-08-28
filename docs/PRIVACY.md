# Focenda Privacy and Security Policy

Last updated: 2026-08-28

Focenda is designed to work locally. It does not require an account, does not
run telemetry, and does not sync your productivity content to a Focenda
server.

## Data stored on this Mac

Focenda stores tasks, task notes, reminders, scratchpad notes, bookmarks,
quick links, productivity profiles, saved app layouts, and app preferences
locally. Before these values are written to
the app's local preference domain, they are encrypted with authenticated
AES-GCM encryption. The 256-bit encryption key is stored in the macOS
Keychain, separately from the encrypted values.

Older Focenda versions stored some values as cleartext `UserDefaults` data.
After an upgrade, Focenda migrates a legacy value when it is read, replaces it
with encrypted data, and does not keep the old value under that key. A value
that has never been read by the updated app can remain in an old local backup
or copy of the preference domain until that backup is removed.

The encryption protects data at rest. It does not protect content while it is
visible in the running app, displayed by macOS, copied to the clipboard, or
accessible to a user or process that already has access to the unlocked macOS
account and Keychain.

## Network communication

Focenda only contacts GitHub's public release service when checking for or
downloading an update. It sends no tasks, notes, reminders, bookmarks, or
preferences to GitHub or to a Focenda service. Update timestamps and release
state are local encrypted preferences.

## macOS notifications and selected files

When reminders or focus alerts are enabled, reminder and task text may be
passed to macOS UserNotifications so the system can display a notification.
macOS controls notification display and may retain notification content under
its own policies.

If you choose a custom alert sound, Focenda stores an encrypted security-scoped
bookmark and the local path needed to access that file. The audio file itself
stays where you selected it; Focenda does not upload or copy it to a server.

For productivity profiles, Focenda stores the selected application's bundle
identifier, local path, a security-scoped bookmark, the saved window layout,
and the profile shortcut in the same encrypted local storage. Activating a
profile uses macOS Accessibility permission to move and resize windows in
other applications. Focenda does not read or upload the contents of those
applications.

## Runtime protections

Generated Focenda app bundles use the hardened runtime and are intentionally not
App Sandbox restricted. This allows the updater to replace the installed app in
place automatically, without asking the user to select its containing folder.
Focenda still only uses files selected by the user for custom sounds and
productivity profiles. Window organization also
requires the user to approve Focenda under System Settings > Privacy & Security
> Accessibility. For public distribution,
the bundle should also be signed with a Developer ID identity and notarized;
an ad-hoc signature is intended only for local staging or CI artifacts.

## Contact

For privacy or security questions, open an issue in the project's public
[GitHub repository](https://github.com/OOMestre/Focenda).
