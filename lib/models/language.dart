class Language {
  final String code;
  final String name;
  final String localizedName;
  final String flagCode;

  const Language({
    required this.code,
    required this.name,
    required this.localizedName,
    required this.flagCode,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      code: json['code'],
      name: json['name'],
      localizedName: json['localizedName'],
      flagCode: json['flagCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'localizedName': localizedName,
      'flagCode': flagCode,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Language && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

// List of supported languages
class SupportedLanguages {
  static const Language english = Language(
    code: 'en',
    name: 'English',
    localizedName: 'English',
    flagCode: 'gb',
  );

  static const Language french = Language(
    code: 'fr',
    name: 'French',
    localizedName: 'Français',
    flagCode: 'fr',
  );

  static const Language arabic = Language(
    code: 'ar',
    name: 'Arabic',
    localizedName: 'العربية',
    flagCode: 'sa',
  );

  static const Language hausa = Language(
    code: 'ha',
    name: 'Hausa',
    localizedName: 'Hausa',
    flagCode: 'ng',
  );

  static const Language yoruba = Language(
    code: 'yo',
    name: 'Yoruba',
    localizedName: 'Yorùbá',
    flagCode: 'ng',
  );

  static const Language igbo = Language(
    code: 'ig',
    name: 'Igbo',
    localizedName: 'Igbo',
    flagCode: 'ng',
  );

  static const List<Language> supportedLanguages = [
    english,
    french,
    arabic,
    hausa,
    yoruba,
    igbo,
  ];

  static Language getLanguageByCode(String code) {
    return supportedLanguages.firstWhere(
      (language) => language.code == code,
      orElse: () => english,
    );
  }
}
