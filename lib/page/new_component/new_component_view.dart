import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/bean/mrt_station.dart';
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
                    size: const Size.square(80),
                    child: Assets.svg.iconPlayground.svg(),
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 10),

                // 起站下拉選單
                _buildStartStationField(),
                const SizedBox(height: 16),

                // 終站下拉選單
                _buildEndStationField(),
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
                // 底部額外空間，確保鍵盤彈出時仍可 scroll
                SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 300),
              ],
            ),
          ),
        );
      }),
    );
  }

  // 建立起點站選單（按距離排序，帶色塊和背景色）
  Widget _buildStartStationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TPText(
          '起站',
          style: TPTextStyles.bodySemiBold,
          color: TPColors.grayscale900,
        ),
        const SizedBox(height: 8),
        Autocomplete<MrtStation>(
          initialValue: controller.selectedStartStation.value != null
              ? TextEditingValue(
                  text: controller.selectedStartStation.value!.displayName)
              : null,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final sorted = controller.sortedStartStations;
            if (textEditingValue.text.isEmpty) {
              return sorted;
            }
            return sorted.where((station) {
              final itemText = station.displayName.toLowerCase();
              final searchText = textEditingValue.text.toLowerCase();
              return itemText.contains(searchText);
            });
          },
          onSelected: (MrtStation selection) {
            controller.selectedStartStation.value = selection;
          },
          displayStringForOption: (station) => station.displayName,
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            if (controller.selectedStartStation.value != null &&
                textEditingController.text.isEmpty) {
              textEditingController.text =
                  controller.selectedStartStation.value!.displayName;
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
                  hintText: '請選擇起始站',
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
            AutocompleteOnSelected<MrtStation> onSelected,
            Iterable<MrtStation> options,
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
                      final station = options.elementAt(index);
                      return InkWell(
                        onTap: () {
                          onSelected(station);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // 顯示線路色塊
                              ...station.lineColors.map((colorHex) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: _buildColorDot(colorHex),
                                );
                              }),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TPText(
                                  station.displayName,
                                  style: TPTextStyles.bodyRegular,
                                  color: TPColors.grayscale900,
                                ),
                              ),
                            ],
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

  // 建立終點站選單（按線路分組顯示）
  Widget _buildEndStationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TPText(
          '終站',
          style: TPTextStyles.bodySemiBold,
          color: TPColors.grayscale900,
        ),
        const SizedBox(height: 8),
        Autocomplete<MrtStation>(
          initialValue: controller.selectedEndStation.value != null
              ? TextEditingValue(
                  text: controller.selectedEndStation.value!.displayName)
              : null,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final grouped = controller.groupedEndStations;
            final allStations = <MrtStation>[];

            // 收集所有站點（去重）
            final seen = <String>{};
            for (final stations in grouped.values) {
              for (final station in stations) {
                if (!seen.contains(station.id)) {
                  seen.add(station.id);
                  allStations.add(station);
                }
              }
            }

            if (textEditingValue.text.isEmpty) {
              return allStations;
            }
            return allStations.where((station) {
              final itemText = station.displayName.toLowerCase();
              final searchText = textEditingValue.text.toLowerCase();
              return itemText.contains(searchText);
            });
          },
          onSelected: (MrtStation selection) {
            controller.selectedEndStation.value = selection;
          },
          displayStringForOption: (station) => station.displayName,
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            if (controller.selectedEndStation.value != null &&
                textEditingController.text.isEmpty) {
              textEditingController.text =
                  controller.selectedEndStation.value!.displayName;
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
                  hintText: '請選擇目的地站',
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
            AutocompleteOnSelected<MrtStation> onSelected,
            Iterable<MrtStation> options,
          ) {
            final grouped = controller.groupedEndStations;

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: TPColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: TPColors.grayscale300,
                      width: 1,
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    children: _buildGroupedStationList(grouped, onSelected),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 建立分組的站點列表
  List<Widget> _buildGroupedStationList(
    Map<String, List<MrtStation>> grouped,
    AutocompleteOnSelected<MrtStation> onSelected,
  ) {
    final List<Widget> widgets = [];
    final lineNames = {
      'red': '紅線',
      'blue': '藍線',
      'green': '綠線',
      'orange': '橘線',
      'brown': '棕線',
      'yellow': '黃線',
    };

    grouped.forEach((line, stations) {
      if (stations.isEmpty) return;

      // 取得該線的第一個站點的顏色
      final colorHex =
          stations.first.lineColors[stations.first.lines.indexOf(line)];

      // 分組標題
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _buildColorDot(colorHex, size: 8),
              const SizedBox(width: 8),
              TPText(
                lineNames[line] ?? line,
                style: TPTextStyles.bodySemiBold,
                color: TPColors.grayscale600,
              ),
            ],
          ),
        ),
      );

      // 該線的所有站點
      for (final station in stations) {
        final colorIndex = station.lines.indexOf(line);
        final stationColorHex =
            colorIndex >= 0 ? station.lineColors[colorIndex] : colorHex;

        widgets.add(
          InkWell(
            onTap: () {
              onSelected(station);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  _buildColorDot(stationColorHex),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TPText(
                      station.displayName,
                      style: TPTextStyles.bodyRegular,
                      color: TPColors.grayscale900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });

    return widgets;
  }

  // 建立圓形色塊
  Widget _buildColorDot(String colorHex, {double size = 12}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _hexToColor(colorHex),
        shape: BoxShape.circle,
      ),
    );
  }

  // 將 hex 字串轉換為 Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
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
