import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorPickerField extends StatefulWidget {
  final String label;
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerField({
    super.key,
    required this.label,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends State<ColorPickerField> {
  late Color _selectedColor;
  late TextEditingController _hexController;

  // Palette de couleurs prédéfinies
  static const List<Color> _presetColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFF3B82F6), // Light Blue
    Color(0xFF0EA5E9), // Sky
    Color(0xFF06B6D4), // Cyan
    Color(0xFF14B8A6), // Teal
    Color(0xFF10B981), // Emerald
    Color(0xFF22C55E), // Green
    Color(0xFF84CC16), // Lime
    Color(0xFFEAB308), // Yellow
    Color(0xFFF59E0B), // Amber
    Color(0xFFF97316), // Orange
    Color(0xFFEF4444), // Red
    Color(0xFFEC4899), // Pink
    Color(0xFFD946EF), // Fuchsia
    Color(0xFFA855F7), // Purple
    Color(0xFF8B5CF6), // Violet
    Color(0xFF6366F1), // Indigo
    Color(0xFF000000), // Black
    Color(0xFF374151), // Gray
    Color(0xFF6B7280), // Gray Light
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _hexController = TextEditingController(
      text: _colorToHex(_selectedColor),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
 final argb = color.toARGB32();
  return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';  }

  Color? _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return null;
  }

  void _updateColor(Color color) {
    setState(() {
      _selectedColor = color;
      _hexController.text = _colorToHex(color);
    });
    widget.onColorChanged(color);
  }

  void _onHexChanged(String value) {
    final color = _hexToColor(value);
    if (color != null) {
      setState(() => _selectedColor = color);
      widget.onColorChanged(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // Aperçu de la couleur + input hex
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              // Aperçu grande
              Row(
                children: [
                  // Cercle de couleur sélectionnée
                  GestureDetector(
                    onTap: _showFullColorPicker,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.onSurface.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _selectedColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.colorize_rounded,
                        color: _selectedColor.computeLuminance() > 0.5
                            ? Colors.black54
                            : Colors.white54,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Input Hex
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '#',
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.4),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: _hexController,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9A-Fa-f#]'),
                                ),
                                LengthLimitingTextInputFormatter(7),
                              ],
                              onChanged: _onHexChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Palette de couleurs prédéfinies
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetColors.map((color) {
                final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _updateColor(color);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? colors.onSurface
                              : colors.onSurface.withValues(alpha: 0.1),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFullColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AdvancedColorPicker(
        currentColor: _selectedColor,
        onColorSelected: (color) {
          _updateColor(color);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─────────────── ADVANCED COLOR PICKER ───────────────

class _AdvancedColorPicker extends StatefulWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  const _AdvancedColorPicker({
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  State<_AdvancedColorPicker> createState() => _AdvancedColorPickerState();
}

class _AdvancedColorPickerState extends State<_AdvancedColorPicker> {
  late double _hue;
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.currentColor);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
  }

  Color get _currentColor =>
      HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Titre
          Text(
            'Choisir une couleur',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // Aperçu
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _currentColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _currentColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Slider Teinte
          _buildSlider(
            label: 'Teinte',
            value: _hue,
            max: 360,
            gradient: LinearGradient(
              colors: List.generate(
                7,
                (i) => HSLColor.fromAHSL(1.0, i * 60.0, 1.0, 0.5).toColor(),
              ),
            ),
            onChanged: (v) => setState(() => _hue = v),
          ),
          const SizedBox(height: 16),

          // Slider Saturation
          _buildSlider(
            label: 'Saturation',
            value: _saturation,
            max: 1,
            gradient: LinearGradient(
              colors: [
                HSLColor.fromAHSL(1.0, _hue, 0.0, _lightness).toColor(),
                HSLColor.fromAHSL(1.0, _hue, 1.0, _lightness).toColor(),
              ],
            ),
            onChanged: (v) => setState(() => _saturation = v),
          ),
          const SizedBox(height: 16),

          // Slider Luminosité
          _buildSlider(
            label: 'Luminosité',
            value: _lightness,
            max: 1,
            gradient: LinearGradient(
              colors: [
                HSLColor.fromAHSL(1.0, _hue, _saturation, 0.0).toColor(),
                HSLColor.fromAHSL(1.0, _hue, _saturation, 0.5).toColor(),
                HSLColor.fromAHSL(1.0, _hue, _saturation, 1.0).toColor(),
              ],
            ),
            onChanged: (v) => setState(() => _lightness = v),
          ),
          const SizedBox(height: 24),

          // Bouton valider
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onColorSelected(_currentColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentColor,
                foregroundColor: _currentColor.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Sélectionner cette couleur',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double max,
    required Gradient gradient,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 32,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 32,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 4,
              ),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
