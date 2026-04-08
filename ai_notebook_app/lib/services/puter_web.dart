// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

Future<String?> callPuterStickerJs(String prompt) async {
  try {
    final promise = js.context.callMethod('generateAndUploadStickerWithPuter', [prompt]);
    final result = await js_util.promiseToFuture<String>(promise);
    return result;
  } catch (e) {
    print('Failed Puter JS: $e');
    return null;
  }
}
