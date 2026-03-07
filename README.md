# SAAF SAAF - Palm Tree Variety Classification & Community

SAAF SAAF (سعف) is a full-stack mobile application developed for the agricultural sector, specifically targeting palm tree farmers. It leverages Artificial Intelligence to identify palm tree varieties from images and provides a community platform for farmers to share insights and classification results.

## 🏗 Project Architecture

The system follows a modern client-server architecture:

```mermaid
graph TD
    A[Flutter Mobile App] <--> B[REST API - Django]
    B <--> C[PostgreSQL Database]
    B <--> D[AI/ML Engine - PyTorch]
    A <--> E[Media Storage]
```

### 1. Frontend: Flutter Mobile Application
A high-performance, cross-platform UI built to handle image processing and community interactions.
- **State Management**: `Provider` pattern for clean data flow.
- **Localization**: Full support for Arabic and English using `.arb` files.
- **Image Handling**: Custom logic for 1:1 aspect ratio cropping and cross-platform (Web/Mobile/macOS) image uploading.

### 2. Backend: Django REST Framework
A robust backend managing users, posts, and ML inference.
- **Authentication**: Custom JWT implementation for secure, stateless sessions.
- **ML Integration**: The AI model is loaded once on server startup (in `classify/apps.py`) and cached in memory for zero-latency inference.
- **Storage**: Media files (images) are managed through Django's `FileSystemStorage`.

---

## 📂 Directory Structure

### Mobile App (`/lib`)
- `core/`: Constants, themes, and shared utilities (token storage).
- `models/`: Plain Dart objects mapping API data (User, Post, Result).
- `providers/`: Business logic and state management (Auth, Feed, Classification).
- `screens/`: UI components organized by feature (Auth, Feed, Result, Profile).
- `services/`: Low-level HTTP communication classes.
- `l10n/`: Translation files for Arabic and English.

### Backend (`/saaf_backend`)
- `accounts/`: Custom user model, profile management, and JWT authentication logic.
- `feed/`: Social features — posts, likes, and nested comments.
- `classify/`: The AI engine. Ported from a standalone FastAPI implementation into Django views.
- `media/`: Storage directory for uploaded images.
- `saaf/`: Core project settings and URL routing.

---

## ⚙️ Technical Deep Dive

### AI Classification Logic
The model uses a pre-trained `TIMM` architecture. To prevent misleading results, the API returns a classification "Unknown" if the model's confidence is below 95%. When a result is "Unknown", the option to "Share to Community" is automatically disabled in the app.

### Data Synchronization
The app uses a "Reload on Tab" strategy. To ensure that likes and comments made in the community feed are visible in the user's profile, the profile posts are re-fetched whenever the user navigates to the Profile tab.

---

## 🛠 Setup and Installation

### Backend (Django)
1. **Database**: Ensure PostgreSQL is running.
   ```bash
   createdb saaf_db
   ```
2. **Environment**: Create a `.env` in `saaf_backend/`:
   ```env
   SECRET_KEY=your_secret
   DATABASE_URL=postgres://user:pass@localhost:5432/saaf_db
   ```
3. **Run**:
   ```bash
   pip install -r requirements.txt
   python manage.py migrate
   python manage.py runserver
   ```

### Frontend (Flutter)
1. **Install Gems/Dependencies**:
   ```bash
   flutter pub get
   ```
2. **Run**:
   ```bash
   flutter run
   ```

---

## 📤 Git Workflow

To keep the project clean, specific rules are set in `.gitignore`:
- **Ignored**: `.env` files, `db.sqlite3`, `media/` uploads, and `__pycache__`.

### Pushing Changes
```bash
git add .
git commit -m "feat: your feature description"
git push origin main
```

---
**Main Repository**: [github.com/avdullvh/saaf-saaf](https://github.com/avdullvh/saaf-saaf)
