// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'سعف';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get noAccount => 'ليس لديك حساب؟ سجّل الآن';

  @override
  String get hasAccount => 'لديك حساب بالفعل؟ سجّل دخولك';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get uploadTitle => 'تصنيف النخلة';

  @override
  String get uploadPrompt => 'التقط أو ارفع صورة لسعف النخلة';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get classifyButton => 'تصنيف';

  @override
  String get classifying => 'جارٍ تحليل الصورة...';

  @override
  String get resultTitle => 'نتيجة التصنيف';

  @override
  String get palmType => 'نوع النخلة';

  @override
  String get confidence => 'نسبة الثقة';

  @override
  String get shareToFeed => 'مشاركة في المجتمع';

  @override
  String get classifyAnother => 'تصنيف صورة أخرى';

  @override
  String get feedTitle => 'مجتمع المزارعين';

  @override
  String likes(int count) {
    return '$count إعجاب';
  }

  @override
  String comments(int count) {
    return '$count تعليق';
  }

  @override
  String get addComment => 'أضف تعليقاً...';

  @override
  String get post => 'نشر';

  @override
  String get shareCaption => 'اكتب تعليقاً (اختياري)';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noPostsYet => 'لا توجد منشورات بعد.\nكن أول من يشارك نتيجة تصنيف!';

  @override
  String get tabClassify => 'تصنيف';

  @override
  String get tabFeed => 'المجتمع';

  @override
  String get tabProfile => 'الملف';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileNotFound => 'الملف الشخصي غير موجود';

  @override
  String get editProfile => 'تعديل الملف';

  @override
  String get bio => 'نبذة تعريفية';

  @override
  String get posts => 'المنشورات';

  @override
  String get noPostsProfile => 'لا توجد منشورات بعد';

  @override
  String get addBioHint => 'اضغط لإضافة نبذة تعريفية';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي!';

  @override
  String get profileUpdateFailed => 'فشل التحديث. حاول مرة أخرى.';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get postTitle => 'المنشور';

  @override
  String get noCommentsYet => 'لا توجد تعليقات بعد. كن أول من يعلّق!';

  @override
  String get commentHint => 'أضف تعليقاً…';

  @override
  String get darkMode => 'التبديل إلى الوضع الداكن';

  @override
  String get lightMode => 'التبديل إلى الوضع الفاتح';

  @override
  String get cancel => 'إلغاء';

  @override
  String get language => 'اللغة';

  @override
  String get errorGeneric => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get errorNetwork => 'خطأ في الشبكة. تحقق من اتصالك.';

  @override
  String get errorInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get errorImagePick => 'تعذّر تحميل الصورة.';

  @override
  String get successPost => 'تم النشر في المجتمع بنجاح!';

  @override
  String get goToFeed => 'الذهاب إلى المجتمع';

  @override
  String get postSharedMessage => 'منشورك الآن ظاهر للمجتمع.';
}
