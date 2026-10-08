import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/kart_tokens.dart';
import '../utils/color_contrast.dart';

class ColorPickerField extends StatefulWidget {
  final String label;
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  /// Couleurs extraites du logo (5 au plus, de la plus présente à la moins
  /// présente). Vide : la ligne « Couleurs de votre logo » n'existe pas et
  /// le champ est exactement celui d'avant.
  final List<Color> logoColors;

  /// Couleur du logo la plus lisible sur la carte : porte le badge
  /// « Suggérée ». Si ce n'est pas une des [logoColors] (aucune n'est
  /// lisible, c'est alors une version éclaircie), elle est ajoutée comme
  /// pastille supplémentaire. Jamais présélectionnée.
  final Color? suggestedColor;

  /// Petit message au-dessus des couleurs du logo (ex. « Logo enregistré »).
  final String? logoNotice;

  /// Affiche « Peu lisible sur votre carte publique » + « Ajuster » quand
  /// la couleur choisie manque de contraste. Désactivé par défaut : les
  /// autres usages du champ (couleur d'entreprise) ne changent pas.
  final bool warnWhenUnreadable;

  /// true si [initialColor] est la couleur par défaut de KART (carte sans
  /// couleur choisie) : jamais d'avertissement tant qu'elle n'a pas été
  /// changée.
  final bool initialIsDefault;

  const ColorPickerField({
    super.key,
    required this.label,
    required this.initialColor,
    required this.onColorChanged,
    this.logoColors = const [],
    this.suggestedColor,
    this.logoNotice,
    this.warnWhenUnreadable = false,
    this.initialIsDefault = false,
  });

  @override
  State<ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends State<ColorPickerField> {
  late Color _selectedColor;
  late TextEditingController _hexController;

  /// L'utilisateur a-t-il changé la couleur depuis l'ouverture ?
  bool _touched = false;

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
      _touched = true;
      _hexController.text = _colorToHex(color);
    });
    widget.onColorChanged(color);
  }

  void _onHexChanged(String value) {
    final color = _hexToColor(value);
    if (color != null) {
      setState(() {
        _selectedColor = color;
        _touched = true;
      });
      widget.onColorChanged(color);
    }
  }

  /// Couleurs du logo à afficher : celles du logo, plus la suggérée si elle
  /// n'en fait pas partie. 6 pastilles au plus.
  List<Color> get _logoSwatches {
    final swatches = widget.logoColors.take(5).toList();
    final suggested = widget.suggestedColor;
    if (suggested != null &&
        !swatches.any((c) => c.toARGB32() == suggested.toARGB32())) {
      swatches.add(suggested);
    }
    return swatches;
  }

  bool get _showContrastWarning =>
      widget.warnWhenUnreadable &&
      !(widget.initialIsDefault && !_touched) &&
      !ColorContrast.isReadableOnCard(_selectedColor);

  /// Pastille de couleur : la même pour la palette et pour les couleurs du
  /// logo (taille, bordure, coche et halo quand elle est sélectionnée).
  Widget _buildSwatch(Color color, ColorScheme colors, {Key? key}) {
    final isSelected = _selectedColor.toARGB32() == color.toARGB32();
    return GestureDetector(
      key: key,
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
  }

  /// « Couleurs de votre logo » : libellé, pastilles, badge « Suggérée »
  /// sous la plus lisible. Rien n'est présélectionné.
  Widget _buildLogoColors(ColorScheme colors) {
    final suggested = widget.suggestedColor;
    final muted = colors.onSurface.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.logoNotice != null) ...[
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 14,
                color: KartTokens.of(context).positive,
              ),
              const SizedBox(width: 6),
              Text(
                widget.logoNotice!,
                style: TextStyle(
                  color: KartTokens.of(context).positive,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Text(
          'Couleurs de votre logo',
          style: TextStyle(
            color: muted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _logoSwatches.map((color) {
            final isSuggested = suggested != null &&
                color.toARGB32() == suggested.toARGB32();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSwatch(
                  color,
                  colors,
                  key: ValueKey('logo-color-${_colorToHex(color)}'),
                ),
                // Hauteur réservée même sans badge : les pastilles restent
                // alignées.
                SizedBox(
                  height: 16,
                  child: isSuggested
                      ? Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            'Suggérée',
                            style: TextStyle(
                              color: muted,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Ligne discrète sous la palette. N'empêche jamais d'enregistrer.
  Widget _buildContrastWarning() {
    final attention = KartTokens.of(context).attention;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: attention),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Peu lisible sur votre carte publique',
              style: TextStyle(color: attention, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _updateColor(ColorContrast.adjustForCard(_selectedColor));
            },
            style: TextButton.styleFrom(
              foregroundColor: attention,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Ajuster',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
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

              // Couleurs du logo, seulement s'il y en a.
              if (_logoSwatches.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: _buildLogoColors(colors),
                ),

              // Palette de couleurs prédéfinies
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetColors
                    .map((color) => _buildSwatch(color, colors))
                    .toList(),
              ),

              if (_showContrastWarning) _buildContrastWarning(),
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

/// Ouvre le sélecteur de couleur libre (le même que celui de « Couleur et
/// logo ») et renvoie la couleur choisie, ou null si la feuille est fermée.
Future<Color?> showKartColorPicker(BuildContext context, Color initial) {
  return showModalBottomSheet<Color>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _AdvancedColorPicker(
      currentColor: initial,
      onColorSelected: (color) => Navigator.pop(sheetContext, color),
    ),
  );
}

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
