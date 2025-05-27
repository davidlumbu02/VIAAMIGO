import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:viaamigo/shared/widgets/build_button_text_logo.dart';
import 'package:viaamigo/shared/widgets/custom_text_field.dart';
import 'package:viaamigo/shared/widgets/my_button.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool usePhone = false;

  @override
  void initState() {
    super.initState();
    // Permet d'utiliser toute la zone d'affichage (y compris autour de la barre système)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500), // ✅ pour s'adapter aux tablettes
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          /// 🔷 Logo + Nom
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                theme.brightness == Brightness.dark
                                    ? 'assets/logo/LOGOBLANC.png'
                                    : 'assets/logo/LOGONOIR.png',
                                width: 40,
                                height: 40,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'ViaAmigo',
                                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          /// 👤 Nom complet
                          CustomTextField(
                            controller: nameController,
                            hintText: 'Full Name',
                            isTransparent: true,
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          /// 📩 Adresse courriel ou téléphone
                          CustomTextField(
                            controller: emailController,
                            hintText: usePhone ? 'Phone number' : 'Email address',
                            keyboardType: usePhone ? TextInputType.phone : TextInputType.emailAddress,
                            isTransparent: true,
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          ),
      
                          const SizedBox(height: 20),
      
                          /// 🔒 Mot de passe
                          CustomTextField(
                            controller: passwordController,
                            hintText: 'Password',
                            obscureText: true,
                            isTransparent: true,
                            validator: (value) => value == null || value.length < 6
                                ? 'Minimum 6 characters'
                                : null,
                          ),
      
                          const SizedBox(height: 20),
      
                          /// 🔁 Confirmation du mot de passe
                          CustomTextField(
                            controller: confirmPasswordController,
                            hintText: 'Confirm Password',
                            obscureText: true,
                            isTransparent: true,
                            validator: (value) => value != passwordController.text
                                ? 'Passwords do not match'
                                : null,
                          ),
      
                          const SizedBox(height: 30),
      
                          /// ✅ Créer le compte
                          MyButton(
                            text: isLoading ? 'Creating Account...' : 'Sign Up',
                            width: double.infinity,
                            height: 45,
                            borderRadius: 8,
                            isLoading: isLoading,
                            onTap: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => isLoading = true);
                                await Future.delayed(const Duration(seconds: 2));
                                setState(() => isLoading = false);
                              }
                            },
                          ),
      
                          const SizedBox(height: 20),
      
                          /// 🔙 Déjà un compte ? Connexion
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Already have an account?", style: textTheme.bodyMedium),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                                child: Text('Login', style: TextStyle(color: theme.colorScheme.primary)),
                              ),
                            ],
                          ),
      
                          /// ➖ OU ➖
                          Row(
                            children: [
                              Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text('OR', style: textTheme.bodySmall),
                              ),
                              Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                            ],
                          ),
      
                          const SizedBox(height: 44),
      /*
                          /// 🌐 Boutons sociaux
                          buildButtonTextLogo(
                            context,
                            borderRadius: 8,
                            height: 50,
                            alignIconStart: true,
                            label: 'Continue with Google',
                            iconAsset: 'assets/logo/google.png',
                            outlined: true,
                            onTap: () {},
                          ),
                          const SizedBox(height: 10),
                          buildButtonTextLogo(
                            context,
                            borderRadius: 8,
                            height: 50,
                            alignIconStart: true,
                            label: 'Continue with Facebook',
                            iconAsset: 'assets/logo/fb.png',
                            outlined: true,
                            onTap: () {},
                          ),
                          const SizedBox(height: 10),
                          buildButtonTextLogo(
                            context,
                            borderRadius: 8,
                            height: 50,
                            alignIconStart: true,
                            label: 'Continue with Apple',
                            iconAsset: theme.brightness == Brightness.dark
                                ? 'assets/logo/whiteapple.png'
                                : 'assets/logo/apple.png',
                            outlined: true,
                            onTap: () {},
                          ),
                          const SizedBox(height: 10),*/
      
                          /// 🔄 Basculer entre téléphone et courriel
                          buildButtonTextLogo(
                            context,
                            borderRadius: 8,
                            height: 50,
                            alignIconStart: true,
                            label: usePhone ? 'Use Email Instead' : 'Use Phone Number Instead',
                            icon: usePhone ? Icons.email_outlined : Icons.phone_outlined,
                            outlined: true,
                            onTap: () => setState(() => usePhone = !usePhone),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
