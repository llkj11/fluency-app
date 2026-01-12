# Fluency for Windows (Tauri v2) - Implementation Guide

This document describes the Windows port of Fluency (currently macOS Swift/SwiftUI) using Tauri v2. It focuses on the core architecture, service mappings, and implementation order.

## Overview

Fluency is a dictation and TTS utility that runs quietly in the background. It captures microphone audio, transcribes with the Groq Whisper API, and plays back text via OpenAI/Gemini TTS using streamed PCM.

## Architecture Strategy

- Frontend (UI): React + TailwindCSS for overlay visuals, waveform rendering, and settings UI.
- Backend (Core): Rust for audio devices, global hotkeys, API calls, clipboard handling, and input simulation.

## Architecture Mapping

| macOS Component | Windows (Tauri) Equivalent |
| --- | --- |
| SwiftUI + AppKit | React + HTML/CSS (Frontend) |
| Swift Logic | Rust Backend |
| AVAudioEngine | cpal (Audio Capture) + rodio (Playback) |
| URLSession | reqwest (Rust HTTP Client) |
| Keychain | keyring (Windows Credential Manager) |
| UserDefaults | tauri-plugin-store (JSON file store) |
| CGEventTap (Hotkeys) | tauri-plugin-global-shortcut |
| NSPasteboard | arboard (Clipboard) |
| Accessibility API | enigo (Input Simulation) |

## Services to Port

### 1) HotkeyService

Purpose: Global trigger for dictation and TTS.

Windows approach (Rust):
- Use `tauri-plugin-global-shortcut`.
- Suggested triggers:
  - Dictate: `Ctrl+Space` (toggle).
  - TTS: `Ctrl+Shift+D` (or similar).
- Note: Fn key is ignored on Windows; use standard modifier keys.

### 2) AudioRecorder

Purpose: Capture microphone audio for transcription.

Windows approach (Rust):
- Use `cpal` for low-level audio capture.
- Configure 16kHz, 16-bit, mono (Whisper standard).
- Stream raw bytes from `cpal` directly to the API or to a `Vec<u8>` buffer.

### 3) TranscriptionService

Purpose: Send audio to Groq Whisper API and receive text.

Windows approach (Rust):
- Use `reqwest` with `multipart`.
- Logic matches macOS flow; handle async HTTP.
- Parse JSON with `serde_json`.

### 4) TTSService

Purpose: Convert text to speech via OpenAI/Gemini APIs.

Windows approach (Rust):
- Use `reqwest` streaming response support (`StreamExt`).
- Request PCM output (`response_format: "pcm"`).
- Stream chunks into a ring buffer or `VecDeque`.

### 5) StreamingAudioPlayer

Purpose: Play PCM audio chunks in real-time.

Windows approach (Rust):
- Use `rodio`.
- Create a custom `Source` reading from the incoming stream buffer.
- Start playback after ~300-500ms of buffered audio to reduce jitter.

### 6) TextCaptureService

Purpose: Get selected text from any application.

Windows approach (Rust):
- Use the "copy trick":
  - Simulate `Ctrl+C` via `enigo`.
  - Read text from the clipboard via `arboard`.
- Optional: restore previous clipboard content.

### 7) PasteService

Purpose: Type transcribed text into the active window.

Windows approach (Rust):
- Use `enigo` to simulate keyboard input.
- `enigo.text(transcribed_string)` types it immediately.

### 8) KeychainHelper

Purpose: Securely store API keys.

Windows approach (Rust):
- Use `keyring`, which maps to Windows Credential Manager.

## UI Components (Frontend - React)

### Transparent Overlay (Recording)

- Window config:
  - `transparent: true`
  - `decorations: false`
  - `alwaysOnTop: true`
  - `skipTaskbar: true`
- Visuals: centered overlay with glowing gradients and smooth animation.
- Waveform: render via `<canvas>`, driven by audio amplitude data from Rust via Tauri events.

### Settings Window

- Standard window with title bar.
- TailwindCSS themes (Aurora, Midnight, Ember, etc.).
- Inputs for API keys, passed to the Rust backend for persistence.

### System Tray

- Use `tauri-plugin-system-tray`.
- Left click: open settings window.
- Right click: context menu (Quit, About).

## Development Setup

- Prerequisites:
  - Node.js
  - Rust (via `rustup`)
  - Microsoft Visual Studio C++ Build Tools
- Scaffold:
  - `npm create tauri-app@latest`
  - Select React, TypeScript, Tailwind
- Configure `tauri.conf.json` permissions for shell, clipboard, and HTTP.

## Recommended Libraries (Crates)

| Purpose | Rust Crate |
| --- | --- |
| Audio Capture | cpal |
| Audio Playback | rodio |
| HTTP Requests | reqwest |
| Serialization | serde, serde_json |
| Input Simulation | enigo |
| Global Hotkeys | tauri-plugin-global-shortcut |
| Clipboard | arboard |
| Secrets/Keys | keyring |

## Suggested Port Order

### Phase 1 - Rust Backend (Core)

- Set up `reqwest` for OpenAI/Groq/Gemini APIs.
- Implement `keyring` for saving keys.
- Verify `cpal` recording to a WAV file.

### Phase 2 - Ghost Window (Overlay)

- Configure the transparent overlay in `tauri.conf.json`.
- Build the React overlay UI.
- Send amplitude events from Rust to React for waveform rendering.

### Phase 3 - System Integration

- Implement global hotkeys (`Ctrl+Space`).
- Implement copy/paste simulation with `enigo`.

### Phase 4 - Polish

- Add theme switching (Tailwind classes).
- Finalize streaming TTS buffer logic.
