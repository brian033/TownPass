import 'dart:io';
import 'package:get/get.dart';
import 'package:town_pass/bean/account.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/service/device_service.dart';
import 'package:town_pass/service/notification_service.dart';
import 'package:town_pass/service/package_service.dart';

class NewComponentViewController extends GetxController {
  final AccountService _accountService = Get.find<AccountService>();
  final DeviceService _deviceService = Get.find<DeviceService>();
  final PackageService _packageService = Get.find<PackageService>();

  // 帳戶資訊
  Account? get account => _accountService.account;

  String get realName => account?.realName ?? '未設定';
  String get email => account?.email ?? '未設定';
  String get accountId => account?.account ?? '未設定';
  String get username => account?.username ?? '未設定';
  String get phoneNumber => account?.phoneNumber ?? '未設定';
  String get birthday => account?.birthday ?? '未設定';
  String get idNumber => account?.idNumber ?? '未設定';
  String get residentAddress => account?.residentAddress ?? '未設定';
  String get memberType => account?.memberType ?? '未設定';
  String get verifyLevel => account?.verifyLevel ?? '未設定';
  String get cityInternetUid => account?.cityInternetUid ?? '未設定';
  bool get isCitizen => account?.citizen ?? false;
  bool get isNativePeople => account?.nativePeople ?? false;

  // 裝置資訊
  String get deviceBrand {
    if (Platform.isAndroid) {
      return _deviceService.androidDeviceInfo?.brand ?? '未知';
    }
    return 'Apple';
  }

  String get deviceModel {
    if (Platform.isAndroid) {
      return _deviceService.androidDeviceInfo?.model ?? '未知';
    }
    if (Platform.isIOS) {
      return _deviceService.iosDeviceInfo?.model ?? '未知';
    }
    return '未知';
  }

  String get deviceName {
    if (Platform.isAndroid) {
      return _deviceService.androidDeviceInfo?.device ?? '未知';
    }
    if (Platform.isIOS) {
      return _deviceService.iosDeviceInfo?.name ?? '未知';
    }
    return '未知';
  }

  String get osVersion {
    if (Platform.isAndroid) {
      final version = _deviceService.androidDeviceInfo?.version;
      return 'Android ${version?.release ?? '未知'} (SDK ${version?.sdkInt ?? '?'})';
    }
    if (Platform.isIOS) {
      final info = _deviceService.iosDeviceInfo;
      return '${info?.systemName ?? 'iOS'} ${info?.systemVersion ?? '未知'}';
    }
    return '未知';
  }

  String get appVersion {
    final version = _packageService.packageInfo?.version ?? '未知';
    final buildNumber = _packageService.packageInfo?.buildNumber ?? '未知';
    return '$version ($buildNumber)';
  }

  String get isPhysicalDevice {
    if (Platform.isAndroid) {
      return (_deviceService.androidDeviceInfo?.isPhysicalDevice ?? false) ? '是' : '否（模擬器）';
    }
    if (Platform.isIOS) {
      return (_deviceService.iosDeviceInfo?.isPhysicalDevice ?? false) ? '是' : '否（模擬器）';
    }
    return '未知';
  }

  String get deviceId {
    if (Platform.isAndroid) {
      return _deviceService.androidDeviceInfo?.id ?? '未知';
    }
    if (Platform.isIOS) {
      return _deviceService.iosDeviceInfo?.identifierForVendor ?? '未知';
    }
    return '未知';
  }

  String get manufacturer {
    if (Platform.isAndroid) {
      return _deviceService.androidDeviceInfo?.manufacturer ?? '未知';
    }
    return 'Apple';
  }

  @override
  void onInit() {
    super.onInit();
  }

  // 發送測試推播
  Future<void> sendTestNotification() async {
    // 先請求權限
    await NotificationService.requestPermission();

    // 發送通知
    await NotificationService.showNotification(
      title: '測試通知',
      content: 'hello test push',
    );
  }
}

