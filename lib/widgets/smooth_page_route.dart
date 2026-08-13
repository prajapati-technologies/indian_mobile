import 'package:flutter/material.dart';

/// Smooth slide + fade transition for page navigation.
/// Use instead of MaterialPageRoute for smoother feel.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(curve),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.5, end: 1.0).animate(curve),
                child: child,
              ),
            );
          },
        );

  final Widget page;
}
