import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:viaamigo/shared/widgets/my_button.dart';
import 'package:viaamigo/src/constantes/text_string.dart';
import 'package:viaamigo/src/utilitaires/theme/themedscaffoldwrapper.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  static const double _defaultSize = 16.0;

  @override
  Widget build(BuildContext context) {
    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Padding(
          padding: const EdgeInsets.all(_defaultSize),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Titre principal
              Text(
                tOtpTitle,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 48.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Sous-titre
              Text(
                tOtpSubTitle.toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Message
              Text(
                "$tOtpMessage support@codingwitht.com",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Champ OTP
              OtpTextField(
                mainAxisAlignment: MainAxisAlignment.center,
                numberOfFields: 6,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface, // 0.1 * 255 = ~26
                showFieldAsBox: true,
                onSubmit: (code) {
                  // Action à effectuer après la saisie du code OTP
                  // print("OTP is => $code");
                },
              ),
              const SizedBox(height: 20),

              // Bouton SUBMIT
              MyButton(
                text: "SUBMIT",
                width: double.infinity,
                height: 50, // 👈 équivalent à vertical: 15
                borderRadius: 30, // 👈 équivalent à BorderRadius.circular(8)
                onTap: () {
                  // Action du bouton
                  // print("Submit button pressed");
                },
              )


            ],
          ),
        ),
      ),
    );
  }
}
