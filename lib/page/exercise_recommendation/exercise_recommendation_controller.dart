import 'package:get/get.dart';
import 'package:town_pass/bean/mrt_station.dart';
import 'package:town_pass/bean/body_part.dart';

class ExerciseRecommendationController extends GetxController {
  // 接收的參數
  late MrtStation startStation;
  late MrtStation endStation;
  late BodyPart bodyPart;
  late int estimatedMinutes;

  final Rxn<ExerciseRecommendation> _exercise = Rxn<ExerciseRecommendation>();
  final RxBool isLoading = false.obs;

  Rxn<ExerciseRecommendation> get exercise => _exercise;

  @override
  void onInit() {
    super.onInit();

    // 從路由參數獲取資料
    final args = Get.arguments as Map<String, dynamic>;
    startStation = args['startStation'] as MrtStation;
    endStation = args['endStation'] as MrtStation;
    bodyPart = args['bodyPart'] as BodyPart;
    estimatedMinutes = args['estimatedMinutes'] as int;

    // TODO: 根據參數推薦適合的運動
    loadRecommendedExercises();
  }

  // 載入推薦的運動
  Future<void> loadRecommendedExercises() async {
    // TODO: 實作推薦邏輯
    // 根據 bodyPart 和 estimatedMinutes 篩選適合的運動
    // TODO: 實作推薦邏輯（串接服務後再補上）
    print('推薦運動給：${bodyPart.name}，預估時間：$estimatedMinutes 分鐘');
  }

  /// 對外提供設定推薦運動資料的接口
  void setExercise(ExerciseRecommendation item) {
    isLoading.value = false;
    _exercise.value = item;
  }

  /// 模擬載入假資料
  Future<void> loadSampleExercises() async {
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    setExercise(
      ExerciseRecommendation(
        name: '肩頸舒展',
        imageUrl: 'https://images.unsplash.com/photo-1547045662-28cfb6b02c42',
        description: '透過肩頸拉伸減緩長時間乘車的僵硬感。',
      ),
    );
  }
}

class ExerciseRecommendation {
  ExerciseRecommendation({
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  final String name;
  final String imageUrl;
  final String description;
}

