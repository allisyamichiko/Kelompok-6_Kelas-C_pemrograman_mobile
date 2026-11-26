import 'package:flutter/material.dart';

class TeamlyHeroIllustration extends StatelessWidget {
  const TeamlyHeroIllustration({super.key, this.size = 96, this.onDark = true});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _HeroIllustrationPainter(onDark: onDark)),
    );
  }
}

class _HeroIllustrationPainter extends CustomPainter {
  const _HeroIllustrationPainter({required this.onDark});
  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final cardFill = Paint()
      ..color = onDark
          ? Colors.white.withValues(alpha: 0.18)
          : const Color(0xFFFFEDD5);
    final accentFill = Paint()
      ..color = onDark
          ? Colors.white.withValues(alpha: 0.90)
          : const Color(0xFFF97316);
    final softFill = Paint()
      ..color = onDark
          ? Colors.white.withValues(alpha: 0.45)
          : const Color(0xFFFDBA74);
    final greenFill = Paint()..color = const Color(0xFF34D399);
    final yellowFill = Paint()..color = const Color(0xFFFDE047);

    // Main Kanban board card
    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.16, w * 0.74, h * 0.62),
      Radius.circular(w * 0.10),
    );
    canvas.drawRRect(boardRect, cardFill);

    // Top window dots
    canvas.drawCircle(Offset(w * 0.24, h * 0.25), w * 0.028, yellowFill);
    canvas.drawCircle(Offset(w * 0.33, h * 0.25), w * 0.028, greenFill);

    // Task bars inside board
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.34, w * 0.44, h * 0.075),
        Radius.circular(w * 0.04),
      ),
      accentFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.46, w * 0.56, h * 0.065),
        Radius.circular(w * 0.03),
      ),
      softFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.57, w * 0.36, h * 0.065),
        Radius.circular(w * 0.03),
      ),
      softFill,
    );

    // Collaborator avatars overlapping bottom-right
    final avatarBorder = Paint()
      ..color = onDark ? const Color(0xFFEA580C) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025;

    final av1 = Offset(w * 0.64, h * 0.78);
    final av2 = Offset(w * 0.78, h * 0.78);

    canvas.drawCircle(av1, w * 0.10, Paint()..color = const Color(0xFF6366F1));
    canvas.drawCircle(av1, w * 0.10, avatarBorder);
    canvas.drawCircle(av2, w * 0.10, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(av2, w * 0.10, avatarBorder);

    // Sparkle top-left
    canvas.drawCircle(Offset(w * 0.12, h * 0.12), w * 0.035, yellowFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TeamlyEmptyTaskIllustration extends StatelessWidget {
  const TeamlyEmptyTaskIllustration({super.key, this.size = 110});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _EmptyTaskPainter()),
    );
  }
}

class _EmptyTaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft background circle
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.52),
      w * 0.42,
      Paint()..color = const Color(0xFFFFF7ED),
    );

    // Clipboard body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.26, h * 0.20, w * 0.48, h * 0.60),
        Radius.circular(w * 0.08),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.26, h * 0.20, w * 0.48, h * 0.60),
        Radius.circular(w * 0.08),
      ),
      Paint()
        ..color = const Color(0xFFFED7AA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Clipboard clip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.38, h * 0.15, w * 0.24, h * 0.09),
        Radius.circular(w * 0.04),
      ),
      Paint()..color = const Color(0xFFF97316),
    );

    // Check lines
    final linePaint = Paint()..color = const Color(0xFFE2E8F0);
    for (var i = 0; i < 3; i++) {
      final y = h * (0.36 + i * 0.14);
      canvas.drawCircle(
        Offset(w * 0.35, y + h * 0.025),
        w * 0.032,
        Paint()..color = i == 0 ? const Color(0xFF34D399) : const Color(0xFFFED7AA),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.42, y, w * 0.25, h * 0.045),
          Radius.circular(w * 0.02),
        ),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
