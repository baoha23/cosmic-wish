import 'wish_category.dart';
import 'wish_prophecy.dart';

class WishSession {
  WishSession({required this.category, this.transcript = ''});

  final WishCategory category;

  /// The user's wish text. Mutable so the camera screen can set it
  /// before pushing the loading screen.
  String transcript;

  /// Filled in by the AI during the ritual. Holds the rich prophecy
  /// (main message + signs + action + affirmation) or a plain-text
  /// fallback when the backend only returned a single string.
  WishProphecy? response;

  /// The personalized question returned by the first AI turn.
  String? reflectionQuestion;

  /// The user's answer to [reflectionQuestion], sent with the original
  /// wish on the second turn.
  String? reflectionAnswer;
}
