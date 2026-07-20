import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';

/// أدوار أفراد العائلة لطقم روزي تاج المتماثل.
abstract final class FamilyMemberRoles {
  static const father = 'father';
  static const motherHijab = 'mother_hijab';
  static const motherSport = 'mother_sport';
  static const girlBig = 'girl_big';
  static const girlMid = 'girl_mid';
  static const girlSmall = 'girl_small';
  static const girlBaby = 'girl_baby';
  static const boyBig = 'boy_big';
  static const boyMid = 'boy_mid';
  static const boySmall = 'boy_small';
  static const boyBaby = 'boy_baby';

  /// توافق مع الأدوار القديمة.
  static const mother = 'mother';
  static const child = 'child';

  static const all = <String>[
    father,
    motherHijab,
    motherSport,
    girlBig,
    girlMid,
    girlSmall,
    girlBaby,
    boyBig,
    boyMid,
    boySmall,
    boyBaby,
  ];

  static const labelsAr = <String, String>{
    father: 'الأب',
    motherHijab: 'الأم المحجبة',
    motherSport: 'الأم سبور',
    mother: 'الأم',
    girlBig: 'البنت الكبيرة',
    girlMid: 'البنت المتوسطة',
    girlSmall: 'البنت الصغيرة',
    girlBaby: 'البيبي بنت',
    boyBig: 'الولد الكبير',
    boyMid: 'الولد المتوسط',
    boySmall: 'الولد الصغير',
    boyBaby: 'البيبي صبي',
    child: 'طفل',
  };

  static const labelsEn = <String, String>{
    father: 'Father',
    motherHijab: 'Mother (hijab)',
    motherSport: 'Mother (sport)',
    mother: 'Mother',
    girlBig: 'Older daughter',
    girlMid: 'Middle daughter',
    girlSmall: 'Younger daughter',
    girlBaby: 'Baby girl',
    boyBig: 'Older son',
    boyMid: 'Middle son',
    boySmall: 'Younger son',
    boyBaby: 'Baby boy',
    child: 'Child',
  };

  static bool get _english {
    try {
      if (Get.isRegistered<LanguageController>()) {
        return LanguageController.instance.isEnglish;
      }
    } catch (_) {}
    return false;
  }

  static String label(String role) {
    if (_english) return labelsEn[role] ?? labelsAr[role] ?? role;
    return labelsAr[role] ?? role;
  }

  static String genderFor(String role) {
    if (role == father || role.startsWith('boy')) return 'male';
    if (role.startsWith('mother') || role.startsWith('girl') || role == mother) {
      return 'female';
    }
    return '';
  }

  static String genderLabel(String gender) {
    final en = _english;
    switch (gender) {
      case 'male':
        return en ? 'Male' : 'ذكر';
      case 'female':
        return en ? 'Female' : 'أنثى';
      default:
        return gender;
    }
  }

  static const defaultSizes = <String>[
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '2-3',
    '4-5',
    '6-7',
    '8-9',
    '10-11',
    '12-13',
  ];
}
