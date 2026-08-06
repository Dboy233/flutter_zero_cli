import 'dart:io';

import 'package:fluzer/src/gen_l10n/toast_handle_patcher.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

/// 模板原版 handle（assert 兜底），结构与 flutter_zero_template 一致，
/// 另带一个开发者可能已扩展的 _handleErrorCode switch。
const _templateSource = '''
import 'package:flutter/material.dart';

bool defaultToastHandle(BuildContext context, UIEffect effect) {
  if (effect is! ToastEffect) return false;

  final svc = getIt<ToastService>();
  if (effect.message != null) {
    svc.showInfo(effect.message!);
  } else if (effect.code != null) {
    svc.showError(_handleErrorCode(context, effect.code!));
  } else if (effect.l10nCode != null) {
    // l10nCode 是开发者自定义键，必须由业务 handle 解析。
    assert(() {
      debugPrint('Unhandled ToastEffect.l10nCode: \${effect.l10nCode}.');
      return true;
    }(), 'l10nCode must be resolved by a business EffectHandle');
  }
  return true;
}

String _handleErrorCode(BuildContext context, int code) {
  return switch (code) {
    AppErrorCodes.unknown => l.unknownError,
    AppErrorCodes.customBusinessCode => l.customError, // 开发者自己加的
    _ => l.unknownErrorCode(code.toString()),
  };
}
''';

/// 已接线版 handle（上一轮 gen-l10n patch 后的状态）。
const _wiredSource = '''
import 'package:flutter/material.dart';
import 'package:my_app/l10n/gen/l10n_code.dart';
import 'package:my_app/l10n/gen/l10n_toast_effect_helper.dart';

bool defaultToastHandle(BuildContext context, UIEffect effect) {
  if (effect is! ToastEffect) return false;

  final svc = getIt<ToastService>();
  if (effect.message != null) {
    svc.showInfo(effect.message!);
  } else if (effect.code != null) {
    svc.showError(_handleErrorCode(context, effect.code!));
  } else if (effect.l10nCode != null) {
    L10nToastEffectHelper.showToastFromL10nCode(
      context,
      L10nCode.parse(effect.l10nCode!),
    );
  }
  return true;
}
''';

/// 开发者自定义了 l10nCode 分支的 handle。
const _customSource = '''
import 'package:flutter/material.dart';

bool defaultToastHandle(BuildContext context, UIEffect effect) {
  if (effect is! ToastEffect) return false;

  final svc = getIt<ToastService>();
  if (effect.message != null) {
    svc.showInfo(effect.message!);
  } else if (effect.l10nCode != null) {
    // 开发者自己的业务解析逻辑
    final resolved = myCustomResolver(context, effect.l10nCode!);
    svc.showInfo(resolved);
  }
  return true;
}
''';

void main() {
  late Directory tempDir;
  late File handleFile;
  late ToastHandlePatcher patcher;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('patcher_test_');
    handleFile = File(p.join(tempDir.path, 'default_toast_effect_handle.dart'));
    patcher = const ToastHandlePatcher();
  });

  tearDown(() async {
    await deleteTempDir(tempDir);
  });

  group('patchDefaultToastHandle', () {
    test('模板态（assert 兜底）→ patched，分支被替换', () async {
      handleFile.writeAsStringSync(_templateSource);

      final outcome = await patcher.patch(handleFile);

      expect(outcome.result, ToastHandlePatchResult.patched);
      expect(outcome.replacedSource, contains('assert('));

      final patched = handleFile.readAsStringSync();
      expect(patched, contains('L10nToastEffectHelper.showToastFromL10nCode('));
      expect(patched, contains('L10nCode.parse(effect.l10nCode!)'));
      expect(patched, isNot(contains('Unhandled ToastEffect.l10nCode')));
    });

    test('模板态替换不触碰同文件其他开发者代码（误触防护）', () async {
      handleFile.writeAsStringSync(_templateSource);

      await patcher.patch(handleFile);

      final patched = handleFile.readAsStringSync();
      // _handleErrorCode 中开发者添加的 case 必须原样保留
      expect(patched, contains('AppErrorCodes.customBusinessCode'));
      expect(patched, contains('// 开发者自己加的'));
      // message / code 分支不受影响
      expect(patched, contains('svc.showInfo(effect.message!)'));
      expect(patched, contains('svc.showError(_handleErrorCode(context, effect.code!))'));
    });

    test('已接线态 → alreadyWired，内容不变（幂等）', () async {
      handleFile.writeAsStringSync(_wiredSource);

      final outcome = await patcher.patch(handleFile);

      expect(outcome.result, ToastHandlePatchResult.alreadyWired);
      expect(handleFile.readAsStringSync(), _wiredSource);
    });

    test('自定义态 → customSkipped，内容不变', () async {
      handleFile.writeAsStringSync(_customSource);

      final outcome = await patcher.patch(handleFile);

      expect(outcome.result, ToastHandlePatchResult.customSkipped);
      expect(handleFile.readAsStringSync(), _customSource);
    });

    test('自定义态 + force → patched', () async {
      handleFile.writeAsStringSync(_customSource);

      final outcome = await patcher.patch(handleFile, force: true);

      expect(outcome.result, ToastHandlePatchResult.patched);
      final patched = handleFile.readAsStringSync();
      expect(patched, contains('L10nToastEffectHelper.showToastFromL10nCode('));
      expect(patched, isNot(contains('myCustomResolver')));
    });

    test('找不到 defaultToastHandle 函数 → anchorNotFound', () async {
      handleFile.writeAsStringSync('void unrelated() {}\n');

      final outcome = await patcher.patch(handleFile);

      expect(outcome.result, ToastHandlePatchResult.anchorNotFound);
    });

    test('分支条件被改写 → anchorNotFound（不硬来）', () async {
      handleFile.writeAsStringSync('''
bool defaultToastHandle(BuildContext context, UIEffect effect) {
  if (effect is! ToastEffect) return false;
  if (effect.l10nCode != null && effect.message == null) {
    assert(() { return true; }());
  }
  return true;
}
''');

      final outcome = await patcher.patch(handleFile);

      expect(outcome.result, ToastHandlePatchResult.anchorNotFound);
    });

    test('condition 格式差异（换行/多余空格）仍可匹配', () async {
      handleFile.writeAsStringSync('''
bool defaultToastHandle(BuildContext context, UIEffect effect) {
  if (effect is! ToastEffect) return false;
  if ( effect.l10nCode\n      !=\n      null ) {
    assert(() { return true; }());
  }
  return true;
}
''');

      final outcome = await patcher.patch(handleFile);

      expect(outcome.result, ToastHandlePatchResult.patched);
    });
  });

  group('formatDartFile', () {
    test('格式化 patch 后的文件且保持语法有效', () async {
      handleFile.writeAsStringSync(_templateSource);
      await patcher.patch(handleFile);

      await patcher.format(handleFile);

      final formatted = handleFile.readAsStringSync();
      // dart_style 输出无连续三换行，且接线代码存在
      expect(formatted, isNot(contains('\n\n\n')));
      expect(formatted, contains('L10nToastEffectHelper.showToastFromL10nCode('));
    });
  });
}
