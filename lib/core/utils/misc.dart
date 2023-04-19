import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:plain_notification_token/plain_notification_token.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toolbox/data/provider/app.dart';
import 'package:toolbox/locator.dart';

import '../../view/widget/rebuild.dart';
import 'platform.dart';

Future<bool> shareFiles(BuildContext context, List<String> filePaths) async {
  for (final filePath in filePaths) {
    if (!await File(filePath).exists()) {
      return false;
    }
  }
  var text = '';
  if (filePaths.length == 1) {
    text = filePaths.first.split('/').last;
  } else {
    text = '${filePaths.length} ${S.of(context)!.files}';
  }
  // ignore: deprecated_member_use
  await Share.shareFiles(filePaths, text: 'ServerBox -> $text');
  return filePaths.isNotEmpty;
}

Future<bool> shareText(String text) async {
  final result = await Share.shareWithResult(text, subject: 'ServerBox backup');
  return result.status == ShareResultStatus.success;
}

void copy(String text) {
  Clipboard.setData(ClipboardData(text: text));
}

Future<String?> pickOneFile() async {
  final app = locator<AppProvider>();
  app.setMoveBg(false);
  final result = await FilePicker.platform.pickFiles(type: FileType.any);
  app.setMoveBg(true);
  return result?.files.single.path;
}

Future<String?> getToken() async {
  if (isIOS) {
    final plainNotificationToken = PlainNotificationToken();
    plainNotificationToken.requestPermission();

    // If you want to wait until Permission dialog close,
    // you need wait changing setting registered.
    await plainNotificationToken.onIosSettingsRegistered.first;
    return await plainNotificationToken.getToken();
  }
  return null;
}

String? getFileName(String? path) {
  if (path == null) {
    return null;
  }
  return path.split('/').last;
}

void rebuildAll(BuildContext context) {
  RebuildWidget.restartApp(context);
}
