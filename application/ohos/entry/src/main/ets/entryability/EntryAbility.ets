
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { LiteAVBase } from '@tencentcloud/liteavsdk_professional';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    LiteAVBase.setContext(this.context);
    GeneratedPluginRegistrant.registerWith(flutterEngine)
  }
}
