import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../providers/payment_provider.dart';
import '../../auth/providers/auth_provider.dart';

class PaymentResultScreen extends StatelessWidget {
  final Payment payment;

  const PaymentResultScreen({
    super.key,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildStatusIcon(),
              const SizedBox(height: 32),
              _buildStatusTitle(),
              const SizedBox(height: 12),
              _buildStatusMessage(),
              const SizedBox(height: 32),
              _buildPaymentDetails(),
              const Spacer(),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    final isSuccess = payment.isSuccessful;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSuccess
              ? [Colors.green.withValues(alpha: 0.3), Colors.green.withValues(alpha: 0.1)]
              : [Colors.red.withValues(alpha: 0.3), Colors.red.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSuccess
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Icon(
        isSuccess ? Icons.check_rounded : Icons.close_rounded,
        color: isSuccess ? Colors.green : Colors.red,
        size: 48,
      ),
    );
  }

  Widget _buildStatusTitle() {
    return Text(
      payment.isSuccessful ? 'Paiement réussi !' : 'Paiement échoué',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Text(
      payment.isSuccessful
          ? 'Votre abonnement est maintenant actif.\nProfitez de toutes les fonctionnalités PRO !'
          : 'Votre paiement n\'a pas abouti.\nVeuillez réessayer ou utiliser une autre méthode.',
      style: TextStyle(
        color: Colors.grey[400],
        fontSize: 15,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow('Référence', payment.reference),
          const SizedBox(height: 12),
          _buildDetailRow('Montant', payment.formattedAmount),
          if (payment.plan != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow('Plan', payment.plan!.name),
          ],
          if (payment.paidAt != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              'Date',
              _formatDate(payment.paidAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (payment.isSuccessful) {
                // Reload user profile to get updated plan
                context.read<AuthProvider>().loadMe();
                context.read<PaymentProvider>().reset();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              } else {
                // Go back to payment method selection
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              payment.isSuccessful ? 'Continuer' : 'Réessayer',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        if (!payment.isSuccessful) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              context.read<PaymentProvider>().reset();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
            child: Text(
              'Retour à l\'accueil',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
