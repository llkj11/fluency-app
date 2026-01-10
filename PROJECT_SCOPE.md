# Fluency - Project Scope

## What Is This?
A native macOS menu bar app that works like Wispr Flow / Spokenly - hold Cmd key to speak, release to transcribe, and the text auto-pastes into whatever text field is focused.

## Tech Stack
- Swift 5.9+ / SwiftUI
- AVFoundation for audio recording
- CGEvent tap for global Cmd key detection
- OpenAI `gpt-4o-mini-transcribe` API for STT
- SwiftData for history persistence
- Keychain for secure API key storage

## Key Features
1. **Hold Cmd Key** - Hold to record, release to transcribe (250ms delay to not interfere with Cmd+C, etc.)
2. **Auto-Paste** - Transcription auto-pastes into the active text field
3. **Recording Overlay** - Floating popup shows "Listening..." with waveform animation
4. **History View** - See past transcriptions with timestamps
5. **Settings** - API key input, stored securely in Keychain
6. **Menu Bar App** - Lives in menu bar, minimal footprint

## Project Structure
```
Fluency/
├── FluencyApp.swift           # App entry, menu bar setup, AppDelegate, AppState
├── Models/
│   └── Transcription.swift    # SwiftData model for history
├── Services/
│   ├── HotkeyService.swift    # Global Cmd key detection via CGEvent
│   ├── AudioRecorder.swift    # AVAudioRecorder wrapper (records to .m4a)
│   ├── TranscriptionService.swift  # OpenAI API + KeychainHelper
│   └── PasteService.swift     # Accessibility paste via AXUIElement
├── Views/
│   ├── MenuBarView.swift      # Menu bar popover with status & actions
│   ├── RecordingOverlay.swift # Floating "Listening..." popup with waveform
│   ├── HistoryView.swift      # List of past transcriptions
│   └── SettingsView.swift     # API key input
└── Resources/
    ├── Info.plist             # Permissions (microphone)
    └── Fluency.entitlements   # Audio input entitlement
```

## Required Permissions
1. **Microphone** - For recording voice
2. **Accessibility** - For CGEvent tap (hotkey detection) and text paste

## OpenAI API Details
- Endpoint: `POST https://api.openai.com/v1/audio/transcriptions`
- Model: `gpt-4o-mini-transcribe`
- Audio format: AAC (.m4a), 16kHz, mono
- Response format: `text`
- Cost: ~$0.003/minute

## Implementation Status

### Completed
- [x] FluencyApp.swift - Main app entry with AppDelegate and AppState
- [x] Transcription.swift - SwiftData model
- [x] AudioRecorder.swift - AVAudioRecorder service
- [x] HotkeyService.swift - Cmd key detection with CGEvent tap
- [x] TranscriptionService.swift - OpenAI API + Keychain helper
- [x] PasteService.swift - Accessibility paste
- [x] RecordingOverlay.swift - Floating UI with waveform animation
- [x] MenuBarView.swift - Menu bar popover
- [x] HistoryView.swift - History list with search
- [x] SettingsView.swift - API key settings + permissions
- [x] Info.plist - Permissions configured
- [x] Fluency.entitlements - Audio input enabled
- [x] Xcode project file (project.pbxproj)

### Ready to Build
All code is complete. Open the project in Xcode and build.

## How to Build & Run
1. Open `/Users/llkj/Documents/Projects/fluency/Fluency.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities (or leave blank for local testing)
3. Build and run (Cmd+R)
4. Grant microphone permission when prompted
5. Grant Accessibility permission in System Settings when prompted
6. Add your OpenAI API key in Settings (click the menu bar icon)
7. Hold Command key to record, release to transcribe!

## API Documentation
See `/Users/llkj/Documents/DOCS/openai_speech_to_text` for full API docs.

## Approved Plan
See `/Users/llkj/.claude/plans/glowing-jumping-thacker.md` for the full implementation plan.
