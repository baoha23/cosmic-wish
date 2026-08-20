import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Live-updating "X ngày Y giờ Z phút" countdown towards [target].
/// When the target has passed, shows "Vũ trụ đã hồi đáp".
class CountdownLabel extends StatefulWidget {
  const CountdownLabel({
    super.key,
    required this.target,
    this.style,
    this.align = TextAlign.center,
  });

  final DateTime target;
  final TextStyle? style;
  final TextAlign align;

  @override
  State<CountdownLabel> createState() => _CountdownLabelState();
}

class _CountdownLabelState extends State<CountdownLabel> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.target.difference(DateTime.now());
    final base = widget.style ?? AppText.body(15);
    if (remaining.isNegative) {
      return Text(
        'Vũ trụ đã hồi đáp',
        textAlign: widget.align,
        style: base.copyWith(
          color: AppColors.goldWhisper,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days ngày');
    if (hours > 0 || days > 0) parts.add('$hours giờ');
    if (days == 0 && hours == 0) parts.add('$minutes phút');
    if (days == 0 && hours == 0 && minutes == 0) parts.add('$seconds giây');
    if (parts.isEmpty) parts.add('${remaining.inSeconds} giây');

    return Text(
      'Vũ trụ sẽ hồi đáp sau ${parts.join(' ')}',
      textAlign: widget.align,
      style: base.copyWith(color: AppColors.goldWhisper),
    );
  }
}
