# accounts/management/commands/create_test_users.py
"""
Django management command to create a realistic test dataset for verifying
the LightGCN recommendation system.

Creates 12 test users arranged in overlapping social clusters so that the
model has meaningful graph structure to learn from:

  Cluster A (photography): alice, bob, carol, dave
  Cluster B (travel):      eve, frank, grace, henry
  Cluster C (tech):        irene, jack, kelly, liam

Cross-cluster edges are also added so the GNN can propagate information
across communities.

Usage:
    python manage.py create_test_users
    python manage.py create_test_users --clear   # remove existing test users first
"""

import random
from django.core.management.base import BaseCommand
from django.db import transaction
from accounts.models import User, Follow


TEST_USERS = [
    # (email, full_name, bio, password)

    # Cluster A — Date Palm Farmers
    ("ahmed@test.saaf",  "Ahmed Al-Hasawi",  "Date palm farmer from Al-Ahsa 🌴",           "Test1234!"),
    ("khalid@test.saaf", "Khalid Al-Mulhim", "Khalas and Shishi dates specialist 🌴",     "Test1234!"),
    ("saad@test.saaf",   "Saad Al-Jabr",     "Traditional palm cultivation 🌴",            "Test1234!"),
    ("fahad@test.saaf",  "Fahad Al-Dawsari", "Organic date farming and harvesting 🌴",    "Test1234!"),

    # Cluster B — Organic Crop Farmers
    ("omar@test.saaf",   "Omar Al-Rajhi",    "Organic vegetable farming 🌱",               "Test1234!"),
    ("saleh@test.saaf",  "Saleh Al-Olayan",  "Sustainable agriculture enthusiast 🚜",      "Test1234!"),
    ("ali@test.saaf",    "Ali Al-Suwailem",  "Local wheat and grain producer 🌾",          "Test1234!"),
    ("tariq@test.saaf",  "Tariq Al-Mutairi", "Farm-to-table organic produce 🍅",           "Test1234!"),

    # Cluster C — Greenhouse & Hydroponics
    ("yasser@test.saaf", "Yasser Al-Qahtani","Modern hydroponic greenhouse owner 💧",     "Test1234!"),
    ("majid@test.saaf",  "Majid Al-Faisal",  "Smart farming and irrigation systems 💡",    "Test1234!"),
    ("sami@test.saaf",   "Sami Al-Zahrani",  "Indoor climate-controlled agriculture 🌡️",   "Test1234!"),
    ("nasser@test.saaf", "Nasser Al-Otaibi", "Vertical farming specialist 🥬",             "Test1234!"),
]

# Directed follow edges  (follower_email → following_email)
# Dense within clusters, sparse across clusters
FOLLOW_EDGES = [
    # ── Cluster A (Date Palm Farmers) ─────────────────────────────────────────
    ("ahmed@test.saaf",  "khalid@test.saaf"),
    ("ahmed@test.saaf",  "saad@test.saaf"),
    ("khalid@test.saaf", "ahmed@test.saaf"),
    ("khalid@test.saaf", "fahad@test.saaf"),
    ("saad@test.saaf",   "ahmed@test.saaf"),
    ("saad@test.saaf",   "fahad@test.saaf"),
    ("fahad@test.saaf",  "saad@test.saaf"),
    ("fahad@test.saaf",  "khalid@test.saaf"),

    # ── Cluster B (Organic Crop Farmers) ──────────────────────────────────────
    ("omar@test.saaf",   "saleh@test.saaf"),
    ("omar@test.saaf",   "ali@test.saaf"),
    ("saleh@test.saaf",  "omar@test.saaf"),
    ("saleh@test.saaf",  "tariq@test.saaf"),
    ("ali@test.saaf",    "omar@test.saaf"),
    ("ali@test.saaf",    "tariq@test.saaf"),
    ("tariq@test.saaf",  "saleh@test.saaf"),
    ("tariq@test.saaf",  "ali@test.saaf"),

    # ── Cluster C (Greenhouse & Hydroponics) ──────────────────────────────────
    ("yasser@test.saaf", "majid@test.saaf"),
    ("yasser@test.saaf", "sami@test.saaf"),
    ("majid@test.saaf",  "yasser@test.saaf"),
    ("majid@test.saaf",  "nasser@test.saaf"),
    ("sami@test.saaf",   "yasser@test.saaf"),
    ("sami@test.saaf",   "nasser@test.saaf"),
    ("nasser@test.saaf", "majid@test.saaf"),
    ("nasser@test.saaf", "sami@test.saaf"),

    # ── Cross-cluster bridges (help GNN propagate across communities) ─────────
    ("fahad@test.saaf",  "omar@test.saaf"),       # date palm → organic
    ("saad@test.saaf",   "saleh@test.saaf"),      # date palm → organic
    ("omar@test.saaf",   "yasser@test.saaf"),     # organic → greenhouse
    ("tariq@test.saaf",  "majid@test.saaf"),      # organic → greenhouse
    ("yasser@test.saaf", "ahmed@test.saaf"),      # greenhouse → date palm
    ("nasser@test.saaf", "khalid@test.saaf"),     # greenhouse → date palm
]


class Command(BaseCommand):
    help = "Create 12 test users with follow relationships for LightGCN testing."

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Delete existing test users (emails ending in @test.saaf) before creating new ones.',
        )

    def handle(self, *args, **options):
        if options['clear']:
            deleted, _ = User.objects.filter(email__endswith='@test.saaf').delete()
            self.stdout.write(self.style.WARNING(f"Deleted {deleted} existing test user(s)."))

        test_emails = {u[0] for u in TEST_USERS}
        email_to_user: dict[str, User] = {}

        self.stdout.write("Creating test users…")
        created_count = 0

        with transaction.atomic():
            for email, full_name, bio, password in TEST_USERS:
                user, created = User.objects.get_or_create(
                    email=email,
                    defaults={'full_name': full_name, 'bio': bio},
                )
                if created:
                    user.set_password(password)
                    user.save()
                    created_count += 1
                    self.stdout.write(f"  ✓ Created  {full_name} <{email}>")
                else:
                    self.stdout.write(f"  · Exists   {full_name} <{email}>")
                email_to_user[email] = user

            # Create follow relationships
            follow_count = 0
            self.stdout.write("\nCreating follow relationships…")
            for follower_email, following_email in FOLLOW_EDGES:
                follower  = email_to_user.get(follower_email)
                following = email_to_user.get(following_email)
                if not follower or not following:
                    continue
                _, created = Follow.objects.get_or_create(
                    follower=follower, following=following
                )
                if created:
                    follow_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"\n✅  Done — {created_count} user(s) created, {follow_count} follow edge(s) added."
            )
        )
        self.stdout.write(
            "\nAll test accounts use password:  Test1234!\n"
            "Tip: run  python manage.py retrain_recommender  (or restart the server)\n"
            "to re-train LightGCN with the new data.\n"
        )
