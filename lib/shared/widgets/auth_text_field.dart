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
  // >1 pour un champ multi-lignes (ex: bio) — le champ garde alors sa
  // hauteur au premier rendu plutôt que de grandir avec le texte, minLines
  // reste à 1 par défaut pour ne rien changer aux champs existants.
  final int maxLines;
  final int minLines;

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
    this.maxLines = 1,
    this.minLines = 1,
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
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isFocused = _focusNode.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;
    final isMatching = widget.matchController != null &&
        hasText &&
        widget.controller.text == widget.matchController!.text;

    // Couleurs adaptatives selon le theme
    final primaryColor = colors.primary;
    final textColor = colors.onSurface;
    final hintColor = colors.onSurface.withValues(alpha: 0.5);

    final borderColor = isFocused
        ? primaryColor
        : hasText
            ? colors.onSurface.withValues(alpha: 0.3)
            : colors.onSurface.withValues(alpha: 0.12);

    final bgColor = isFocused
        ? primaryColor.withValues(alpha: isDark ? 0.08 : 0.05)
        : colors.onSurface.withValues(alpha: isDark ? 0.05 : 0.03);

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
                color: isFocused ? primaryColor : hintColor,
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
                      ? Colors.red.withValues(alpha: 0.7)
                      : borderColor,
                  width: isFocused ? 1.5 : 1,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.1),
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
                maxLines: widget.obscureText ? 1 : widget.maxLines,
                minLines: widget.obscureText ? 1 : widget.minLines,
                textCapitalization: widget.maxLines > 1
                    ? TextCapitalization.sentences
                    : TextCapitalization.none,
                onChanged: (v) {
                  setState(() {});
                  widget.onChanged?.call(v);
                },
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                cursorColor: primaryColor,
                cursorWidth: 1.5,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    color: hintColor,
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
                            color: isFocused ? primaryColor : hintColor,
                            size: 20,
                          ),
                        )
                      : null,
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  suffixIcon: _buildSuffixIcon(isMatching, colors, isDark),
                ),
              ),
            ),
            if (widget.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  widget.errorText!,
                  style: TextStyle(
                    color: Colors.red[isDark ? 300 : 600],
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

  Widget? _buildSuffixIcon(bool isMatching, ColorScheme colors, bool isDark) {
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
                    color: Colors.green.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: isDark ? Colors.greenAccent : Colors.green,
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
                  color: colors.onSurface.withValues(alpha: 0.5),
                  size: 22,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
