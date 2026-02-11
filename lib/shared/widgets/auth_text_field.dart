import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final TextEditingController? matchController;
  final bool enabled;
  final IconData? prefixIcon;
  final String? errorText;

  const AuthTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.matchController,
    this.enabled = true,
    this.prefixIcon,
    this.errorText,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late bool _obscure;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _obscure = widget.obscureText;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.015).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() {});
    if (_focusNode.hasFocus) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;
    final isMatching = widget.matchController != null &&
        hasText &&
        widget.controller.text == widget.matchController!.text;

    final borderColor = isFocused
        ? Colors.white
        : hasText
            ? Colors.white.withOpacity(0.4)
            : Colors.white.withOpacity(0.12);

    final bgColor = isFocused
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.03);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          );
        },
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: isFocused || hasText ? 12 : 14,
              color: isFocused ? Colors.white : Colors.grey[400],
              fontWeight: isFocused ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.5,
            ),
            child: Text(widget.label),
          ),
          const SizedBox(height: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.errorText != null
                    ? Colors.red.withOpacity(0.7)
                    : borderColor,
                width: isFocused ? 1.5 : 1,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: _obscure,
              keyboardType: widget.keyboardType,
              enabled: widget.enabled,
              onChanged: (v) {
                setState(() {});
                widget.onChanged?.call(v);
              },
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
              cursorColor: Colors.white,
              cursorWidth: 1.5,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                border: InputBorder.none,
                prefixIcon: widget.prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 16, right: 12),
                        child: Icon(
                          widget.prefixIcon,
                          color: isFocused ? Colors.white : Colors.grey[500],
                          size: 20,
                        ),
                      )
                    : null,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                suffixIcon: _buildSuffixIcon(isMatching),
              ),
            ),
          ),
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                widget.errorText!,
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget? _buildSuffixIcon(bool isMatching) {
    if (!widget.obscureText && !isMatching) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.matchController != null && isMatching)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.greenAccent,
                    size: 16,
                  ),
                ),
              );
            },
          ),
        if (widget.obscureText)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  key: ValueKey(_obscure),
                  color: Colors.grey[400],
                  size: 22,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
