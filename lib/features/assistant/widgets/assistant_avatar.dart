import 'package:flutter/material.dart';

class AssistantAvatar extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  final String heroTag;

  const AssistantAvatar({
    super.key,
    required this.onTap,
    this.size = 58,
    this.heroTag = 'transia_ai_avatar',
  });

  @override
  State<AssistantAvatar> createState() => _AssistantAvatarState();
}

class _AssistantAvatarState extends State<AssistantAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _shadowAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.06,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _shadowAnimation = Tween<double>(
      begin: 0.18,
      end: 0.34,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(
      reverse: true,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.heroTag,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? 0.92 : _scaleAnimation.value,
              child: GestureDetector(
                onTapDown: _handleTapDown,
                onTapCancel: _handleTapCancel,
                onTapUp: _handleTapUp,
                child: Semantics(
                  button: true,
                  label: 'Ouvrir TransIA',
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4F72FF),
                          Color(0xFF3158F5),
                          Color(0xFF2445D8),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: 0.28,
                        ),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3158F5).withValues(
                            alpha: _shadowAnimation.value,
                          ),
                          blurRadius: 22,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 7,
                          left: 11,
                          child: Container(
                            width: widget.size * 0.28,
                            height: widget.size * 0.12,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: 0.22,
                              ),
                              borderRadius: BorderRadius.circular(
                                widget.size,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.smart_toy_rounded,
                          size: widget.size * 0.5,
                          color: Colors.white,
                        ),
                        Positioned(
                          right: 5,
                          bottom: 5,
                          child: Container(
                            width: widget.size * 0.18,
                            height: widget.size * 0.18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: 0.14,
                                  ),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}