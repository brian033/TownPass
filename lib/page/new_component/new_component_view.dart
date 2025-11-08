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

  Widget _buildDropdownField<T extends Object>({
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
        Autocomplete<T>(
          initialValue:
              value != null ? TextEditingValue(text: itemBuilder(value)) : null,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return items;
            }
            return items.where((T item) {
              final itemText = itemBuilder(item).toLowerCase();
              final searchText = textEditingValue.text.toLowerCase();
              return itemText.contains(searchText);
            });
          },
          onSelected: (T selection) {
            onChanged(selection);
          },
          displayStringForOption: itemBuilder,
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            // 同步初始值
            if (value != null && textEditingController.text.isEmpty) {
              textEditingController.text = itemBuilder(value);
            }

            return Container(
              decoration: BoxDecoration(
                color: TPColors.grayscale50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TPColors.grayscale300,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: textEditingController,
                focusNode: focusNode,
                onTapOutside: (event) {
                  focusNode.unfocus();
                },
                style: TPTextStyles.bodyRegular.copyWith(
                  color: TPColors.grayscale900,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TPTextStyles.bodyRegular.copyWith(
                    color: TPColors.grayscale500,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: TPColors.grayscale700,
                  ),
                ),
              ),
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<T> onSelected,
            Iterable<T> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: TPColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: TPColors.grayscale300,
                      width: 1,
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final T option = options.elementAt(index);
                      return InkWell(
                        onTap: () {
                          onSelected(option);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: TPText(
                            itemBuilder(option),
                            style: TPTextStyles.bodyRegular,
                            color: TPColors.grayscale900,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
