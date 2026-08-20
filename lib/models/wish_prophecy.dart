/// AI's reply to the user's wish. Returned by WishService.generateProphecy.
///
/// Holds a single prophecy string. We used to carry a structured shape
/// (main message / signs / action / affirmation) but that pushed the
/// model into rigid patterns — it kept reusing the same opening line
/// ("Cái X mà ngươi cứ ôm...") and lost the spontaneous feel of a
/// prophecy. A free-text reply gives the model room to vary.
class WishProphecy {
  const WishProphecy({required this.text});

  /// The prophecy as plain text. Always populated when the call
  /// succeeded — may be a fallback string if the model was unreachable.
  final String text;

  /// True if the backend returned real model output (i.e. text is a
  /// genuine prophecy, not a canned fallback). False when text is the
  /// generic "Vũ trụ tạm im lặng…" fallback.
  bool get isStructured => text.isNotEmpty;
}
