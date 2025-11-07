import 'package:flutter/material.dart';
import 'package:town_pass/gen/assets.gen.dart';
import 'package:town_pass/page/city_service/widget/official_service_card/official_service_card.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_route.dart';
import 'package:town_pass/util/tp_text.dart';

class OfficialServiceCardNew extends OfficialServiceCard {
  const OfficialServiceCardNew({super.key});

  @override
  Color get borderColor => TPColors.grayscale100;

  @override
  Widget layoutBuild(BuildContext context, BoxConstraints constraint) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await TPRoute.openUri(uri: 'local://new_component');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: TPColors.white,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: TPColors.grayscale100),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TPText(
                    '新元件',
                    style: TPTextStyles.h3SemiBold,
                    color: TPColors.primary500,
                    overflow: TextOverflow.ellipsis,
                  ),
                  TPText(
                    'New Component',
                    style: TPTextStyles.caption,
                    color: TPColors.grayscale700,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox.fromSize(
              size: const Size.square(48),
              child: Assets.svg.iconMore.svg(),
            ),
          ],
        ),
      ),
    );
  }
}

