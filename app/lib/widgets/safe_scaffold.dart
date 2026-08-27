import 'package:flutter/material.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/quick_calculator/quick_calculator_screen.dart';
import 'banner_ad_widget.dart';

/// Safe Scaffold wrapper with PopScope for web back button handling
/// and proper SafeArea padding for Android 3-button navigation.
///
/// Features:
/// - Handles web browser back button properly
/// - Optional back navigation to parent screen
/// - Consistent AppBar with optional actions
/// - SafeArea padding prevents content from being hidden by nav buttons
/// - Optional bottom banner ad slot
class SafeScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;
  final bool canPop;
  final VoidCallback? onPopInvoked;
  final Color? backgroundColor;
  final bool showBannerAd;

  const SafeScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
    this.canPop = true,
    this.onPopInvoked,
    this.backgroundColor,
    this.showBannerAd = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && onPopInvoked != null) {
          onPopInvoked!();
        }
        // Handle web back button
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: title != null
            ? AppBar(
                title: Text(title!),
                centerTitle: true,
                actions: actions,
              )
            : null,
        body: SafeArea(
          top: false, // AppBar handles top padding
          bottom: true, // Ensures space for Android 3-button nav
          child: Column(
            children: [
              Expanded(child: body),
              if (showBannerAd) const AppBannerAd(),
            ],
          ),
        ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

/// Navigation helper for consistent screen transitions
class AppNavigation {
  /// Push a new screen
  static void push(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Push and replace current screen
  static void pushReplacement(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Push and remove all previous screens (go to home)
  static void pushAndRemoveAll(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  /// Pop to dashboard (or push if not in stack)
  static void popToDashboard(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
    // If dashboard is not first route, push it
    if (ModalRoute.of(context)?.settings.name != '/') {
      pushReplacement(context, const DashboardScreen());
    }
  }

  /// Go back or to dashboard if can't pop
  static void popOrDashboard(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      pushAndRemoveAll(context, const QuickCalculatorScreen());
    }
  }
}
