import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleLogo(),
                const SizedBox(width: 12),
                Text(
                  'Continuer avec Google',
                  style: TextStyle(
                    color: Colors.grey[200],
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Blue segment
    _drawSegment(canvas, cx, cy, r, -0.1, 1.4, const Color(0xFF4285F4));
    // Red segment
    _drawSegment(canvas, cx, cy, r, 1.4, 2.7, const Color(0xFFEA4335));
    // Yellow segment
    _drawSegment(canvas, cx, cy, r, 2.7, 3.8, const Color(0xFFFBBC05));
    // Green segment
    _drawSegment(canvas, cx, cy, r, 3.8, 2 * 3.14159 - 0.1, const Color(0xFF34A853));

    // White center circle
    final whitePaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, whitePaint);

    // "G" notch - draw the horizontal bar of the G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = r * 0.35
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.55, cy),
      barPaint,
    );
  }

  void _drawSegment(Canvas canvas, double cx, double cy, double r,
      double startAngle, double endAngle, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        endAngle - startAngle,
        false,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
