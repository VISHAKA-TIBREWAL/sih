// lib/utils/page_transitions.dart
import 'package:flutter/material.dart';

/// Custom page route transitions for smoother navigation between screens
class PageRoutes {
  /// Fade transition between pages with shared elements
  static Route<T> fadeThrough<T>(Widget page, [int duration = 400]) {
    return PageRouteBuilder<T>(
      transitionDuration: Duration(milliseconds: duration),
      reverseTransitionDuration: Duration(milliseconds: duration),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      maintainState: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Make it smoother with custom curves
        var fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: child,
        );
      },
    );
  }
  
  /// Smooth slide transition from right to left (standard navigation)
  static Route<T> slideRight<T>(Widget page, [int duration = 400]) {
    return PageRouteBuilder<T>(
      transitionDuration: Duration(milliseconds: duration),
      reverseTransitionDuration: Duration(milliseconds: duration),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      maintainState: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeOutQuint; // Smoother curve
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        // Add a fade as well for smoother effect
        final fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutQuint)
        );
        
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }
  
  /// Smooth slide transition from left to right (going back)
  static Route<T> slideLeft<T>(Widget page, [int duration = 400]) {
    return PageRouteBuilder<T>(
      transitionDuration: Duration(milliseconds: duration),
      reverseTransitionDuration: Duration(milliseconds: duration),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      maintainState: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeOutQuint; // Smoother curve
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        // Add a fade as well for smoother effect
        final fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutQuint)
        );
        
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }
  
  /// Elegant scale and fade transition
  static Route<T> scaleFade<T>(Widget page, [int duration = 400]) {
    return PageRouteBuilder<T>(
      transitionDuration: Duration(milliseconds: duration),
      reverseTransitionDuration: Duration(milliseconds: duration),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      maintainState: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuint,
          ),
        );
        
        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuint,
          ),
        );
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }
}