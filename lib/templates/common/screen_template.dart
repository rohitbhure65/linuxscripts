import 'package:flutter/material.dart';

/// Screen template - basic screen with app bar
class ${FEATURE_NAME}Screen extends StatelessWidget {
  const ${FEATURE_NAME}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('${FEATURE_NAME}'),
      ),
      body: const Center(
        child: Text('${FEATURE_NAME} Screen'),
      ),
    );
  }
}