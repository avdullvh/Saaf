# Saaf (سعف)

Palm tree variety classification and farmer community app — Flutter + Django + PostgreSQL, with AI classification hosted on Hugging Face.

---

## Project Architecture

```mermaid
graph TD
    A[Flutter Mobile App] <--> B[REST API - Django]
    B <--> C[PostgreSQL Database]
    B <--> D[AI Model - Hugging Face Space]
    A <--> E[Media Storage]
```

### Frontend — Flutter Mobile Application
- **State Management**: `Provider` pattern.
- **Localization**: Full Arabic and English support via `.arb` files.
- **Image Handling**: Camera and gallery picking with cross-platform image upload.

### Backend — Django REST Framework
- **Authentication**: Custom JWT (SimpleJWT) for secure, stateless sessions.
- **AI Classification**: Images are forwarded to a hosted Hugging Face Space (`mutairi1-palmtreeclassifer`). No local model file is needed.
- **Social Feed**: Posts, likes, nested comments, and follow relationships.
- **Recommendations**: LightGCN-based "Who to follow" suggestions.
- **Storage**: Media files managed through Django's `FileSystemStorage`.

---

## Directory Structure

### Mobile App (`/lib`)
- `core/` — API constants, theme, and token storage utilities.
- `models/` — Dart data classes (User, Post, ClassificationResult).
- `providers/` — State management (Auth, Feed, Classification, Profile, Theme, Locale).
- `screens/` — UI screens: Auth, Classification, Feed, Profile.
- `services/` — HTTP communication layer.
- `l10n/` — Arabic and English translation files.

### Backend (`/saaf_backend`)
- `accounts/` — Custom user model, JWT auth, profile, follow system, and recommendations.
- `feed/` — Posts, likes, and comments.
- `classify/` — Proxies classification requests to the Hugging Face Space.
- `saaf/` — Django settings and root URL configuration.

---

## Setup and Installation

### Option A: Docker (recommended)

**Prerequisites**
- Docker Desktop installed and running.

**Run** from the `Saaf/` folder:
```bash
docker compose up --build
```

- **Backend**: `http://127.0.0.1:8000/`
- **API base**: `http://127.0.0.1:8000/api/`

> The AI model is hosted on Hugging Face — no local model file needed. The `HF_CLASSIFY_URL` is already set in `docker-compose.yml`.

---

### Option B: Local (no Docker)

#### 1) Backend (Django)

**Prerequisites**
- Python 3.11+
- PostgreSQL 16+

**Create `saaf_backend/.env`**

```env
SECRET_KEY=your_secret_key
DEBUG=True
DB_NAME=saaf_db
DB_USER=postgres
DB_PASSWORD=your_postgres_password
DB_HOST=localhost
DB_PORT=5432
HF_CLASSIFY_URL=https://mutairi1-palmtreeclassifer.hf.space/classify
```

**Install and run**
```bash
cd saaf_backend
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

Backend will be at `http://127.0.0.1:8000/`.

> Using `0.0.0.0:8000` makes the backend reachable from physical phones on the same Wi-Fi network.

---

#### 2) Frontend (Flutter) — Web / Emulator

**Prerequisites**
- Flutter SDK installed ([flutter.dev](https://flutter.dev))

```bash
cd Saaf
flutter pub get
flutter run
```

For web or desktop testing, ensure `lib/core/constants/api_constants.dart` has:
```dart
static const String baseUrl = 'http://127.0.0.1:8000/api';
```

---

#### 3) Running on a Physical Android Device

**Step 1 — Enable Developer Options on the phone**
1. Go to **Settings → About phone**.
2. Tap **Build number** 7 times until you see "You are now a developer".
3. Go back to **Settings → Developer Options**.
4. Enable **USB Debugging**.

**Step 2 — Connect the phone**

Connect via USB. When prompted on the phone, tap **Allow USB Debugging**.

Verify the device is detected:
```bash
flutter devices
```

**Step 3 — Find your machine's local IP**

- **Windows**: open Command Prompt → run `ipconfig` → look for **IPv4 Address** (e.g. `192.168.1.10`)
- **macOS**: open Terminal → run `ifconfig en0` → look for **inet** (e.g. `192.168.1.10`)

**Step 4 — Update the API base URL**

Open `lib/core/constants/api_constants.dart` and set your machine's IP:

```dart
static const String baseUrl = 'http://192.168.1.10:8000/api';
```

> Make sure your phone and your computer are on the **same Wi-Fi network**.

**Step 5 — Run Django on your LAN**
```bash
python manage.py runserver 0.0.0.0:8000
```

**Step 6 — Run the app**
```bash
flutter run
```

---

#### 4) Running on a Physical iPhone (via Xcode)

> **Requirements**: macOS machine, Xcode installed, Apple Developer account (free account is enough for personal testing).

**Step 1 — Install Xcode**

Download **Xcode** from the Mac App Store. After installing, open it once to accept the license and install components.

Also install the Xcode command-line tools:
```bash
sudo xcode-select --install
```

**Step 2 — Install CocoaPods**
```bash
sudo gem install cocoapods
```

**Step 3 — Install Flutter dependencies**

From the `Saaf/` folder:
```bash
flutter pub get
cd ios
pod install
cd ..
```

**Step 4 — Open the project in Xcode**
```bash
open ios/Runner.xcworkspace
```

> Always open the `.xcworkspace` file, **not** `.xcodeproj`.

**Step 5 — Set your Apple Developer Team**

1. In Xcode, click on **Runner** in the left sidebar.
2. Go to the **Signing & Capabilities** tab.
3. Under **Team**, select your Apple ID (sign in via Xcode → Settings → Accounts if needed).
4. Xcode will automatically manage the signing certificate.

**Step 6 — Enable Developer Mode and trust the certificate on the iPhone**

1. Connect your iPhone via USB.
2. Enable Developer Mode: go to **Settings → Privacy & Security → Developer Mode**, toggle it on, then restart the phone when prompted.
3. After restart, go to **Settings → General → VPN & Device Management**.
4. Find your Apple ID under "Developer App" and tap **Trust**.

**Step 7 — Find your machine's local IP**

Open Terminal:
```bash
ifconfig en0
```
Look for the `inet` line (e.g. `192.168.1.10`).

**Step 8 — Update the API base URL**

Open `lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'http://192.168.1.10:8000/api';
```

> Make sure your iPhone and your Mac are on the **same Wi-Fi network**.

**Step 9 — Run Django on your LAN**
```bash
python manage.py runserver 0.0.0.0:8000
```

**Step 10 — Build and run from Xcode**

1. In Xcode, select your iPhone from the device dropdown at the top.
2. Press the **▶ Run** button (or `Cmd + R`).
3. Xcode will build and install the app on your iPhone.

Alternatively, from the terminal:
```bash
flutter run
```

Flutter will automatically detect the connected iPhone.

---

## Seed Demo Data (optional)

Populates the database with 50 realistic users, posts, follow relationships, and likes.

**Requirements:**
- Backend must be running at `http://127.0.0.1:8000`.
- `feedPhotos/` folder must exist at the repo root with `.jpg` images (already included).

```bash
# From the Saaf/ folder
python saaf_backend/seed_data.py
```

All seeded accounts use the password `Saaf@1234`.

---

## Technical Notes

### AI Classification
Images are sent from the Flutter app → Django backend → Hugging Face Space (`/classify` endpoint). The Hugging Face model returns the predicted palm variety (`Khalas`, `Razeez`, or `Shishi`) and a confidence score.

To prevent misleading results, the result screen shows `"Unknown"` and disables the "Share to Community" button if confidence is below 95%.

### Password Policy
Passwords must be at least 6 characters and contain both letters and numbers. This is enforced both on the frontend (Flutter form validator) and backend (Django serializer).

### Social Recommendation Algorithm
The "People you may know" feature uses a LightGCN graph neural network trained on the follow graph. Details are in `SOCIAL_RECOMMENDATION_ALGORITHM.md`.

### Data Synchronization
The app uses a "Reload on Tab" strategy — profile posts are re-fetched whenever the user opens the Profile tab so likes and comments stay in sync.

---

## Git Workflow

`.gitignore` excludes: `.env` files, `db.sqlite3`, `media/` uploads, `__pycache__`, and build artifacts.



---

**Repository**: [github.com/avdullvh/Saaf](https://github.com/avdullvh/Saaf)
