import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/payment_provider.dart';
import '../models/payment.dart';

class PaymentProcessingScreen extends StatefulWidget {
  const PaymentProcessingScreen({super.key});

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  late WebViewController _webViewController;
  bool _isWebViewLoading = true;
  bool _useExternalBrowser = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _startPaymentPolling();
  }

  void _initWebView() {
    final provider = context.read<PaymentProvider>();
    final url = provider.paymentUrl;

    if (url == null) return;

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isWebViewLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isWebViewLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle callback URLs or specific schemes
            if (request.url.contains('callback') ||
                request.url.contains('success') ||
                request.url.contains('failed')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _startPaymentPolling() {
    final provider = context.read<PaymentProvider>();
    provider.startPollingPaymentStatus((payment) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/payment/result',
        arguments: payment,
      );
    });
  }

  Future<void> _openExternalBrowser() async {
    final provider = context.read<PaymentProvider>();
    final url = provider.paymentUrl;

    if (url == null) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _useExternalBrowser = true);
    }
  }

  @override
  void dispose() {
    context.read<PaymentProvider>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => _showCancelDialog(),
        ),
        title: const Text(
          'Paiement en cours',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white),
            onPressed: _openExternalBrowser,
          ),
        ],
      ),
      body: _useExternalBrowser
          ? _buildWaitingScreen(provider)
          : _buildWebView(provider),
    );
  }

  Widget _buildWebView(PaymentProvider provider) {
    if (provider.paymentUrl == null) {
      return const Center(
        child: Text(
          'URL de paiement non disponible',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isWebViewLoading)
          Container(
            color: const Color(0xFF0A0A0A),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildWaitingScreen(PaymentProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Paiement en attente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complétez votre paiement dans le navigateur.\nNous vérifierons automatiquement le statut.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (provider.currentPayment != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Statut: ${_getStatusLabel(provider.currentPayment!.status)}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 48),
            TextButton(
              onPressed: _openExternalBrowser,
              child: const Text(
                'Rouvrir la page de paiement',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.successful:
        return 'Réussi';
      case PaymentStatus.failed:
        return 'Échoué';
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Annuler le paiement ?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Votre paiement est peut-être en cours de traitement. Êtes-vous sûr de vouloir quitter ?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non, continuer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, quitter'),
          ),
        ],
      ),
    );
  }
}
