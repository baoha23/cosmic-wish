import 'dart:math';

/// Returns a short reflection prompt (a question to journal about) in
/// the user's language. We use a static pool rather than calling the
/// AI — reflection is a quiet personal moment, and offline/no-network
/// support matters here.
///
/// Each call picks a different prompt so the user doesn't see the
/// same line three days in a row.
class ReflectionPromptService {
  ReflectionPromptService({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Supported locales — must match [AppLocalizations.supportedLocales].
  static const _vi = <String>[
    'Hôm nay, điều ước này còn vang trong ngươi không?',
    'Đã có dấu hiệu nào xuất hiện — dù nhỏ — mà ngươi từng bỏ qua?',
    'Nếu điều ước thành hiện, ngươi sẽ làm gì khác ngay bây giờ?',
    'Ngươi có đang ôm điều ước này đúng cách, hay đang quên nó?',
    'Một người ngươi yêu sẽ nói gì về điều ước này?',
    'Khoảnh khắc nào trong tuần qua khiến ngươi nhớ đến điều ước?',
    'Ngươi đã sẵn sàng buông điều ước này chưa?',
  ];

  static const _en = <String>[
    'Is this wish still humming inside you today?',
    'Have you noticed any small sign you might have overlooked?',
    'If the wish came true, what would you do differently right now?',
    'Are you holding this wish the way it wants to be held — or forgetting it?',
    'What would someone you love say about this wish?',
    'When this week did this wish quietly show up?',
    'Are you ready to release this wish?',
  ];

  String promptFor(String localeCode) {
    final pool = localeCode.startsWith('vi') ? _vi : _en;
    return pool[_random.nextInt(pool.length)];
  }
}
