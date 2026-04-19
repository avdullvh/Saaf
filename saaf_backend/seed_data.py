"""
seed_data.py — Populate Saaf DB with 50 fake users and their posts.
Run from project root: python saaf_backend/seed_data.py
"""

import os
import sys
import random
import shutil
from pathlib import Path

# ── Django setup ──────────────────────────────────────────────────────────────
ROOT = Path(__file__).resolve().parent        # saaf_backend/
PROJECT_ROOT = ROOT.parent                    # repo root (where feedPhotos/ lives)
sys.path.insert(0, str(ROOT))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'saaf.settings')

import django
django.setup()

from accounts.models import User, Follow
from feed.models import Post, Like

# ── Data pools ────────────────────────────────────────────────────────────────

ARABIC_NAMES = [
    "عبدالله الغامدي", "محمد العتيبي", "سالم الزهراني", "خالد المطيري", "فهد الشهري",
    "يوسف الدوسري", "عمر القحطاني", "أحمد الحربي", "نواف السبيعي", "سعد البقمي",
    "ماجد العمري", "طارق الرشيدي", "بندر المالكي", "عبدالعزيز الأسمري", "فيصل الجهني",
    "راشد العنزي", "منصور السلمي", "حمزة الشمري", "وليد الثبيتي", "إبراهيم العجمي",
    "علي الكعبي", "ناصر المنصوري", "جاسم البلوشي", "سلطان الرميثي", "حمد المزروعي",
    "صالح الكندي", "عيسى الظاهري", "مرعي الهاجري", "سيف العامري", "زياد الفلاسي",
    "حسن الشكيلي", "يعقوب المعمري", "بدر الريامي", "عبدالرحمن الوهيبي", "خلفان الحسيني",
    "مازن الصالحي", "رامي البريكي", "تركي الحمودي", "سامي الغريب", "نبيل القرني",
    "حمود العسيري", "جابر الداود", "مشعل الفريدي", "دخيل الرويلي", "عطا الله الحازمي",
    "مبارك الصبيحي", "رياض المطرفي", "وضاح العتيبي", "حسين الغساني", "عقيل الصواف",
]

BIOS = [
    "مزارع نخيل من المدينة المنورة 🌴",
    "أحب الزراعة والطبيعة، أعمل في مزرعة العائلة منذ الصغر.",
    "صاحب مزرعة نخيل في الأحساء، نخيلي هي كل دنياي.",
    "خبير في زراعة النخيل وأمراضه، أشارككم تجربتي.",
    "مزارع شغوف من الرياض، أتابع صحة نخيلي يومياً.",
    "ورثت عن أبي حب النخيل والأرض.",
    "نخيل المدينة ومزارعها الخضراء تسكن قلبي.",
    "أعمل في الزراعة العضوية وأتجنب المبيدات.",
    "طالب زراعة، أطبق ما أتعلمه على نخيل أسرتي.",
    "مهتم بالحفاظ على أصناف النخيل النادرة.",
]

DISEASE_TYPES = [
    "Healthy",
    "Bayoud Disease",
    "White Scale",
    "Black Scorch",
    "Inflorescence Rot",
]

CAPTIONS = {
    "Healthy": [
        "الحمد لله نخيلي بصحة ممتازة هذا الموسم 💚 الثمار طالعة حلوة وكبيرة.",
        "شفت النخلة اليوم وهي بأحسن حال 🌴 ربنا يديم النعمة.",
        "نخلتي الصغيرة كبرت وصارت تعطي أجمل الثمار، سبحان الله 🌴💚",
        "نخيل المزرعة كلها بخير والحمد لله، الخضرة في كل مكان 🌿",
        "نتايج التحليل ممتازة، النخلة صحتها مية بالمية 💯",
        "الموسم هذا أحسن موسم، النخيل ما شاء الله زاهية ومعطية 🌴",
        "اطمنوا على نخيلنا، كلها بصحة وعافية والحمد لله 🙏",
    ],
    "Bayoud Disease": [
        "نخلتي هذي بدت تظهر عليها علامات مرض البيوض، نسبة الإصابة عالية. أرجو المساعدة 🌴",
        "لاحظت اصفرار في السعف وذبول في الأوراق، خايف يكون بيوض. وش تنصحوني؟",
        "مرض البيوض وصل للمزرعة 😢 فقدت ثلاث نخلات الأسبوع الماضي.",
        "السعف صار يتساقط وألوانه تغيرت، الجهاز شخّص مرض البيوض بنسبة عالية.",
        "يا ليت أحد يساعدني، النخلة هذي مريضة ومحتاجة علاج عاجل من مرض البيوض.",
    ],
    "White Scale": [
        "ظهرت على جريد النخلة بقع بيضاء صغيرة، الجهاز قال حشرة القشرة البيضاء 😟",
        "الحشرات البيضاء غطّت السعف، اضطريت أعزل النخلة عن باقي المزرعة.",
        "القشرة البيضاء منتشرة على جذع النخلة، وش أفضل علاج؟",
        "لاحظت إفراز أبيض لزج على الأوراق، يبدو إنه إصابة بحشرة القشرة البيضاء.",
        "النخلة تعبانة من القشرة البيضاء، نسبة الإصابة متوسطة والحمد لله.",
    ],
    "Black Scorch": [
        "أطراف السعف اسودّت فجأة، الجهاز كشف الحرق الأسود بنسبة عالية 😰",
        "الحرق الأسود أتلف جزء كبير من النخلة، أتمنى أنقذها قبل فوات الأوان.",
        "لاحظت تحول لون الجمار إلى الأسود، وهذا مؤشر خطر للحرق الأسود.",
        "النخلة هذي أصابها الحرق الأسود بشكل واضح، نحتاج تدخل سريع.",
        "الحرق الأسود بدأ من قمة النخلة وينتشر للأسفل، الوضع خطير.",
    ],
    "Inflorescence Rot": [
        "الطلع خرج هذا الموسم لكن الجهاز كشف تعفن في النورة الزهرية 😟",
        "تعفن النورة الزهرية أثّر على محصول هذا العام بشكل كبير.",
        "لاحظت رطوبة زايدة في منطقة الطلع وبدأ يتعفن، نسبة الإصابة متوسطة.",
        "النورة الزهرية تعفنت قبل الإخصاب، خسرنا إنتاج هذه النخلة.",
        "تعفن الطلع مشكلة منتشرة هذا الموسم بسبب الرطوبة العالية.",
    ],
}

# ── Helpers ───────────────────────────────────────────────────────────────────

def make_email(name: str, idx: int) -> str:
    slug = name.split()[0]
    latin_map = {
        "عبدالله": "Abdullah", "محمد": "Mohammed", "سالم": "Salem",
        "خالد": "Khalid", "فهد": "Fahad", "يوسف": "Yousuf",
        "عمر": "Omar", "أحمد": "Ahmed", "نواف": "Nawaf", "سعد": "Saad",
        "ماجد": "Majid", "طارق": "Tariq", "بندر": "Bandar",
        "عبدالعزيز": "AbdulAziz", "فيصل": "Faisal", "راشد": "Rashed",
        "منصور": "Mansour", "حمزة": "Hamza", "وليد": "Walid",
        "إبراهيم": "Ibrahim", "علي": "Ali", "ناصر": "Nasser",
        "جاسم": "Jasem", "سلطان": "Sultan", "حمد": "Hamad",
        "صالح": "Saleh", "عيسى": "Eisa", "مرعي": "Marei",
        "سيف": "Saif", "زياد": "Ziad", "حسن": "Hassan",
        "يعقوب": "Yaqoob", "بدر": "Badr", "عبدالرحمن": "AbdulRahman",
        "خلفان": "Khalfan", "مازن": "Mazen", "رامي": "Rami",
        "تركي": "Turki", "سامي": "Sami", "نبيل": "Nabil",
        "حمود": "Hamoud", "جابر": "Jaber", "مشعل": "Meshal",
        "دخيل": "Dakhil", "عطا": "Ata", "مبارك": "Mubarak",
        "رياض": "Riyad", "وضاح": "Wadah", "حسين": "Hussein",
        "عقيل": "Aqeel",
    }
    latin = latin_map.get(slug, f"user{idx}")
    domains = ["gmail.com", "hotmail.com", "yahoo.com", "outlook.com"]
    return f"{latin.lower()}{idx}@{random.choice(domains)}"


def pick_caption(disease: str) -> str:
    return random.choice(CAPTIONS[disease])


def copy_image_to_media(src: Path, media_posts: Path) -> str:
    """Copy src image into media/posts/ with a unique name; return relative path."""
    media_posts.mkdir(parents=True, exist_ok=True)
    dest_name = f"seed_{src.name}"
    dest = media_posts / dest_name
    if not dest.exists():
        shutil.copy2(src, dest)
    return f"posts/{dest_name}"


# ── Main ──────────────────────────────────────────────────────────────────────

def run():
    feed_photos_dir = PROJECT_ROOT / "feedPhotos"
    media_posts_dir = ROOT / "media" / "posts"

    photo_files = sorted(feed_photos_dir.glob("*.jpg")) + sorted(feed_photos_dir.glob("*.JPG"))
    if not photo_files:
        print("ERROR: No photos found in feedPhotos/")
        sys.exit(1)

    print(f"Found {len(photo_files)} photos in feedPhotos/")

    # ── 1. Create 50 users ────────────────────────────────────────────────────
    print("\n[1/4] Creating users...")
    created_users = []

    for idx, full_name in enumerate(ARABIC_NAMES):
        email = make_email(full_name, idx + 1)
        if User.objects.filter(email=email).exists():
            print(f"  SKIP (exists): {email}")
            user = User.objects.get(email=email)
        else:
            user = User(
                email=email,
                full_name=full_name,
                bio=random.choice(BIOS),
            )
            user.set_password("Saaf@1234")
            user.save()
            print(f"  Created: {full_name} <{email}>")
        created_users.append(user)

    print(f"  Total users ready: {len(created_users)}")

    # ── 2. Create posts ───────────────────────────────────────────────────────
    print("\n[2/4] Creating posts...")
    all_posts = []
    photo_cycle = list(photo_files)
    random.shuffle(photo_cycle)
    photo_index = 0

    for user in created_users:
        num_posts = random.randint(2, 5)
        for _ in range(num_posts):
            disease = random.choice(DISEASE_TYPES)
            confidence = round(random.uniform(0.75, 0.99), 4)
            caption = pick_caption(disease)

            photo = photo_cycle[photo_index % len(photo_cycle)]
            photo_index += 1
            rel_path = copy_image_to_media(photo, media_posts_dir)

            post = Post.objects.create(
                author=user,
                caption=caption,
                image=rel_path,
                predicted_type=disease,
                confidence_score=confidence,
            )
            all_posts.append(post)

        print(f"  {user.full_name}: {num_posts} posts")

    print(f"  Total posts created: {len(all_posts)}")

    # ── 3. Create follow relationships ────────────────────────────────────────
    print("\n[3/4] Creating follow relationships...")
    follow_count = 0

    for user in created_users:
        others = [u for u in created_users if u.pk != user.pk]
        targets = random.sample(others, min(random.randint(5, 15), len(others)))
        for target in targets:
            _, created = Follow.objects.get_or_create(follower=user, following=target)
            if created:
                follow_count += 1

    print(f"  Total follow relationships created: {follow_count}")

    # ── 4. Add random likes ───────────────────────────────────────────────────
    print("\n[4/4] Adding likes...")
    like_count = 0

    for user in created_users:
        sample_size = min(random.randint(5, 20), len(all_posts))
        posts_to_like = random.sample(all_posts, sample_size)
        for post in posts_to_like:
            if post.author_id == user.pk:
                continue
            _, created = Like.objects.get_or_create(user=user, post=post)
            if created:
                like_count += 1

    print(f"  Total likes created: {like_count}")

    print("\n✓ Seeding complete!")
    print(f"  Users:   {len(created_users)}")
    print(f"  Posts:   {len(all_posts)}")
    print(f"  Follows: {follow_count}")
    print(f"  Likes:   {like_count}")


if __name__ == "__main__":
    try:
        run()
    except Exception as exc:
        import traceback
        print("\nERROR during seeding:")
        traceback.print_exc()
        sys.exit(1)
