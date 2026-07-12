import 'package:analyzer/dart/ast/ast.dart';
import 'package:codemod_recipe/codemod_recipe.dart';

/// 在指定类的方法体末尾插入代码的 Transform。
///
/// 只处理 `{ ... }` 块式方法体，`=> expr` 和抽象方法会被忽略。
/// 通过 [skipIfContains] 实现幂等。
///
/// Transform that inserts code at the end of a method body in a given class.
/// Only handles `{ ... }` block bodies; ignores `=> expr` and abstract methods.
/// Idempotent via [skipIfContains].
class InsertAtMethodEndTransform implements CodeTransform {
  /// 创建 Transform。
  ///
  /// Creates the transform.
  const InsertAtMethodEndTransform({
    required this.className,
    required this.methodName,
    required this.code,
    this.skipIfContains,
  });

  /// 类名。
  ///
  /// Class name.
  final String className;

  /// 方法名。
  ///
  /// Method name.
  final String methodName;

  /// 要插入的代码字符串。
  ///
  /// Code to insert.
  final String code;

  /// 若方法体源码已包含该字符串，则跳过插入。
  ///
  /// Skip insertion if the method body already contains this string.
  final String? skipIfContains;

  @override
  Future<List<SourcePatch>> apply(String source, CodemodContext context) async {
    final unit = parseSource(source);
    final cls = findClassByName(unit, className);
    if (cls == null) return [];

    final method = findMethodByName(cls, methodName);
    if (method == null) return [];

    final body = method.body;
    if (body is! BlockFunctionBody) return [];

    if (skipIfContains != null) {
      final methodSource = source.substring(method.offset, method.end);
      if (methodSource.contains(skipIfContains!)) return [];
    }

    // 在方法体块内最后一个换行符之后插入，确保代码位于 `}` 所在行之前
    // 且不继承 `}` 的缩进。
    // Insert after the last newline inside the block body so the code sits
    // on its own line before the `}` and does not inherit the `}` indentation.
    final blockStart = body.block.leftBracket.end;
    final blockEnd = body.block.rightBracket.offset;
    final blockSource = source.substring(blockStart, blockEnd);
    final lastNewline = blockSource.lastIndexOf('\n');
    final insertOffset = lastNewline >= 0
        ? blockStart + lastNewline + 1
        : blockStart;

    return [
      SourcePatch(
        insertOffset,
        0,
        code,
        description: 'Insert at end of $className.$methodName',
      ),
    ];
  }
}
