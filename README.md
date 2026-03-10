# ClawVoice

A minimal voice assistant for [OpenClaw](https://github.com/nichochar/openclaw) users.

Tap to talk (or say **"Hey Siri, [your shortcut name]"**) → Gemini Live handles voice I/O → OpenClaw executes actions → response spoken back.

No video. No camera. No battery drain. Just voice.

---

## Features

- 🎙 Real-time voice conversation via Gemini Live API (audio only)
- 🔗 Direct OpenClaw integration — your server, your AI, your tools
- 📵 Minimal UI — one screen, works with screen dimmed
- ⚡ Siri Shortcut support — custom wake phrase via "Hey Siri"
- ⚙️ Fully configurable — server URL, token, Gemini key, voice, prompt
- 🎧 Works with any headphones or built-in mic/speaker

## Requirements

- iPhone with iOS 17.0+
- Xcode 15.0+
- [Gemini API key](https://aistudio.google.com/apikey) (free)
- OpenClaw server running with `chatCompletions` endpoint enabled

## Setup

### 1. Clone & Open

```bash
git clone https://github.com/YOUR_USERNAME/clawvoice-ios.git
cd clawvoice-ios
cp ClawVoice/Secrets.swift.example ClawVoice/Secrets.swift
```

### 2. Create Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Product Name: `ClawVoice`, Bundle ID: `com.yourname.ClawVoice`
4. Language: **Swift**, Interface: **SwiftUI**
5. Save into the cloned folder (replace the generated files)
6. Drag all `.swift` files from the `ClawVoice/` folder into Xcode
7. In `Info.plist`, add:
   - `NSMicrophoneUsageDescription` → `"Voice assistant needs microphone access"`
   - `UIBackgroundModes` → `audio`

### 3. Configure

Edit `ClawVoice/Secrets.swift`:

```swift
struct Secrets {
    static let geminiApiKey    = "YOUR_GEMINI_API_KEY"
    static let openClawHost    = "https://your-tailscale-hostname.ts.net"
    static let openClawPort    = 443
    static let openClawToken   = "YOUR_GATEWAY_TOKEN"
}
```

Or leave blank and configure everything in-app via Settings (⚙️).

### 4. OpenClaw Server Config

Ensure your `~/.openclaw/openclaw.json` has:

```json
{
  "gateway": {
    "http": {
      "endpoints": {
        "chatCompletions": { "enabled": true }
      }
    }
  }
}
```

### 5. Build & Run

Select your iPhone → **Cmd+R**

## Siri Shortcut Setup

To activate hands-free with a custom phrase:

1. Open **Shortcuts** app on iPhone
2. Tap **+** → Search "ClawVoice" → Select **"Activate Assistant"**
3. Tap **Add to Siri** → Record your phrase (e.g. "Mr Krabs", "Hey Assistant")
4. Say "Hey Siri, Mr Krabs" → app opens and starts listening immediately

## Architecture

```
User voice (mic)
      │ PCM 16kHz
      ▼
Gemini Live API (WebSocket, audio only)
      │ tool calls
      ▼
OpenClaw Gateway (/v1/chat/completions)
      │ AI response (Claude / your model)
      ▼
Gemini speaks the result (PCM 24kHz)
      │
      ▼
Speaker / headphones
```

## File Structure

```
ClawVoice/
├── ClawVoiceApp.swift          # App entry point
├── ContentView.swift           # Main UI (orb + status)
├── SettingsView.swift          # Configuration screen
├── AppSettings.swift           # UserDefaults wrapper
├── Audio/
│   └── AudioManager.swift      # Mic capture + speaker playback
├── Gemini/
│   ├── GeminiConfig.swift      # Model name, voice, system prompt
│   ├── GeminiLiveService.swift # WebSocket client
│   └── GeminiModels.swift      # Encode/decode types
├── OpenClaw/
│   ├── OpenClawBridge.swift    # HTTP client for OpenClaw
│   └── ToolCallRouter.swift    # Routes Gemini tool calls → OpenClaw
├── Intents/
│   └── AssistantIntent.swift   # Siri Shortcut intent
└── Secrets.swift               # API keys (gitignored)
```

## License

MIT
