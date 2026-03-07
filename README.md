# SAAF SAAF - Palm Tree Variety Classification & Community

SAAF SAAF is a comprehensive mobile application designed to help farmers and palm enthusiasts classify palm tree varieties using AI/ML and share their results with a local community.

## 🚀 Features
- **AI Classification**: Instantly identify palm varieties (Khalas, Shishi, etc.) from photos.
- **Community Feed**: Share your classification results, like posts, and comment on others.
- **User Profiles**: Manage your own profile, upload an avatar, and track your contributions.
- **Multilingual Support**: Fully localized in both Arabic and English.
- **Cross-Platform**: Built with Flutter for a smooth experience across devices.

## 🛠 Tech Stack
- **Frontend**: Flutter (Provider for state management, Material 3 Design)
- **Backend**: Django 5 + Django REST Framework (DRF)
- **Database**: PostgreSQL (for persistent profiles and posts)
- **AI/ML**: PyTorch (Torchvision + TIMM) integrated directly into the Django backend.
- **Authentication**: JWT (JSON Web Tokens) for secure sessions.

---

## 💻 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Python 3.10+](https://www.python.org/downloads/)
- [PostgreSQL](https://www.postgresql.org/download/)

### 2. Backend Setup (Django)
```bash
cd saaf_backend

# Install dependencies
pip install -r requirements.txt

# Setup Environment (.env)
# Create a .env file with your DB_URL and SECRET_KEY

# Run migrations
python manage.py migrate

# Start the server
python manage.py runserver
```

### 3. Frontend Setup (Flutter)
```bash
# From the root directory
flutter pub get

# (Optional) Regenerate localization if needed
flutter gen-l10n

# Run the app
flutter run
```

---

## 📤 Git & GitHub Workflow

### How to push changes
Whenever you make changes to the code, run these commands to update your GitHub repository:

```bash
# 1. Stage all changes
git add .

# 2. Commit with a meaningful message
git commit -m "Describe your changes here"

# 3. Push to GitHub
git push
```

### GitHub Repository
Your code is hosted at: **[github.com/avdullvh/saaf-saaf](https://github.com/avdullvh/saaf-saaf)**

---
Developed as a graduation project at **KFU**.
