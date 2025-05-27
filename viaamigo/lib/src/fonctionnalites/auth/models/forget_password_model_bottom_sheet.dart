import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:viaamigo/src/constantes/text_string.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/forget_password_mail.dart';
import 'package:viaamigo/src/fonctionnalites/auth/widgets/forget_password_btn_widget.dart';

class ForgetPasswordModelBottomSheetScreen {
  static Future<dynamic> buildShowModalBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,//Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (builder) => Container(
        height: MediaQuery.of(context).size.height * 0.5, // 📏 40% de l’écran
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧠 Titre
            Text(
              tForgetPasswordTitle,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),

            // 📄 Sous-titre
            Text(
              tForgetPasswordSubTitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 30),

            // 📧 Bouton reset par email
            ForgetPasswordBtnWidget(
              onTap: () {
                Navigator.pop(context);
                Get.to(() => ForgetPasswordMailScreen());
              },
              btnIcon: LucideIcons.mail,
              title: tEmail,
              subtitle: tResetViaEMail,
            ),
            const SizedBox(height: 20),

            // 📱 Bouton reset par téléphone (à venir)
            ForgetPasswordBtnWidget(
              onTap: () {
                Navigator.pop(context);
                // TODO: Implémenter OTP via téléphone
              },
              btnIcon: LucideIcons.phone,
              title: tPhone,
              subtitle: tResetPhone,
            ),
          ],
        ),
      ),
    );
  }
}
