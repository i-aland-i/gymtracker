import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Page transition: fade on web, slide+fade on mobile.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required WidgetBuilder builder, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = animation.drive(
              Tween<double>(begin: 0.0, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeOut)),
            );
            if (kIsWeb) {
              return FadeTransition(opacity: fade, child: child);
            }
            final slide = animation.drive(
              Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
            );
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
          transitionDuration: Duration(milliseconds: kIsWeb ? 200 : 300),
          reverseTransitionDuration:
              Duration(milliseconds: kIsWeb ? 160 : 240),
        );
}

/// Smooth cross-fade for tab switches on all platforms.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.index;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _index = widget.index;
      // Set to 0 synchronously so the new content is already hidden when
      // the frame paints, then fade in after the frame completes.
      _ctrl.value = 0.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: IndexedStack(index: _index, children: widget.children),
    );
  }
}
