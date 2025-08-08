import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/shared/collections/parcel/controller/parcel_controller.dart';
import 'package:viaamigo/shared/collections/parcel/model/parcel_model.dart';
import 'package:viaamigo/shared/utilis/uimessagemanager.dart';
import 'package:viaamigo/shared/widgets/custom_widget.dart';
import 'package:viaamigo/shared/widgets/my_button.dart';
import 'package:viaamigo/shared/controllers/navigationcontroller.dart';
import 'package:viaamigo/src/fonctionnalites/parcel_steps/screens/parcel_step_mixim.dart';
import 'package:viaamigo/src/utilitaires/theme/app_colors.dart';

class ParcelStepPaymentChoice extends StatefulWidget {
  const ParcelStepPaymentChoice({super.key});

  @override
  ParcelStepPaymentChoiceState createState() => ParcelStepPaymentChoiceState();
}

class ParcelStepPaymentChoiceState extends State<ParcelStepPaymentChoice> {
  final controller = Get.find<ParcelsController>();
  
  // États de sélection
  final RxString selectedPaymentChoice = ''.obs;
  final RxBool isProcessing = false.obs;
  
  // Options de paiement
  final List<PaymentChoiceOption> paymentOptions = [
    PaymentChoiceOption(
      id: 'pay_now',
      title: 'Pay now and publish',
      subtitle: 'Secure payment • Immediate publication',
      description: 'Your parcel will be published immediately after payment confirmation',
      icon: LucideIcons.creditCard,
      iconColor: Colors.green,
      badges: ['Recommended', 'Secure'],
      advantages: [
        'Immediate publication',
        'Higher priority in search results',
        'Faster matching with drivers',
        'No risk of payment issues',
      ],
      estimatedTime: '2-3 minutes',
    ),
    PaymentChoiceOption(
      id: 'pay_later',
      title: 'Publish now, pay when matched',
      subtitle: 'Free publication • Pay when driver is found',
      description: 'Your parcel will be published for free. Payment will be required when a driver accepts your request',
      icon: LucideIcons.clock,
      iconColor: Colors.blue,
      badges: ['Free publication'],
      advantages: [
        'No upfront payment',
        'Cancel anytime before match',
        'Pay only when driver confirmed',
        'Flexibility in negotiations',
      ],
      estimatedTime: 'Instant publication',
      warning: 'Payment will be required within 2 hours when a driver accepts',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final parcel = controller.currentParcel.value;

    if (parcel == null) {
      return const Center(
        child: Text("⛔ Colis non initialisé", style: TextStyle(color: Colors.red)),
      );
    }

    return Scaffold(
      backgroundColor: colors.parcelColor,
      body: Column(
        children: [
          buildHeader(context),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle(context, "Payment options"),
                    const SizedBox(height: 8),
                    Text(
                      "Choose when you want to pay for your parcel delivery",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Résumé des coûts
                    _buildCostSummary(parcel),
                    const SizedBox(height: 32),
                    
                    // Options de paiement
                    ...paymentOptions.map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPaymentOption(option),
                    )),
                    
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary(ParcelModel parcel) {
    final theme = Theme.of(context);
    final totalCost = parcel.initialPrice ?? 0.0;
    final insuranceFee = parcel.insurance_fee ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.calculator, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                "Delivery summary",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildCostLine("Delivery price", "${(totalCost - insuranceFee).toStringAsFixed(2)} CAD"),
          if (insuranceFee > 0)
            _buildCostLine("Insurance", "${insuranceFee.toStringAsFixed(2)} CAD"),
          
          const Divider(thickness: 1),
          _buildCostLine(
            "Total amount", 
            "${totalCost.toStringAsFixed(2)} CAD", 
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCostLine(String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(PaymentChoiceOption option) {
    final theme = Theme.of(context);
    
    return Obx(() {
      final isSelected = selectedPaymentChoice.value == option.id;
      
      return InkWell(
        onTap: () => selectedPaymentChoice.value = option.id,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withAlpha(77),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            color: isSelected 
              ? theme.colorScheme.primary.withAlpha(25)
              : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec icône et titre
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: option.iconColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(option.icon, color: option.iconColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? theme.colorScheme.primary : null,
                                ),
                              ),
                            ),
                            // Radio button
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected 
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                  width: 2,
                                ),
                                color: isSelected ? theme.colorScheme.primary : null,
                              ),
                              child: isSelected 
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Badges
              if (option.badges.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: option.badges.map((badge) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: option.iconColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: option.iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],
              
              // Description
              Text(
                option.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              
              // Animation d'expansion pour les détails
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: isSelected 
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Avantages
                    Text(
                      "Advantages:",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...option.advantages.map((advantage) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.check,
                            size: 16,
                            color: option.iconColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              advantage,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    
                    // Temps estimé
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Processing time: ${option.estimatedTime}",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    // Avertissement si présent
                    if (option.warning != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withAlpha(77)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.alertTriangle,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option.warning!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildActionButtons() {
    return Obx(() {
      final hasSelection = selectedPaymentChoice.value.isNotEmpty;
      final selectedOption = paymentOptions.firstWhereOrNull(
        (option) => option.id == selectedPaymentChoice.value
      );
      
      return Column(
        children: [
          // Bouton principal
          MyButton(
            onTap: hasSelection ? _proceedWithSelectedOption : null,
            text: selectedOption?.id == 'pay_now' 
              ? "Proceed to payment"
              : "Publish parcel",
            height: 56,
            width: double.infinity,
            borderRadius: 30,
            backgroundColor: hasSelection ? null : Colors.grey,
            child: isProcessing.value 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : null,
          ),
          
          const SizedBox(height: 12),
          
          // Bouton retour
          TextButton(
            onPressed: () => Get.find<NavigationController>().goBack(),
            child: const Text("Back to previous step"),
          ),
        ],
      );
    });
  }

  void _proceedWithSelectedOption() async {
    if (selectedPaymentChoice.value.isEmpty) return;
    
    isProcessing.value = true;
    
    try {
      // Sauvegarder le choix de paiement
      await controller.updateField('payment_method', selectedPaymentChoice.value);
      await controller.updateField('payment_status', 
        selectedPaymentChoice.value == 'pay_now' ? 'pending' : 'deferred');
      
      if (selectedPaymentChoice.value == 'pay_now') {
        // Rediriger vers la page de paiement
        _goToPaymentPage();
      } else {
        // Publier directement le colis
        await _publishParcelWithDeferredPayment();
      }
      
    } catch (e) {
      UIMessageManager.error("An error occurred: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }

  void _goToPaymentPage() {
    // TODO: Implémenter la navigation vers la page de paiement
    Get.find<NavigationController>().navigateToNamed('payment-process');
    
    UIMessageManager.info(
      "Redirecting to secure payment...",
      title: "Payment",
    );
  }

  Future<void> _publishParcelWithDeferredPayment() async {
    try {
      // Publier le colis avec statut "en attente de conducteur"
      await controller.publishParcel();
      
      UIMessageManager.success(
        "Your parcel has been published successfully!\nYou will be notified when a driver accepts your request.",
        title: "Parcel published",
      );
            // ✅ Le reset est déjà fait dans publishParcel(), 
      // juste attendre un peu pour la stabilité
      await Future.delayed(const Duration(milliseconds: 400));
      // Rediriger vers le dashboard ou la liste des colis
      Get.find<NavigationController>().navigateToNamed('home');
      
    } catch (e) {
      throw Exception("Failed to publish parcel: ${e.toString()}");
    }
  }
}

// Modèle pour les options de paiement
class PaymentChoiceOption {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color iconColor;
  final List<String> badges;
  final List<String> advantages;
  final String estimatedTime;
  final String? warning;

  PaymentChoiceOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.iconColor,
    this.badges = const [],
    this.advantages = const [],
    required this.estimatedTime,
    this.warning,
  });
}
