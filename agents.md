# agents.md — Drivora Project Context

This file gives AI coding assistants the context needed to work on this
codebase without re-explaining architecture each session.

## Project Overview
Drivora is a Flutter mobile app that helps vehicle owners track document
expiries (insurance, license, revenue license) and service history, with
AI-powered document scanning for auto-filling data. Built for Ascentic
AI Launch Pad (6-week program).

## Tech Stack
- Flutter / Dart (mobile-first, Android primary target)
- Local storage: SQLite via sqflite (or Hive — confirm before adding persistence code)
- AI: Claude API (vision) for document scanning/extraction — not yet integrated
- No backend yet — local-only for MVP, backend-agnostic service layer planned

## Folder Structure
```
lib/
├── models/       # Data classes: Vehicle, DocumentRecord, ServiceRecord
├── services/      # Business logic, data providers, future AIExtractionService
├── screens/       # Full-page UI screens
├── widgets/       # Reusable UI components
└── main.dart      # App entry point, theme config
```

## Data Models (current)
- `Vehicle`: id, plateNumber, make, model, year, photoPath
- `DocumentRecord`: id, vehicleId (FK), type (enum: insurance/license/
  revenueLicense/emissionTest), expiryDate, policyNumber, issuer,
  documentPhotoPath. Has `daysUntilExpiry` getter for status logic.
- `ServiceRecord`: id, vehicleId (FK), date, mileage, description, cost,
  garageName

All models use `toMap()`/`fromMap()` for sqflite compatibility (not
full JSON serialization — vehicleId is a string FK, not a nested object).

## Coding Conventions
- IDs are client-generated Strings (UUID), not auto-increment ints —
  this matters for future backend sync
- Status color logic: red = expired (daysUntilExpiry < 0), amber =
  expiring soon (<= 14 days), green = valid
- Dark theme only: background #121212, cards #1E1E24, primary blue
  #3B82F6, accent green #10B981
- Currently using mock data via `MockDataProvider` — this will be
  replaced by real sqflite queries in Step 5, keep the same method
  signatures (getVehicles(), getDocuments(), getServiceRecords()) so
  screens don't need rewriting

## Current State (update this as the project progresses)
- [x] Models defined
- [x] Dashboard + Vehicle Detail screens built with mock data
- [ ] Local persistence (sqflite) — in progress
- [ ] AI document scan/extraction feature — not started
- [ ] Notifications system — not started
- [ ] Natural language service logging — not started

## What NOT to do
- Don't add a backend/API layer yet — local-first MVP first
- Don't use community_charts_flutter for any charting — use fl_chart
  (lesson learned from a prior project, community_charts is abandoned)
- Don't hardcode API keys in source — will use .env or secure storage
  once AI integration starts
