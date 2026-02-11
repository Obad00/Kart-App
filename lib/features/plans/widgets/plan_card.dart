import 'package:flutter/material.dart';

class PlanCard extends StatefulWidget {
  final String title;
  final String price;
  final String description;
  final List<String> features;
  final bool highlight;
  final bool isPopular;
  final VoidCallback? onTap;
  final Color? accentColor;
  final Color? secondaryColor;

  const PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.description,
    this.features = const [],
    this.highlight = false,
    this.isPopular = false,
    this.onTap,
    this.accentColor,
    this.secondaryColor,
  });

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor => widget.accentColor ?? Colors.white;
  Color get _secondaryColor => widget.secondaryColor ?? _accentColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: widget.highlight
                ? LinearGradient(
                    colors: [
                      _accentColor.withOpacity(0.18),
                      _secondaryColor.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.highlight ? null : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.highlight
                  ? _accentColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
              width: widget.highlight ? 2 : 1,
            ),
            boxShadow: widget.highlight
                ? [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Popular badge
                if (widget.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _accentColor,
                          _accentColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.black,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'POPULAIRE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

              if (widget.isPopular) const SizedBox(height: 16),

              // Title
              Text(
                widget.title,
                style: TextStyle(
                  color: widget.highlight ? _accentColor : Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.price,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                widget.description,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              // Features list (limité à 4 pour éviter overflow)
              if (widget.features.isNotEmpty) ...[
                const SizedBox(height: 20),
                Divider(
                  color: Colors.white.withOpacity(0.1),
                  height: 1,
                ),
                const SizedBox(height: 12),
                ...widget.features.take(3).map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: _accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],

              // Afficher +N si plus de features
              if (widget.features.length > 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '+ ${widget.features.length - 3} autres avantages',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              // Selection indicator
              if (widget.highlight) ...[
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _accentColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: _accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sélectionné',
                          style: TextStyle(
                            color: _accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
}
