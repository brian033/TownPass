import 'package:flutter/material.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class NewComponentView extends StatelessWidget {
  const NewComponentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TPColors.white,
      appBar: const TPAppBar(
        title: '新元件',
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TPText(
                '這是新元件頁面',
                style: TPTextStyles.h2SemiBold,
                color: TPColors.grayscale900,
              ),
              SizedBox(height: 16),
              TPText(
                'New Component Page',
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
