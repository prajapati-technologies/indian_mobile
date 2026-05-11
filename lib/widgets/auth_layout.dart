import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  final Widget child;
  final bool isLogin;

  const AuthLayout({
    super.key,
    required this.child,
    this.isLogin = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          // Top Wave
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: CustomPaint(
              painter: _TopWavePainter(isLogin: isLogin),
            ),
          ),

          // Bottom Wave
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 150,
            child: CustomPaint(
              painter: _BottomWavePainter(),
            ),
          ),

          // Main Content Area
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Placeholder for Logo
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 60,
                            color: Color(0xFF0F2C59),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              children: [
                                TextSpan(
                                  text: 'India ',
                                  style: TextStyle(color: Color(0xFF0F2C59)),
                                ),
                                TextSpan(
                                  text: 'Informations',
                                  style: TextStyle(color: Color(0xFFFF6B00)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'SACCHI JANKARI, SABKE LIYE, SABSE PEHLE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F2C59),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    child,
                    const SizedBox(height: 80), // padding for bottom wave
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopWavePainter extends CustomPainter {
  final bool isLogin;

  _TopWavePainter({required this.isLogin});

  @override
  void paint(Canvas canvas, Size size) {
    if (isLogin) {
      // Orange Wave
      final path = Path();
      path.moveTo(0, 0);
      path.lineTo(0, size.height * 0.7);
      path.quadraticBezierTo(
        size.width * 0.4, size.height * 0.3,
        size.width, size.height * 0.8,
      );
      path.lineTo(size.width, 0);
      path.close();

      final paint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, paint);
    } else {
      // Blue Wave with inner curve
      final bgPath = Path();
      bgPath.moveTo(0, 0);
      bgPath.lineTo(0, size.height * 0.8);
      bgPath.quadraticBezierTo(
        size.width * 0.5, size.height * 0.2,
        size.width, size.height * 0.9,
      );
      bgPath.lineTo(size.width, 0);
      bgPath.close();

      final bgPaint = Paint()
        ..color = const Color(0xFF0F2C59);

      // Green/Orange edge highlight
      final edgePath = Path();
      edgePath.moveTo(0, size.height * 0.8);
      edgePath.quadraticBezierTo(
        size.width * 0.5, size.height * 0.2,
        size.width, size.height * 0.9,
      );
      edgePath.lineTo(size.width, size.height * 0.95);
      edgePath.quadraticBezierTo(
        size.width * 0.5, size.height * 0.25,
        0, size.height * 0.85,
      );
      edgePath.close();

      final edgePaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF008A20), Color(0xFFFF6B00)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(edgePath, edgePaint);
      canvas.drawPath(bgPath, bgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Orange Bottom Wave
    final orangePath = Path();
    orangePath.moveTo(0, size.height * 0.4);
    orangePath.quadraticBezierTo(
      size.width * 0.25, size.height * 0.8,
      size.width * 0.5, size.height * 0.5,
    );
    orangePath.quadraticBezierTo(
      size.width * 0.75, size.height * 0.2,
      size.width, size.height * 0.6,
    );
    orangePath.lineTo(size.width, size.height);
    orangePath.lineTo(0, size.height);
    orangePath.close();

    final orangePaint = Paint()
      ..color = const Color(0xFFFF6B00);
    canvas.drawPath(orangePath, orangePaint);

    // Green Bottom Wave
    final greenPath = Path();
    greenPath.moveTo(0, size.height * 0.6);
    greenPath.quadraticBezierTo(
      size.width * 0.3, size.height * 0.9,
      size.width * 0.6, size.height * 0.6,
    );
    greenPath.quadraticBezierTo(
      size.width * 0.8, size.height * 0.4,
      size.width, size.height * 0.7,
    );
    greenPath.lineTo(size.width, size.height);
    greenPath.lineTo(0, size.height);
    greenPath.close();

    final greenPaint = Paint()
      ..color = const Color(0xFF007A25);
    canvas.drawPath(greenPath, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
