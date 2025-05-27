import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viaamigo/shared/widgets/custom_text_field.dart';
import 'package:viaamigo/shared/widgets/my_button.dart';
import 'package:viaamigo/src/constantes/text_string.dart';
import 'package:viaamigo/src/fonctionnalites/auth/screens/otp_screen.dart';
import 'package:viaamigo/src/utilitaires/theme/themedscaffoldwrapper.dart';

class ForgetPasswordMailScreen extends StatelessWidget {
  ForgetPasswordMailScreen({super.key});

  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: colorScheme.surface, // ✅ respect du thème clair/sombre
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
                          // 🔙 Retour
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            onPressed: () => Get.back(),
                          ),
              SizedBox(height: size.height * 0.05),
              // 🖼 Illustration
              Image.asset(
                'assets/images/imagemdpoublie.png',
                height: size.height * 0.3,
                fit: BoxFit.contain,
              ),
      
              const SizedBox(height: 30),
      
              // 🧠 Titre
              Text(
                tForgetPassword,
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
      
              const SizedBox(height: 10),
      
              // 📄 Sous-titre
              Text(
                tForgetPasswordSubTitle,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                textAlign: TextAlign.center,
              ),
      
              const SizedBox(height: 25),
      
              // ✉️ Champ email
              Form(
                key: _formKey,
                child: CustomTextField(
                  controller: _emailController,
                  hintText: "Enter your email",
                  isTransparent: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                  
                ),
              ),
              const SizedBox(height: 30),
              MyButton(
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    Get.to(() => const OTPScreen()); // 🚧 À remplacer par succès réel
                  }
                },
                text: "SUBMIT",
                height: 50,
                width: double.infinity,
                borderRadius: 35,
              ),


            ],
          ),
        ),
      ),
    );
  }
}
