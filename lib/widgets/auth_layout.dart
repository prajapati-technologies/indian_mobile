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
    final screenHeight = MediaQuery.of(context).size.height;
    final topWaveHeight = screenHeight * 0.28;
    final bottomWaveHeight = screenHeight * 0.15;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          // Top Wave Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topWaveHeight,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, topWaveHeight),
              painter: _TopWavePainter(isLogin: isLogin),
            ),
          ),

          // Bottom Wave Background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: bottomWaveHeight,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, bottomWaveHeight),
              painter: _BottomWavePainter(),
            ),
          ),

          // Main Content Area
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Logo Section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F2C59).withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.info_rounded,
                                size: 40,
                                color: Color(0xFF0F2C59),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 26,
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
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F2C59),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Form Content
                    child,
                    const SizedBox(height: 60),
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
      // Orange gradient wave for Login
      final path = Path();
      path.moveTo(0, 0);
      path.lineTo(0, size.height * 0.65);
      path.quadraticBezierTo(
        size.width * 0.35, size.height * 0.85,
        size.width * 0.6, size.height * 0.6,
      );
      path.quadraticBezierTo(
        size.width * 0.85, size.height * 0.35,
        size.width, size.height * 0.55,
      );
      path.lineTo(size.width, 0);
      path.close();

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFFFF6B00), const Color(0xFFFF9800).withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, paint);

      // Subtle lighter overlay wave
      final overlayPath = Path();
      overlayPath.moveTo(0, 0);
      overlayPath.lineTo(0, size.height * 0.45);
      overlayPath.quadraticBezierTo(
        size.width * 0.5, size.height * 0.65,
        size.width, size.height * 0.35,
      );
      overlayPath.lineTo(size.width, 0);
      overlayPath.close();

      final overlayPaint = Paint()
        ..color = Colors.white.withOpacity(0.15);
      canvas.drawPath(overlayPath, overlayPaint);
    } else {
      // Navy blue wave for Register
      final path = Path();
      path.moveTo(0, 0);
      path.lineTo(0, size.height * 0.7);
      path.quadraticBezierTo(
        size.width * 0.3, size.height * 0.9,
        size.width * 0.55, size.height * 0.65,
      );
      path.quadraticBezierTo(
        size.width * 0.8, size.height * 0.4,
        size.width, size.height * 0.6,
      );
      path.lineTo(size.width, 0);
      path.close();

      final bgPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0F2C59), Color(0xFF1A3F7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, bgPaint);

      // Green-orange accent edge
      final edgePath = Path();
      edgePath.moveTo(0, size.height * 0.7);
      edgePath.quadraticBezierTo(
        size.width * 0.3, size.height * 0.9,
        size.width * 0.55, size.height * 0.65,
      );
      edgePath.quadraticBezierTo(
        size.width * 0.8, size.height * 0.4,
        size.width, size.height * 0.6,
      );
      edgePath.lineTo(size.width, size.height * 0.65);
      edgePath.quadraticBezierTo(
        size.width * 0.8, size.height * 0.45,
        size.width * 0.55, size.height * 0.7,
      );
      edgePath.quadraticBezierTo(
        size.width * 0.3, size.height * 0.95,
        0, size.height * 0.75,
      );
      edgePath.close();

      final edgePaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF008A20), Color(0xFFFF6B00)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(edgePath, edgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TopWavePainter oldDelegate) =>
      oldDelegate.isLogin != isLogin;
}

class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Orange Bottom Wave
    final orangePath = Path();
    orangePath.moveTo(0, size.height * 0.5);
    orangePath.quadraticBezierTo(
      size.width * 0.25, size.height * 0.2,
      size.width * 0.5, size.height * 0.45,
    );
    orangePath.quadraticBezierTo(
      size.width * 0.75, size.height * 0.7,
      size.width, size.height * 0.35,
    );
    orangePath.lineTo(size.width, size.height);
    orangePath.lineTo(0, size.height);
    orangePath.close();

    final orangePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6B00), Color(0xFFFF9800)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(orangePath, orangePaint);

    // Green Bottom Wave (on top)
    final greenPath = Path();
    greenPath.moveTo(0, size.height * 0.7);
    greenPath.quadraticBezierTo(
      size.width * 0.3, size.height * 0.45,
      size.width * 0.6, size.height * 0.65,
    );
    greenPath.quadraticBezierTo(
      size.width * 0.85, size.height * 0.8,
      size.width, size.height * 0.55,
    );
    greenPath.lineTo(size.width, size.height);
    greenPath.lineTo(0, size.height);
    greenPath.close();

    final greenPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF008A20), Color(0xFF006A18)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(greenPath, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
