import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:viaamigo/shared/controllers/signup_controller.dart';
import 'package:viaamigo/src/utilitaires/theme/ThemedScaffoldWrapper.dart';

class SignupBirthdayPage extends StatefulWidget {
  const SignupBirthdayPage({super.key});

  @override
  State<SignupBirthdayPage> createState() => _SignupBirthdayPageState();
}

class _SignupBirthdayPageState extends State<SignupBirthdayPage> {

  @override
void initState() {
  super.initState();
  signupController.currentStepRoute.value = '/signup/birthday'; // ✅ À la bonne place
}

  DateTime selectedDate = DateTime.now().subtract(const Duration(days: 365 * 18));
  

  void _showCupertinoDatePicker(BuildContext context) {
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate,
                  maximumDate: DateTime.now(),
                  minimumYear: 1900,
                  maximumYear: DateTime.now().year,
                  onDateTimeChanged: (date) {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ThemedScaffoldWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Get.back(),
                ),
                const SizedBox(height: 10),

                Text(
                  "When is your birthday?",
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                GestureDetector(
                  onTap: () => _showCupertinoDatePicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: theme.dividerColor),
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat.yMMMMd().format(selectedDate),
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                "Your birthday will be used to create your profile and for age verification.\nIt will not be shared with other users.",
                                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                const Spacer(),

                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      iconSize: 32,
                      onPressed: () {
                        signupController.updateField('birthday', selectedDate);
                        Get.toNamed('/signup/role');
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
