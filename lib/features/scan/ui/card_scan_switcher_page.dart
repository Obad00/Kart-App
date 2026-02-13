import 'package:flutter/material.dart';
import '../../digital_card/ui/my_digital_card_page.dart';
import 'scan_page.dart';

class CardScanSwitcherPage extends StatefulWidget {
  const CardScanSwitcherPage({super.key});

  @override
  State<CardScanSwitcherPage> createState() =>
      _CardScanSwitcherPageState();
}

class _CardScanSwitcherPageState
    extends State<CardScanSwitcherPage> {
  int _index = 0; // 0 = Scan, 1 = Carte

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🔥 Contenu principal
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _index == 0
                ? const ScanPage()
                : const MyDigitalCardPage(),
          ),

          // 🔙 Bouton retour en haut à gauche
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),

          // 🔥 Switcher en bas (Wave style)
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  _buildTab("Scanner une KART", 0),
                  _buildTab("Ma KART", 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final selected = _index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _index = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.black
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
