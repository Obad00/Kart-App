import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final TextEditingController? matchController; 
  final bool enabled; 

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.matchController,
    this.enabled = true,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late FocusNode _focusNode;
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _obscure = widget.obscureText; // Initialiser l'état de l’œil
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMatching = widget.matchController != null &&
        widget.controller.text.isNotEmpty &&
        widget.controller.text == widget.matchController!.text;

    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: _focusNode.hasFocus || widget.controller.text.isNotEmpty
                  ? 12
                  : 14,
              color: _focusNode.hasFocus ? Colors.white : Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
            child: Text(widget.label),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscure,
            keyboardType: widget.keyboardType,
            enabled: widget.enabled,
            onChanged: (v) {
              setState(() {}); // Pour rafraîchir l’œil et le check
              if (widget.onChanged != null) widget.onChanged!(v);
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              suffixIcon: widget.obscureText
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Check vert si matchController fourni et correspond
                        if (widget.matchController != null && isMatching)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child:
                                Icon(Icons.check_circle, color: Color.fromARGB(255, 255, 255, 255)),
                          ),
                        IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[400],
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
