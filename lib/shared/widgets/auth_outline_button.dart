import 'package:flutter/material.dart';

class AuthOutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expanded;
  final bool loading;

  const AuthOutlineButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.expanded = true,
    this.loading = false,
  });

  @override
  State<AuthOutlineButton> createState() => _AuthOutlineButtonState();
}

class _AuthOutlineButtonState extends State<AuthOutlineButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && !widget.loading) {
      setState(() => _isHovered = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isHovered = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isHovered = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onTap != null && !widget.loading;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: isEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.expanded ? double.infinity : null,
          constraints: BoxConstraints(
            minWidth: widget.expanded ? double.infinity : 200,
          ),
          height: 58,
          padding: EdgeInsets.symmetric(
            horizontal: widget.expanded ? 24 : 32,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled
                  ? Colors.white.withOpacity(_isHovered ? 0.5 : 0.25)
                  : Colors.grey[700]!,
              width: 1.5,
            ),
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: isEnabled ? Colors.white70 : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isEnabled ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
