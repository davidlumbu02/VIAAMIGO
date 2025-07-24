
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:viaamigo/shared/controllers/navigationcontroller.dart';

class PublishTripPage extends StatelessWidget {
  const PublishTripPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Publier un trajet"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.find<NavigationController>().goBack(),
        ),
      ),
      body: const Center(
        child: Text("Page de publication de trajet"),
      ),
    );
  }}