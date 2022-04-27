import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/tap_bounce_container.dart';

OverlayEntry? _previousEntry;

/// Displays a widget that will be passed to [child] parameter above the current
/// contents of the app, with transition animation
///
/// The [child] argument is used to pass widget that you want to show
///
/// The [showOutAnimationDuration] argument is used to specify duration of
/// enter transition
///
/// The [hideOutAnimationDuration] argument is used to specify duration of
/// exit transition
///
/// The [displayDuration] argument is used to specify duration displaying
///
/// The [additionalStartPadding] argument is used to specify amount of top
/// padding that will be added for SafeArea values
///
/// The [onTap] callback of [CustomPositionSnackBar]
///
/// The [overlayState] argument is used to add specific overlay state.
/// If you will not pass it, it will try to get the current overlay state from
/// passed [BuildContext]
void showCustomPositionSnackBar(
  BuildContext context,
  Widget child, {
  bool isTop = true,
  Duration showOutAnimationDuration = const Duration(milliseconds: 1200),
  Duration hideOutAnimationDuration = const Duration(milliseconds: 550),
  Duration displayDuration = const Duration(milliseconds: 3000),
  double additionalStartPadding = 16,
  VoidCallback? onTap,
  OverlayState? overlayState,
  double leftPadding = 16,
  double rightPadding = 16,
}) async {
  overlayState ??= Overlay.of(context);
  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) {
      return CustomPositionSnackBar(
        child: child,
        isTop: isTop,
        onDismissed: () {
          overlayEntry.remove();
          _previousEntry = null;
        },
        showOutAnimationDuration: showOutAnimationDuration,
        hideOutAnimationDuration: hideOutAnimationDuration,
        displayDuration: displayDuration,
        additionalStartPadding: additionalStartPadding,
        onTap: onTap,
        leftPadding: leftPadding,
        rightPadding: rightPadding,
      );
    },
  );

  _previousEntry?.remove();
  overlayState?.insert(overlayEntry);
  _previousEntry = overlayEntry;
}

/// Widget that controls all animations
class CustomPositionSnackBar extends StatefulWidget {
  final Widget child;
  final bool isTop;
  final VoidCallback onDismissed;
  final showOutAnimationDuration;
  final hideOutAnimationDuration;
  final displayDuration;
  final additionalStartPadding;
  final VoidCallback? onTap;
  final double leftPadding;
  final double rightPadding;

  CustomPositionSnackBar({
    Key? key,
    required this.child,
    required this.isTop,
    required this.onDismissed,
    required this.showOutAnimationDuration,
    required this.hideOutAnimationDuration,
    required this.displayDuration,
    required this.additionalStartPadding,
    this.onTap,
    this.leftPadding = 16,
    this.rightPadding = 16,
  }) : super(key: key);

  @override
  _CustomPositionSnackBarState createState() => _CustomPositionSnackBarState();
}

class _CustomPositionSnackBarState extends State<CustomPositionSnackBar> with SingleTickerProviderStateMixin {
  late Animation offsetAnimation;
  late AnimationController animationController;
  double? startPosition;

  @override
  void initState() {
    startPosition = widget.additionalStartPadding;
    _setupAndStartAnimation();
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void _setupAndStartAnimation() async {
    animationController = AnimationController(
      vsync: this,
      duration: widget.showOutAnimationDuration,
      reverseDuration: widget.hideOutAnimationDuration,
    );

    Tween<Offset> offsetTween = Tween<Offset>(
      begin: Offset(0.0, widget.isTop ? -1.0 : 1.0),
      end: Offset(0.0, 0.0),
    );

    offsetAnimation = offsetTween.animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.elasticOut,
        reverseCurve: Curves.linearToEaseOut,
      ),
    )..addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          await Future.delayed(widget.displayDuration);
          if (mounted) {
            animationController.reverse();
            setState(() {
              startPosition = 0;
            });
          }
        }

        if (status == AnimationStatus.dismissed) {
          widget.onDismissed.call();
        }
      });

    if (mounted) {
      animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: widget.hideOutAnimationDuration * 1.5,
      curve: Curves.linearToEaseOut,
      top: widget.isTop ? startPosition : null,
      bottom: widget.isTop ? null : startPosition,
      left: widget.leftPadding,
      right: widget.rightPadding,
      child: SlideTransition(
        position: offsetAnimation as Animation<Offset>,
        child: SafeArea(
          child: TapBounceContainer(
            onTap: () {
              if (mounted) {
                widget.onTap?.call();
                animationController.reverse();
              }
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
