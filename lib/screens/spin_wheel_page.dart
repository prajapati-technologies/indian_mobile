import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SpinWheelPage extends StatefulWidget {
  final ApiService api;
  final String token;
  final int initialCoins;
  final int initialRemainingSpins;
  final int initialBonusSpins;

  const SpinWheelPage({
    super.key,
    required this.api,
    required this.token,
    required this.initialCoins,
    required this.initialRemainingSpins,
    required this.initialBonusSpins,
  });

  @override
  State<SpinWheelPage> createState() => _SpinWheelPageState();
}

class _SpinWheelPageState extends State<SpinWheelPage> with SingleTickerProviderStateMixin {
  late int _coins;
  late int _remainingSpins;
  late int _bonusSpins;
  bool _isSpinning = false;

  late AnimationController _controller;
  late Animation<double> _animation;

  // The 6 segments from backend:
  // 5 Coins, 10 Coins, 20 Coins, 50 Coins, Try Again, Bonus Spin
  final List<String> _segments = [
    '5 Coins',
    '10 Coins',
    '20 Coins',
    '50 Coins',
    'Try Again',
    'Bonus Spin'
  ];

  final List<Color> _colors = [
    const Color(0xFFF0F4FA),
    AppColors.brandOrange.withValues(alpha: 0.2),
    const Color(0xFFF0F4FA),
    AppColors.brandOrange.withValues(alpha: 0.2),
    const Color(0xFFF0F4FA),
    AppColors.brandOrange.withValues(alpha: 0.2),
  ];

  @override
  void initState() {
    super.initState();
    _coins = widget.initialCoins;
    _remainingSpins = widget.initialRemainingSpins;
    _bonusSpins = widget.initialBonusSpins;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Initial static state
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_isSpinning || _remainingSpins <= 0) return;

    setState(() {
      _isSpinning = true;
    });

    try {
      final res = await widget.api.postJson(
        '/rewards/spin',
        {},
        token: widget.token,
      );
      final data = res as Map<String, dynamic>;

      if (data['ok'] == true) {
        final String label = data['label'];
        final int targetIndex = _segments.indexOf(label);
        
        // If label not found exactly, default to 0 just to spin somewhere
        final int finalTargetIndex = targetIndex >= 0 ? targetIndex : 0;

        // Calculate rotation
        // Each segment is (2 * pi / 6) radians.
        // We want the target segment to end up at the TOP (which is -pi/2 in our drawing, but we can just calculate standard offset).
        // Let's spin 5 full times + the offset to the target.
        final double segmentAngle = 2 * pi / _segments.length;
        
        // Target angle is where the segment center is at the top.
        // In our CustomPainter, segment 0 starts at -pi/2.
        // So segment i starts at -pi/2 + i*segmentAngle, centered at -pi/2 + (i+0.5)*segmentAngle.
        // To bring it to top (-pi/2), we need to rotate backwards by (i+0.5)*segmentAngle.
        // We add 5 full rotations (10 * pi).
        final double stopAngle = (10 * pi) - ((finalTargetIndex + 0.5) * segmentAngle);

        _animation = Tween<double>(
          begin: _controller.value,
          end: _controller.value + stopAngle,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCirc));

        await _controller.forward(from: 0);

        setState(() {
          _coins = data['coin_balance'] ?? _coins;
          _remainingSpins = data['remaining_spins'] ?? _remainingSpins;
          _bonusSpins = data['bonus_spins'] ?? _bonusSpins;
        });

        if (mounted) {
          _showResultDialog(label, data['coins'] ?? 0);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiConnectionException ? e.message : e.toString()),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSpinning = false;
        });
      }
    }
  }

  void _showResultDialog(String label, int coinsWon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(coinsWon > 0 ? Icons.celebration : Icons.info_outline, 
                 color: AppColors.brandOrange, size: 28),
            const SizedBox(width: 8),
            const Text('Result', style: TextStyle(color: AppColors.brandNavy)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (coinsWon > 0)
              Text('Congratulations! You won $coinsWon coins.')
            else
              const Text('Better luck next time!'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _coins);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.brandNavy,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Daily Spin',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: AppColors.brandOrange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$_coins',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const SizedBox(height: 20),
            const Text(
              'Test Your Luck!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Spins Remaining: $_remainingSpins',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_bonusSpins > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brandOrange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+$_bonusSpins Bonus Spins',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.brandOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The spinning wheel
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animation.value,
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 300,
                      height: 300,
                      child: CustomPaint(
                        painter: _WheelPainter(segments: _segments, colors: _colors),
                      ),
                    ),
                  ),
                  // The pointer at the top
                  Positioned(
                    top: -20,
                    child: Transform.rotate(
                      angle: 0,
                      child: const Icon(
                        Icons.arrow_drop_down_circle,
                        size: 48,
                        color: AppColors.brandOrange,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                    ),
                  ),
                  // Center button
                  GestureDetector(
                    onTap: _remainingSpins > 0 ? _spin : null,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'SPIN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandNavy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FilledButton(
                onPressed: _remainingSpins > 0 && !_isSpinning ? _spin : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isSpinning ? 'SPINNING...' : 'SPIN NOW',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> segments;
  final List<Color> colors;

  _WheelPainter({required this.segments, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final double sweepAngle = 2 * pi / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      // Start from -pi/2 (Top)
      final startAngle = -pi / 2 + i * sweepAngle;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Draw border
      final borderPaint = Paint()
        ..color = AppColors.brandNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

      // Draw Text
      canvas.save();
      canvas.translate(center.dx, center.dy);
      // Rotate to the middle of the segment
      canvas.rotate(startAngle + sweepAngle / 2);
      
      final textSpan = TextSpan(
        text: segments[i],
        style: const TextStyle(
          color: AppColors.brandNavy,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Translate to draw text near the outer edge
      textPainter.paint(
        canvas,
        Offset(radius * 0.45, -textPainter.height / 2),
      );

      canvas.restore();
    }

    // Draw outer glowing rim
    final outerRimPaint = Paint()
      ..color = AppColors.brandOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, outerRimPaint);

    final outerRimShadow = Paint()
      ..color = AppColors.brandOrange.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(center, radius, outerRimShadow);

    // Draw inner solid rim
    final innerRimPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.25, innerRimPaint);

    // Inner rim decoration
    final innerRimDeco = Paint()
      ..color = AppColors.brandNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius * 0.25, innerRimDeco);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
