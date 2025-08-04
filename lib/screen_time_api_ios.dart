import 'package:screen_time_api_ios/screen_time_api_ios_method_channel.dart';
import 'package:screen_time_api_ios/screen_time_api_ios_platform_interface.dart';

class ScreenTimeApiIos {
  Future<String?> getPlatformVersion() {
    return ScreenTimeApiIosPlatform.instance.getPlatformVersion();
  }

  Future<void> selectAppsToDiscourage() async {
    final instance =
        ScreenTimeApiIosPlatform.instance as MethodChannelScreenTimeApiIos;
    await instance.selectAppsToDiscourage();
  }

  Future<void> encourageAll() async {
    final instance =
        ScreenTimeApiIosPlatform.instance as MethodChannelScreenTimeApiIos;
    await instance.encourageAll();
  }
}
