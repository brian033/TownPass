import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/bean/mrt_station.dart';
import 'package:town_pass/gen/assets.gen.dart';
import 'package:town_pass/page/exercise_history/exercise_history_view.dart';
import 'package:town_pass/page/new_component/new_component_view_controller.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class NewComponentView extends GetView<NewComponentViewController> {
  const NewComponentView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(NewComponentViewController());

    return Scaffold(
      backgroundColor: TPColors.white,
      appBar: AppBar(
        title: const Text('捷運動'),
        backgroundColor: TPColors.primary500,
        foregroundColor: TPColors.white,
        elevation: 0,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, size: 28),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              tooltip: '選單',
            ),
          ),
        ],
      ),
      endDrawer: _buildDrawer(),
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

                // 起站選擇（自動完成）
                _buildStartStationField(),
                const SizedBox(height: 16),

                // 終站選擇（自動完成）
                _buildEndStationField(),
                const SizedBox(height: 16),

                // 要運動的部位多選
                _buildBodyPartsMultiSelect(),
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
                  height: MediaQuery.of(context).viewInsets.bottom + 300,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // 建立起點站選單（按站名排序，顯示顏色標籤）
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
        LayoutBuilder(
          builder: (context, constraints) {
            final dropdownWidth = constraints.maxWidth;
            return Autocomplete<MrtStation>(
              key: ValueKey(controller.selectedStartStation.value?.id ?? 'start-none'),
              initialValue: controller.selectedStartStation.value != null
                  ? TextEditingValue(
                      text: controller.selectedStartStation.value!.displayName,
                    )
                  : const TextEditingValue(),
              optionsBuilder: (TextEditingValue textEditingValue) {
                final stations = controller.sortedStartStations;
                if (textEditingValue.text.isEmpty) {
                  return stations;
                }
                final searchText = textEditingValue.text.toLowerCase();
                return stations.where(
                  (station) => station.displayName.toLowerCase().contains(searchText),
                );
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
                if (!focusNode.hasFocus) {
                  final selected = controller.selectedStartStation.value;
                  if (selected == null && textEditingController.text.isNotEmpty) {
                    textEditingController.clear();
                  } else if (selected != null &&
                      textEditingController.text != selected.displayName) {
                    textEditingController.text = selected.displayName;
                  }
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
                    onTapOutside: (_) {
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
                return _buildStartStationOptionsView(
                  context,
                  onSelected,
                  options,
                  dropdownWidth,
                );
              },
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
        LayoutBuilder(
          builder: (context, constraints) {
            final dropdownWidth = constraints.maxWidth;
            return Autocomplete<MrtStation>(
              key: ValueKey(controller.selectedEndStation.value?.id ?? 'end-none'),
              initialValue: controller.selectedEndStation.value != null
                  ? TextEditingValue(
                      text: controller.selectedEndStation.value!.displayName,
                    )
                  : const TextEditingValue(),
              optionsBuilder: (TextEditingValue textEditingValue) {
                final grouped = controller.groupedEndStations;
                final allStations = <MrtStation>[];
                final seen = <String>{};

                for (final stations in grouped.values) {
                  for (final station in stations) {
                    if (seen.add(station.id)) {
                      allStations.add(station);
                    }
                  }
                }

                if (textEditingValue.text.isEmpty) {
                  return allStations;
                }
                final searchText = textEditingValue.text.toLowerCase();
                return allStations.where(
                  (station) => station.displayName.toLowerCase().contains(searchText),
                );
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
                if (!focusNode.hasFocus) {
                  final selected = controller.selectedEndStation.value;
                  if (selected == null && textEditingController.text.isNotEmpty) {
                    textEditingController.clear();
                  } else if (selected != null &&
                      textEditingController.text != selected.displayName) {
                    textEditingController.text = selected.displayName;
                  }
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
                    onTapOutside: (_) {
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
                return _buildEndStationOptionsView(
                  context,
                  onSelected,
                  options,
                  dropdownWidth,
                );
              },
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
    final widgets = <Widget>[];
    const lineNames = {
      'red': '紅線',
      'blue': '藍線',
      'green': '綠線',
      'orange': '橘線',
      'brown': '棕線',
      'yellow': '黃線',
    };

    grouped.forEach((line, stations) {
      if (stations.isEmpty) {
        return;
      }

      final colorIndex = stations.first.lines.indexOf(line);
      final colorHex = colorIndex >= 0 && colorIndex < stations.first.lineColors.length
          ? stations.first.lineColors[colorIndex]
          : (stations.first.lineColors.isNotEmpty
              ? stations.first.lineColors.first
              : '#000000');

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

      for (final station in stations) {
        final index = station.lines.indexOf(line);
        final stationColorHex = index >= 0 && index < station.lineColors.length
            ? station.lineColors[index]
            : colorHex;

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

  // 建立起站選單的下拉選單視圖
  Widget _buildStartStationOptionsView(
    BuildContext context,
    AutocompleteOnSelected<MrtStation> onSelected,
    Iterable<MrtStation> options,
    double dropdownWidth,
  ) {
    final optionList = options.toList();
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dropdownWidth,
            maxHeight: 240,
          ),
          child: Container(
            width: dropdownWidth,
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
              itemCount: optionList.length,
              itemBuilder: (BuildContext context, int index) {
                final station = optionList[index];
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
                        for (final colorHex in station.lineColors)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _buildColorDot(colorHex),
                          ),
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
      ),
    );
  }

  // 建立終站選單的下拉選單視圖
  Widget _buildEndStationOptionsView(
    BuildContext context,
    AutocompleteOnSelected<MrtStation> onSelected,
    Iterable<MrtStation> options,
    double dropdownWidth,
  ) {
    final filteredGrouped = <String, List<MrtStation>>{};
    final seenByLine = <String, Set<String>>{};
    final optionList = options.toList();

    for (final station in optionList) {
      for (var i = 0; i < station.lines.length; i++) {
        final line = station.lines[i];
        final list = filteredGrouped.putIfAbsent(line, () => []);
        final seen = seenByLine.putIfAbsent(line, () => <String>{});
        if (seen.add(station.id)) {
          list.add(station);
        }
      }
    }

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dropdownWidth,
            maxHeight: 300,
          ),
          child: Container(
            width: dropdownWidth,
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
              children: _buildGroupedStationList(filteredGrouped, onSelected),
            ),
          ),
        ),
      ),
    );
  }

  // 建立通用下拉選單的視圖
  Widget _buildDropdownOptionsView<T extends Object>(
    BuildContext context,
    AutocompleteOnSelected<T> onSelected,
    Iterable<T> options,
    double dropdownWidth,
    String Function(T) itemBuilder,
  ) {
    final optionList = options.toList();
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dropdownWidth,
            maxHeight: 240,
          ),
          child: Container(
            width: dropdownWidth,
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
              itemCount: optionList.length,
              itemBuilder: (BuildContext context, int index) {
                final option = optionList[index];
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
  
  // 根據身體部位 ID 返回對應的圖標
  IconData _getBodyPartIcon(String bodyPartId) {
    switch (bodyPartId) {
      case 'upper_body':
        return Icons.accessibility_new;
      case 'lower_body':
        return Icons.directions_walk;
      case 'core':
        return Icons.fitness_center;
      case 'full_body':
        return Icons.sports_gymnastics;
      case 'neck_shoulder':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
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
        LayoutBuilder(
          builder: (context, constraints) {
            final dropdownWidth = constraints.maxWidth;
            return Autocomplete<T>(
              key: ValueKey('${label}_${value != null ? itemBuilder(value) : 'none'}'),
              initialValue:
                  value != null ? TextEditingValue(text: itemBuilder(value)) : const TextEditingValue(),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return items;
                }
                final searchText = textEditingValue.text.toLowerCase();
                return items.where((item) {
                  final itemText = itemBuilder(item).toLowerCase();
                  return itemText.contains(searchText);
                });
              },
              onSelected: (selection) {
                onChanged(selection);
              },
              displayStringForOption: itemBuilder,
              fieldViewBuilder: (
                BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                if (!focusNode.hasFocus) {
                  if (value == null && textEditingController.text.isNotEmpty) {
                    textEditingController.clear();
                  } else if (value != null &&
                      textEditingController.text != itemBuilder(value)) {
                    textEditingController.text = itemBuilder(value);
                  }
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
                    onTapOutside: (_) {
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
                return _buildDropdownOptionsView(
                  context,
                  onSelected,
                  options,
                  dropdownWidth,
                  itemBuilder,
                );
              },
            );
          },
        ),
      ],
    );
  }

  // 建立身體部位多選界面
  Widget _buildBodyPartsMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TPText(
          '要運動的部位',
          style: TPTextStyles.bodySemiBold,
          color: TPColors.grayscale900,
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.bodyParts.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TPColors.grayscale50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TPColors.grayscale300,
                  width: 1,
                ),
              ),
              child: Center(
                child: TPText(
                  '載入中...',
                  style: TPTextStyles.bodyRegular,
                  color: TPColors.grayscale500,
                ),
              ),
            );
          }
          
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.bodyParts.map((bodyPart) {
              final isSelected = controller.isBodyPartSelected(bodyPart);
              return GestureDetector(
                onTap: () => controller.toggleBodyPart(bodyPart),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? TPColors.primary500
                        : TPColors.grayscale50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? TPColors.primary500
                          : TPColors.grayscale300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 身體部位圖標（未選中時有彩色背景圓形）
                      if (!isSelected)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _hexToColor(bodyPart.color).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getBodyPartIcon(bodyPart.id),
                            size: 16,
                            color: _hexToColor(bodyPart.color),
                          ),
                        )
                      else
                        Icon(
                          _getBodyPartIcon(bodyPart.id),
                          size: 18,
                          color: TPColors.white,
                        ),
                      const SizedBox(width: 8),
                      TPText(
                        bodyPart.displayName,
                        style: TPTextStyles.bodyRegular.copyWith(
                          color: isSelected
                              ? TPColors.white
                              : TPColors.grayscale900,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 選中狀態圖標
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: TPColors.white,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
        Obx(() => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TPText(
            controller.selectedBodyParts.isEmpty
                ? '請至少選擇一個部位'
                : '已選擇 ${controller.selectedBodyParts.length} 個部位',
            style: TPTextStyles.caption,
            color: controller.selectedBodyParts.isEmpty
                ? TPColors.grayscale500
                : TPColors.primary500,
          ),
        )),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 漂亮的漸層標題區
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [TPColors.primary500, TPColors.primary700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: TPColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: TPColors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TPText(
                      '捷運動',
                      style: TPTextStyles.h2SemiBold,
                      color: TPColors.white,
                    ),
                    const SizedBox(height: 4),
                    TPText(
                      '讓運動成為生活的一部分',
                      style: TPTextStyles.caption,
                      color: TPColors.white.withOpacity(0.9),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 選單項目
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TPColors.primary50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: TPColors.primary500,
                size: 22,
              ),
            ),
            title: const TPText(
              '運動歷史',
              style: TPTextStyles.bodySemiBold,
            ),
            subtitle: const TPText(
              '查看過去的運動紀錄',
              style: TPTextStyles.caption,
              color: TPColors.grayscale500,
            ),
            onTap: () {
              Get.back(); // 關閉 drawer
              Get.to(() => const ExerciseHistoryView());
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TPColors.grayscale100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: TPColors.grayscale600,
                size: 22,
              ),
            ),
            title: const TPText(
              '關於',
              style: TPTextStyles.bodySemiBold,
            ),
            subtitle: const TPText(
              '版本資訊與說明',
              style: TPTextStyles.caption,
              color: TPColors.grayscale500,
            ),
            onTap: () {
              Get.back();
              Get.snackbar(
                '關於捷運動',
                '版本 1.0.0\n結合捷運通勤與運動的健康生活應用',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
            },
          ),
        ],
      ),
    );
  }
}
