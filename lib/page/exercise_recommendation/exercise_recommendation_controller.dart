import 'package:get/get.dart';
import 'package:town_pass/bean/body_part.dart';
import 'package:town_pass/bean/mrt_connection.dart';
import 'package:town_pass/bean/mrt_station.dart';

class ExerciseRecommendationController extends GetxController {
  // 接收的參數
  late MrtStation startStation;
  late MrtStation endStation;
  late BodyPart bodyPart;
  late int estimatedMinutes;
  MrtRouteResult? routeResult;

  @override
  void onInit() {
    super.onInit();

    // 從路由參數獲取資料
    final args = Get.arguments as Map<String, dynamic>;
    startStation = args['startStation'] as MrtStation;
    endStation = args['endStation'] as MrtStation;
    bodyPart = args['bodyPart'] as BodyPart;
    estimatedMinutes = args['estimatedMinutes'] as int;
    routeResult = args['routeResult'] as MrtRouteResult?;

    // TODO: 根據參數推薦適合的運動
    loadRecommendedExercises();
  }

  // 載入推薦的運動
  Future<void> loadRecommendedExercises() async {
    // TODO: 實作推薦邏輯
    // 根據 bodyPart 和 estimatedMinutes 篩選適合的運動
    print('推薦運動給：${bodyPart.name}，預估時間：$estimatedMinutes 分鐘');
  }
}
