import 'package:flutter/material.dart';

/// A singleton service for handling navigation-related tasks.
///
/// This service allows for context-less navigation, meaning you can navigate
/// from your business logic (like a Provider or BLoC) without needing to pass
/// the BuildContext around.
///
/// How to use:
/// 1. Assign the navigatorKey to your MaterialApp:
///    MaterialApp(navigatorKey: NavigationService().navigatorKey, ...)
///
/// 2. Call navigation methods from anywhere in your app:
///    NavigationService().navigateTo('/details');
///
class NavigationService {
  // --- Singleton Pattern Setup ---

  // A private constructor to prevent direct instantiation.
  NavigationService._internal();

  // The single, static instance of the service.
  static final NavigationService _instance = NavigationService._internal();

  // The factory constructor that returns the single instance.
  // This allows you to call NavigationService() anywhere and get the same instance.
  factory NavigationService() {
    return _instance;
  }

  // --- Navigation Logic ---

  /// The global key for accessing the Navigator's state.
  /// This key must be assigned to the `navigatorKey` property of your MaterialApp.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Returns the current context of the Navigator.
  ///
  /// This is useful for showing app-wide dialogs, snackbars, or bottom sheets
  /// from a service layer. It can be null if the navigator is not yet built.
  BuildContext? get context => navigatorKey.currentContext;

  /// Pushes a named route onto the navigator stack.
  ///
  /// Returns a [Future] that completes to the result of the popped route.
  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    // Ensure the navigator state is available before attempting to navigate.
    if (navigatorKey.currentState != null) {
      return navigatorKey.currentState!.pushNamed(
        routeName,
        arguments: arguments,
      );
    }
    return null;
  }

  /// Pushes a named route and removes all previous routes from the stack.
  ///
  /// Ideal for navigation after an action like logging in or out.
  Future<dynamic>? navigateAndClearStack(String routeName, {Object? arguments}) {
    if (navigatorKey.currentState != null) {
      return navigatorKey.currentState!.pushNamedAndRemoveUntil(
        routeName,
        (route) => false, // This predicate always returns false to remove all routes.
        arguments: arguments,
      );
    }
    return null;
  }

  /// Pushes a named route and replaces the current route in the stack.
  Future<dynamic>? navigateAndReplace(String routeName, {Object? arguments}) {
    if (navigatorKey.currentState != null) {
      return navigatorKey.currentState!.pushReplacementNamed(
        routeName,
        arguments: arguments,
      );
    }
    return null;
  }

  /// Pops the current route off the navigator stack.
  void goBack() {
    if (navigatorKey.currentState != null) {
      return navigatorKey.currentState!.pop();
    }
  }
}