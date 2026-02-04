import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/highlight_provider.dart';
import '../widgets/highlight_bar.dart';

class HighlightSection extends StatefulWidget {
  const HighlightSection({super.key});

  @override
  State<HighlightSection> createState() => _HighlightSectionState();
}

class _HighlightSectionState extends State<HighlightSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HighlightProvider>().loadHighlights();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HighlightBar();
  }
}
