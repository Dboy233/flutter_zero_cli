/// `defaultToastHandle` 自动接线 patcher。
///
/// 将 `default_toast_effect_handle.dart` 中 `effect.l10nCode != null`
/// 分支的 assert 兜底替换为 `L10nToastEffectHelper` 调用。
///
/// 三态检测（防止误触开发者修改）：
/// - 模板态（block 含 `assert(`）→ 执行替换；
/// - 已接线态（block 含 `L10nToastEffectHelper`）→ 幂等跳过；
/// - 自定义态（其他）→ 跳过，除非 [force]。
///
/// AST 负责结构边界，规范化文本负责语义匹配；不处理 doc 注释。
library;

import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:analyzer/dart/analysis/utilities.dart';
// ignore: depend_on_referenced_packages
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_style/dart_style.dart';

/// patch 结果状态。
enum ToastHandlePatchResult {
  /// 模板态 → 已替换。
  patched,

  /// 已接线态 → 幂等跳过。
  alreadyWired,

  /// 自定义态 → 跳过（未加 --force）。
  customSkipped,

  /// 找不到函数或分支锚点。
  anchorNotFound,
}

/// patch 返回值：结果状态 + 被替换的分支原文（仅 [patched] 时非 null）。
typedef ToastHandlePatchOutcome = ({
  ToastHandlePatchResult result,
  String? replacedSource,
});

/// `defaultToastHandle` 函数名。
const String toastHandleFunctionName = 'defaultToastHandle';

/// 分支 condition 的规范化形式（去除所有空白后比较）。
const String _normalizedCondition = 'effect.l10nCode!=null';

/// 已接线态特征。
const String wiredMarker = 'L10nToastEffectHelper';

/// 模板态特征。
const String _templateMarker = 'assert(';

/// 依据 `defaultToastHandle` 的真实 `BuildContext` 形参名构造替换分支体，
/// 避免硬编码 `context` 导致自定义形参名的模板接线出非法的未定义引用。
String _buildReplacementBody(String contextParamName) => '''
L10nToastEffectHelper.showToastFromL10nCode(
          $contextParamName,
          L10nCode.parse(effect.l10nCode!),
        );''';

/// 对 [file] 执行接线 patch。
///
/// 封装 AST 解析、三态检测与文件 I/O。实例化后通过 [patch] 调用。
///
/// Patches the default toast handle file in-place.
class ToastHandlePatcher {
  const ToastHandlePatcher();

  /// 对 [file] 执行接线 patch。
  ///
  /// [force] 为 true 时自定义态也强制替换。返回状态与被替换原文。
  Future<ToastHandlePatchOutcome> patch(
    File file, {
    bool force = false,
  }) async {
    final source = await file.readAsString();

    final unit =
        parseString(content: source, throwIfDiagnostics: false).unit;
    final fn = unit.declarations.whereType<FunctionDeclaration>().where(
          (d) => d.name.lexeme == toastHandleFunctionName,
        );
    if (fn.isEmpty) {
      return (
        result: ToastHandlePatchResult.anchorNotFound,
        replacedSource: null,
      );
    }

    // 解析 defaultToastHandle 的真实 BuildContext 形参名，替换分支体时复用，
    // 避免硬编码 `context` 在自定义形参名的模板上生成非法引用。
    final contextParamName = _resolveContextParamName(fn.first);

    final body = fn.first.functionExpression.body;
    if (body is! BlockFunctionBody) {
      return (
        result: ToastHandlePatchResult.anchorNotFound,
        replacedSource: null,
      );
    }

    IfStatement? target;
    for (final stmt in body.block.statements) {
      target = _findL10nBranch(stmt, source);
      if (target != null) break;
    }
    if (target == null) {
      return (
        result: ToastHandlePatchResult.anchorNotFound,
        replacedSource: null,
      );
    }

    final thenBlock = target.thenStatement;
    if (thenBlock is! Block) {
      return (
        result: ToastHandlePatchResult.anchorNotFound,
        replacedSource: null,
      );
    }
    final blockSource = source.substring(thenBlock.offset, thenBlock.end);

    // 三态检测
    if (blockSource.contains(wiredMarker)) {
      return (
        result: ToastHandlePatchResult.alreadyWired,
        replacedSource: null,
      );
    }
    final isTemplate = blockSource.contains(_templateMarker);
    if (!isTemplate && !force) {
      return (
        result: ToastHandlePatchResult.customSkipped,
        replacedSource: null,
      );
    }

    // 保留原花括号，仅替换块内容；格式化由调用方统一收尾。
    final contentStart = thenBlock.leftBracket.end;
    final contentEnd = thenBlock.rightBracket.offset;
    final patched = source.replaceRange(
      contentStart,
      contentEnd,
      '\n        ${_buildReplacementBody(contextParamName)}\n      ',
    );
    await file.writeAsString(patched);
    return (
      result: ToastHandlePatchResult.patched,
      replacedSource: blockSource,
    );
  }

  /// 使用 dart_style 库内格式化 [file]（不走 `dart format` 子进程）。
  Future<void> format(File file) async {
    final source = await file.readAsString();
    try {
      final formatted = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(source);
      await file.writeAsString(formatted);
    } on Object {
      // 格式化失败保留未格式化内容（结构已由 AST patch 保证）。
    }
  }

  // ---- 私有 ----

  /// 在 [stmt] 及其 else-if 链 / then 块嵌套中递归查找目标分支。
  IfStatement? _findL10nBranch(Statement stmt, String source) {
    if (stmt is! IfStatement) return null;

    final conditionSource = source.substring(
      stmt.expression.offset,
      stmt.expression.end,
    );
    if (_normalize(conditionSource) == _normalizedCondition) return stmt;

    final elseStmt = stmt.elseStatement;
    if (elseStmt != null) {
      final found = _findL10nBranch(elseStmt, source);
      if (found != null) return found;
    }

    final thenStmt = stmt.thenStatement;
    if (thenStmt is Block) {
      for (final nested in thenStmt.statements) {
        final found = _findL10nBranch(nested, source);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// 去除所有空白字符，用于 condition 的格式无关比较。
  String _normalize(String value) => value.replaceAll(RegExp(r'\s+'), '');

  /// 从 [fn] 解析 `BuildContext` 形参的真实名字，用于构造替换分支体。
  ///
  /// 优先匹配声明类型为 `BuildContext` 的形参；找不到时回退到第一个形参名，
  /// 仍找不到则回退约定名 `context`（模板契约保证首参为 BuildContext）。
  String _resolveContextParamName(FunctionDeclaration fn) {
    final params = fn.functionExpression.parameters?.parameters ?? const [];
    String? fallback;
    for (final p in params) {
      final name = _paramName(p);
      final type = _paramTypeSource(p);
      if (type != null && type.contains('BuildContext')) {
        return name ?? 'context';
      }
      fallback ??= name;
    }
    return fallback ?? 'context';
  }

  /// 解开 [DefaultFormalParameter] 包裹，返回内层形参名。
  String? _paramName(FormalParameter p) {
    final inner = p is DefaultFormalParameter ? p.parameter : p;
    return inner is SimpleFormalParameter ? inner.name?.lexeme : null;
  }

  /// 解开 [DefaultFormalParameter] 包裹，返回内层形参的类型源码。
  String? _paramTypeSource(FormalParameter p) {
    final inner = p is DefaultFormalParameter ? p.parameter : p;
    return inner is SimpleFormalParameter ? inner.type?.toSource() : null;
  }
}
