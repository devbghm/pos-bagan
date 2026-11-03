# pos-bagan

An offline-first Flutter point-of-sale foundation intended to be configurable for different types of businesses.

## Current foundation

- Flutter app scaffold and Material 3 theme
- Local SQLite database (no network required for normal use)
- Product catalog with name, category, and whole-unit price
- Cart and checkout saved as locally stored sales
- Sales history with saved line-item snapshots
- Basic business name and currency settings stored locally
- Myanmar Kyat (MMK) and `မကွေးဆိုင်` are starter defaults; change them in Settings

## Run

1. Install Flutter and an Android toolchain.
2. From the project root run `flutter pub get`.
3. Run `flutter run` on an Android device or emulator.

This repository currently contains the Dart application foundation. Generate the Android platform project if it is not present by running `flutter create --platforms=android .` from the repository root with Flutter installed.

## Offline data and backups

Products, settings, and completed sales are stored in the app's local SQLite database. Checkout does not require an internet connection. This starter does not yet sync to Firebase, export to Google Sheets, or provide a backup/restore flow. Add and test backup/export before using it as the sole record of real business transactions.

## Important next steps

- Confirm business rules: tax, discounts, rounding, currencies, refunds, and receipt requirements.
- Add optional inventory, table numbering (00–99), team/group management, and business-specific workflows as configurable modules.
- Add staff accounts and role-based access if multiple employees use the app.
- Design encrypted/managed backup and a safe multi-device sync strategy before introducing cloud sync.
- Add automated tests for pricing, checkout, persistence, and recovery; test on the target devices and printers.
- Review privacy, security, and local legal/tax requirements before production use.

## Data considerations

This starter stores prices as integer whole currency units and has no tax/discount/refund implementation. It is suitable as a development starting point, not yet as a production accounting system. Avoid uninstalling the app or clearing its storage until you have implemented and verified a backup process.
