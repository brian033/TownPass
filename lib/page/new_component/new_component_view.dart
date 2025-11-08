import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/gen/assets.gen.dart';
import 'package:town_pass/page/new_component/new_component_view_controller.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class NewComponentView extends GetView<NewComponentViewController> {
  const NewComponentView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(NewComponentViewController());

    return Scaffold(
      backgroundColor: TPColors.white,
      appBar: const TPAppBar(
        title: '捷運動',
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: TPColors.primary500,
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 運動插圖 ICON
                Center(
                  child: SizedBox.fromSize(
                    size: const Size.square(120),
                    child: Assets.svg.iconPlayground.svg(),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TPText(
                    '在捷運上輕鬆運動',
                    style: TPTextStyles.h3SemiBold,
                    color: TPColors.grayscale900,
                  ),
                ),
                Center(
                  child: TPText(
                    '選擇您的旅程，我們推薦適合的伸展運動',
                    style: TPTextStyles.caption,
                    color: TPColors.grayscale600,
                  ),
                ),
                const SizedBox(height: 32),

                // 起站下拉選單
                _buildDropdownField(
                  label: '起站',
                  hint: '請選擇起始站',
                  value: controller.selectedStartStation.value,
                  items: controller.mrtStations,
                  onChanged: (value) {
                    controller.selectedStartStation.value = value;
                  },
                  itemBuilder: (station) => station.displayName,
                ),
                const SizedBox(height: 16),

                // 終站下拉選單
                _buildDropdownField(
                  label: '終站',
                  hint: '請選擇目的地站',
                  value: controller.selectedEndStation.value,
                  items: controller.mrtStations,
                  onChanged: (value) {
                    controller.selectedEndStation.value = value;
                  },
                  itemBuilder: (station) => station.displayName,
                ),
                const SizedBox(height: 16),

                // 要運動的部位下拉選單
                _buildDropdownField(
                  label: '要運動的部位',
                  hint: '請選擇身體部位',
                  value: controller.selectedBodyPart.value,
                  items: controller.bodyParts,
                  onChanged: (value) {
                    controller.selectedBodyPart.value = value;
                  },
                  itemBuilder: (bodyPart) => bodyPart.displayName,
                ),
                const SizedBox(height: 24),

                // 預估時間顯示
                Center(
                  child: TPText(
                    controller.estimatedTimeText,
                    style: TPTextStyles.bodySemiBold,
                    color: TPColors.primary500,
                  ),
                ),
                const SizedBox(height: 24),

                // 開始按鈕
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        controller.canStart ? controller.startPlanning : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TPColors.primary500,
                      disabledBackgroundColor: TPColors.grayscale300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const TPText(
                      '開始規劃運動',
                      style: TPTextStyles.h3SemiBold,
                      color: TPColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TPText(
          label,
          style: TPTextStyles.bodySemiBold,
          color: TPColors.grayscale900,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: TPColors.grayscale50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: TPColors.grayscale300,
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            hint: TPText(
              hint,
              style: TPTextStyles.bodyRegular,
              color: TPColors.grayscale500,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
            ),
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: TPColors.grayscale700,
            ),
            dropdownColor: TPColors.white,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: TPText(
                  itemBuilder(item),
                  style: TPTextStyles.bodyRegular,
                  color: TPColors.grayscale900,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
