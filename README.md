# BroadcastLabs Releases

Public Windows installers for BroadcastLabs apps. Source code stays in each product's private repository.

## BroadcastRC

| File | Description |
|------|-------------|
| `BroadcastRC-Host-Setup.exe` | Install on the studio PC that accepts connections |
| `BroadcastRC-Setup.exe` | Install on a person's PC to connect into the station |

Release tag pattern: `BroadcastRC-vX.Y.Z`

Download base: `https://github.com/BroadcastLabsAU/BroadcastLabs-Releases/releases/download/BroadcastRC-vX.Y.Z/`

## BroadcastMate, Logger, Sync, DeDuper, Trimmer, Phone, SMS and VerifyAI

| App | What it does | Newest installer |
|-----|--------------|------------------|
| **BroadcastMate** | Radio automation and playout | [`BroadcastMate-Setup.exe`](https://github.com/BroadcastLabsAU/BroadcastLabs-Releases/releases/download/BroadcastMate-latest/BroadcastMate-Setup.exe) |
| **BroadcastLogger** | Compliance logging and off-air recording | [`BroadcastLogger-Setup.exe`](https://github.com/BroadcastLabsAU/BroadcastLabs-Releases/releases/download/BroadcastLogger-latest/BroadcastLogger-Setup.exe) |
| **BroadcastSync** | Scheduled FTP and folder synchronisation | [`BroadcastSync-Setup.exe`](https://github.com/BroadcastLabsAU/BroadcastLabs-Releases/releases/download/BroadcastSync-latest/BroadcastSync-Setup.exe) |
| **BroadcastDeDuper** | Duplicate music detection and library clean-up | [`BroadcastDeDuper-Setup.exe`](https://github.com/BroadcastLabsAU/BroadcastLabs-Releases/releases/download/BroadcastDeDuper-latest/BroadcastDeDuper-Setup.exe) |
| **BroadcastTrimmer** | Automatic silence trimming | [`BroadcastTrimmer-Setup.exe`](https://github.com/BroadcastLabsAU/BroadcastLabs-Releases/releases/download/BroadcastTrimmer-latest/BroadcastTrimmer-Setup.exe) |
| **BroadcastPhone** | Phone-in calls and talkback straight to air | [`BroadcastPhone-Setup.exe`](https://github.com/BroadcastLabsAU/BroadcastLabs-Releases/releases/download/BroadcastPhone-latest/BroadcastPhone-Setup.exe) |
| **BroadcastSMS** | The studio text line: song requests, competitions and listener texts | [`BroadcastSMS-Setup.exe`](https://github.com/BroadcastLabsAU/BroadcastLabs-Releases/releases/download/BroadcastSMS-latest/BroadcastSMS-Setup.exe) |
| **BroadcastVerifyAI** | Local, privacy-first screening of audio for signs of AI generation | [`BroadcastVerifyAI-Setup.exe`](https://github.com/BroadcastLabsAU/BroadcastLabs-Releases/releases/download/BroadcastVerifyAI-latest/BroadcastVerifyAI-Setup.exe) |

Release tag patterns:
- `<App>-vX.Y.Z`: one release per version, for example `BroadcastMate-v1.0.0`
- `<App>-latest`: a permanent release whose installer is replaced by every new
  version, so the link above never changes. The website's download buttons use it.

Each release also carries `<App>-Setup.exe.sha256` for checking the download.
These installers are built, smoke-tested and published automatically by the
GitHub Actions workflow in each app's repository. To release one, see
[RELEASING.md](RELEASING.md): it is one button in the app's Actions tab.
