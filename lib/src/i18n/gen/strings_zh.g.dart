///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsZh = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$zh app = Translations$app$zh._(_root);
	late final Translations$create$zh create = Translations$create$zh._(_root);
	late final Translations$feature$zh feature = Translations$feature$zh._(_root);
	late final Translations$genL10n$zh genL10n = Translations$genL10n$zh._(_root);
	late final Translations$cache$zh cache = Translations$cache$zh._(_root);
	late final Translations$version$zh version = Translations$version$zh._(_root);
	late final Translations$template$zh template = Translations$template$zh._(_root);
	late final Translations$versionCheck$zh versionCheck = Translations$versionCheck$zh._(_root);
	late final Translations$http$zh http = Translations$http$zh._(_root);
	late final Translations$codemod$zh codemod = Translations$codemod$zh._(_root);
	late final Translations$l10nParser$zh l10nParser = Translations$l10nParser$zh._(_root);
	late final Translations$spinner$zh spinner = Translations$spinner$zh._(_root);
	late final Translations$config$zh config = Translations$config$zh._(_root);

	/// zh: '模板版本 $version 超出当前 fluzer 支持范围（最高 $maxSupported）。请更新 fluzer：dart pub global activate fluzer'
	String unsupportedTooNew({required Object version, required Object maxSupported}) => '模板版本 ${version} 超出当前 fluzer 支持范围（最高 ${maxSupported}）。请更新 fluzer：dart pub global activate fluzer';

	/// zh: '模板版本 $version 过低，当前 fluzer 不支持，请升级项目模板或 fluzer。'
	String unsupportedTooOld({required Object version}) => '模板版本 ${version} 过低，当前 fluzer 不支持，请升级项目模板或 fluzer。';
}

// Path: app
class Translations$app$zh {
	Translations$app$zh._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: 'Flutter MVI 模板项目脚手架工具'
	String get description => 'Flutter MVI 模板项目脚手架工具';

	/// zh: '调试模式：显示详细日志、子进程原始输出与异常堆栈'
	String get logFlagHelp => '调试模式：显示详细日志、子进程原始输出与异常堆栈';

	/// zh: '执行出错：'
	String get unexpectedError => '执行出错：';

	/// zh: '指定界面语言（zh/en/ja），默认跟随系统'
	String get localeFlagHelp => '指定界面语言（zh/en/ja），默认跟随系统';
}

// Path: create
class Translations$create$zh {
	Translations$create$zh._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '从模板创建全新 Flutter 项目'
	String get description => '从模板创建全新 Flutter 项目';

	/// zh: '组织标识（影响 bundle ID）'
	String get orgHelp => '组织标识（影响 bundle ID）';

	/// zh: '错误：请指定项目名'
	String get nameRequired => '错误：请指定项目名';

	/// zh: '校验项目名与目录'
	String get step1Validate => '校验项目名与目录';

	/// zh: '用 Mason 渲染 project 模板'
	String get step2Render => '用 Mason 渲染 project 模板';

	/// zh: '执行 flutter create .'
	String get step3FlutterCreate => '执行 flutter create .';

	/// zh: '清理 flutter create 生成的多余测试文件'
	String get step4CleanTest => '清理 flutter create 生成的多余测试文件';

	/// zh: '执行 flutter pub get'
	String get step5PubGet => '执行 flutter pub get';

	/// zh: '执行 flutter gen-l10n'
	String get step6GenL10n => '执行 flutter gen-l10n';

	/// zh: ' 项目名: $name, 组织: $org'
	String detailProject({required Object name, required Object org}) => '  项目名: ${name}, 组织: ${org}';

	/// zh: ' 已生成 $path'
	String detailGenerated({required Object path}) => '  已生成 ${path}';

	/// zh: '项目创建完成！'
	String get created => '项目创建完成！';

	/// zh: '后续步骤：'
	String get nextSteps => '后续步骤：';

	/// zh: ' 2. fluzer new my_feature （可选：添加功能模块）'
	String get stepNewFeature => '  2. fluzer new my_feature （可选：添加功能模块）';

	/// zh: ' 3. flutter run （启动应用）'
	String get stepFlutterRun => '  3. flutter run           （启动应用）';

	/// zh: ' 已删除：test/widget_test.dart'
	String get removedWidgetTest => '  已删除：test/widget_test.dart';

	/// zh: ' 删除 widget_test.dart 失败：$error'
	String removeWidgetTestFailed({required Object error}) => '  删除 widget_test.dart 失败：${error}';

	/// zh: ' 已清理失败目录'
	String get cleanedFailedDir => '  已清理失败目录';

	/// zh: ' 清理失败目录失败：$error'
	String cleanupFailedDir({required Object error}) => '  清理失败目录失败：${error}';

	/// zh: '项目名不合法：必须只包含小写字母、数字和下划线，且以字母开头。'
	String get nameInvalid => '项目名不合法：必须只包含小写字母、数字和下划线，且以字母开头。';

	/// zh: '目录 $name 已存在，请选择不同的项目名。'
	String dirExists({required Object name}) => '目录 ${name} 已存在，请选择不同的项目名。';

	/// zh: '未找到 Flutter 命令。请确保 Flutter SDK 已正确安装并在 PATH 中。 原始错误：$error'
	String flutterNotFound({required Object error}) => '未找到 Flutter 命令。请确保 Flutter SDK 已正确安装并在 PATH 中。\n原始错误：${error}';

	/// zh: '创建失败：$error'
	String failed({required Object error}) => '创建失败：${error}';

	/// zh: '$step 执行失败 (exit code: $code)'
	String stepFailedWithCode({required Object step, required Object code}) => '${step} 执行失败 (exit code: ${code})';
}

// Path: feature
class Translations$feature$zh {
	Translations$feature$zh._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '新增功能模块'
	String get description => '新增功能模块';

	/// zh: '错误：请指定功能名'
	String get nameRequired => '错误：请指定功能名';

	/// zh: '功能名不能为空。'
	String get featureNameEmpty => '功能名不能为空。';

	/// zh: '加载项目配置'
	String get step1Load => '加载项目配置';

	/// zh: '解析模板加载器（本地或远程下载）'
	String get step2Template => '解析模板加载器（本地或远程下载）';

	/// zh: '生成功能模块 $feature'
	String step3Generate({required Object feature}) => '生成功能模块 ${feature}';

	/// zh: '运行 build_runner'
	String get step4BuildRunner => '运行 build_runner';

	/// zh: ' 项目根目录: $path'
	String detailProjectRoot({required Object path}) => '  项目根目录: ${path}';

	/// zh: ' 按项目模板版本 $version 钉死下载源'
	String detailPinnedVersion({required Object version}) => '  按项目模板版本 ${version} 钉死下载源';

	/// zh: ' 已生成功能模块 $feature'
	String detailGenerated({required Object feature}) => '  已生成功能模块 ${feature}';

	/// zh: 'build_runner 执行失败。'
	String get buildRunnerFailed => 'build_runner 执行失败。';

	/// zh: 'build_runner 执行完成。'
	String get buildRunnerCompleted => 'build_runner 执行完成。';

	/// zh: '生成失败：$error'
	String generationFailed({required Object error}) => '生成失败：${error}';

	/// zh: '功能模块 $feature 已创建并注册到 DI。'
	String successCreated({required Object feature}) => '功能模块 ${feature} 已创建并注册到 DI。';

	/// zh: '功能模块 $feature 已存在。'
	String featureExists({required Object feature}) => '功能模块 ${feature} 已存在。';

	/// zh: '功能名必须是 snake_case 且以小写字母开头，例如 user_profile。'
	String get featureNameInvalid => '功能名必须是 snake_case 且以小写字母开头，例如 user_profile。';
}

// Path: genL10n
class Translations$genL10n$zh {
	Translations$genL10n$zh._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '生成国际化代码并自动创建 L10nCode 类'
	String get description => '生成国际化代码并自动创建 L10nCode 类';

	/// zh: '校验项目'
	String get step1Validate => '校验项目';

	/// zh: '解析 l10n.yaml 与 ARB 目录'
	String get step2Parse => '解析 l10n.yaml 与 ARB 目录';

	/// zh: '执行 flutter gen-l10n'
	String get step3GenL10n => '执行 flutter gen-l10n';

	/// zh: '解析本地化成员'
	String get step4Members => '解析本地化成员';

	/// zh: '生成 L10nCode 等文件'
	String get step5Generate => '生成 L10nCode 等文件';

	/// zh: '接线 defaultToastHandle'
	String get step6Wire => '接线 defaultToastHandle';

	/// zh: ' 成员: $names'
	String detailMembers({required Object names}) => '  成员: ${names}';

	/// zh: '已生成：$path'
	String generated({required Object path}) => '已生成：${path}';

	/// zh: 'gen-l10n 执行失败：$error'
	String failed({required Object error}) => 'gen-l10n 执行失败：${error}';

	/// zh: 'defaultToastHandle 已接线，跳过（幂等）'
	String get alreadyWired => 'defaultToastHandle 已接线，跳过（幂等）';

	/// zh: '跳过 defaultToastHandle 自动接线'
	String get skipHandlePatchHelp => '跳过 defaultToastHandle 自动接线';

	/// zh: 'l10nCode 分支已被自定义时也强制覆盖'
	String get forceHandlePatchHelp => 'l10nCode 分支已被自定义时也强制覆盖';

	/// zh: '未找到 $dir 目录，请确保项目已配置国际化。'
	String arbDirNotFound({required Object dir}) => '未找到 ${dir} 目录，请确保项目已配置国际化。';

	/// zh: '$dir 目录中没有找到 .arb 文件。'
	String noArbFiles({required Object dir}) => '${dir} 目录中没有找到 .arb 文件。';

	/// zh: '找到 $count 个 .arb 文件'
	String foundArbFiles({required Object count}) => '找到 ${count} 个 .arb 文件';

	/// zh: 'flutter gen-l10n 执行失败（退出码: $code）。'
	String flutterFailed({required Object code}) => 'flutter gen-l10n 执行失败（退出码: ${code}）。';

	/// zh: '未找到生成的 $file，请检查 l10n.yaml 中 output-dir 配置。'
	String generatedFileNotFound({required Object file}) => '未找到生成的 ${file}，请检查 l10n.yaml 中 output-dir 配置。';

	/// zh: '解析到 $total 个本地化成员（$noParam 无参, $withParam 有参）'
	String parsedMembers({required Object total, required Object noParam, required Object withParam}) => '解析到 ${total} 个本地化成员（${noParam} 无参, ${withParam} 有参）';

	/// zh: '未解析到任何本地化成员，请检查 arb 文件是否包含翻译 key。'
	String get noMembers => '未解析到任何本地化成员，请检查 arb 文件是否包含翻译 key。';

	/// zh: '已跳过 defaultToastHandle 接线（--skip-handle-patch）'
	String get skippedHandlePatch => '已跳过 defaultToastHandle 接线（--skip-handle-patch）';

	/// zh: 'defaultToastHandle 已接线 L10nToastEffectHelper。 被替换的分支原文： $replaced'
	String patched({required Object replaced}) => 'defaultToastHandle 已接线 L10nToastEffectHelper。\n被替换的分支原文：\n${replaced}';

	/// zh: '检测到 l10nCode 分支已被自定义，跳过接线。 如需强制覆盖请使用 --force-handle-patch。'
	String get customSkipped => '检测到 l10nCode 分支已被自定义，跳过接线。\n如需强制覆盖请使用 --force-handle-patch。';

	/// zh: '未找到 default_toast_effect_handle.dart，跳过自动接线。 请手动将 L10nToastEffectHelper 接入 defaultToastHandle。'
	String get handleFileNotFound => '未找到 default_toast_effect_handle.dart，跳过自动接线。\n请手动将 L10nToastEffectHelper 接入 defaultToastHandle。';

	/// zh: '未找到 defaultToastHandle 的 l10nCode 分支锚点，跳过接线。 请手动接入 L10nToastEffectHelper。'
	String get branchAnchorNotFound => '未找到 defaultToastHandle 的 l10nCode 分支锚点，跳过接线。\n请手动接入 L10nToastEffectHelper。';
}

// Path: cache
class Translations$cache$zh {
	Translations$cache$zh._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '管理模板缓存'
	String get description => '管理模板缓存';

	/// zh: '查看已缓存的模板版本'
	String get listDescription => '查看已缓存的模板版本';

	/// zh: '清空所有缓存的模板版本'
	String get cleanDescription => '清空所有缓存的模板版本';

	/// zh: '暂无缓存（缓存目录不存在）。'
	String get noneNotExist => '暂无缓存（缓存目录不存在）。';

	/// zh: '暂无缓存版本。'
	String get noneVersions => '暂无缓存版本。';

	/// zh: '缓存目录：$path'
	String directory({required Object path}) => '缓存目录：${path}';

	/// zh: '缓存目录不存在，无需清理。'
	String get cleanNotExist => '缓存目录不存在，无需清理。';

	/// zh: '暂无缓存版本，无需清理。'
	String get cleanNone => '暂无缓存版本，无需清理。';

	/// zh: '删除失败 $name：$error'
	String deleteFailed({required Object name, required Object error}) => '删除失败 ${name}：${error}';

	/// zh: '已清空 $count 个缓存版本。'
	String cleared({required Object count}) => '已清空 ${count} 个缓存版本。';
}

// Path: version
class Translations$version$zh {
	Translations$version$zh._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '查看当前版本并检查更新'
	String get description => '查看当前版本并检查更新';

	/// zh: '正在检查更新…'
	String get checking => '正在检查更新…';

	/// zh: '（无法检查更新：包尚未发布或网络异常）'
	String get checkUnavailable => '（无法检查更新：包尚未发布或网络异常）';

	/// zh: '发现新版本 $latest，运行以下命令升级：'
	String newVersionFound({required Object latest}) => '发现新版本 ${latest}，运行以下命令升级：';

	/// zh: '已是最新版本'
	String get alreadyLatest => '已是最新版本';

	/// zh: '发现新版本 $latest，运行 dart pub global activate fluzer 升级'
	String updateHint({required Object latest}) => '发现新版本 ${latest}，运行 dart pub global activate fluzer 升级';
}

// Path: template
class Translations$template$zh {
	Translations$template$zh._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '本地模板不存在： $path'
	String localTemplateNotFound({required Object path}) => '本地模板不存在：\n${path}';

	/// zh: '远程模板中未找到 brick：$brickName'
	String remoteBrickNotFound({required Object brickName}) => '远程模板中未找到 brick：${brickName}';

	/// zh: '使用缓存模板：$path'
	String usingCachedDetail({required Object path}) => '使用缓存模板：${path}';

	/// zh: '模板下载失败（直连与镜像均不可达）：$url'
	String downloadFailed({required Object url}) => '模板下载失败（直连与镜像均不可达）：${url}';

	/// zh: '模板 zip 包含非法路径：$name'
	String zipIllegalPath({required Object name}) => '模板 zip 包含非法路径：${name}';

	/// zh: '远程模板中未找到 bricks 目录。'
	String get bricksDirNotFound => '远程模板中未找到 bricks 目录。';

	/// zh: '正在使用环境变量 FLUZER_BRICKS_DIR 指定的本地模板目录。'
	String get usingBricksDir => '正在使用环境变量 FLUZER_BRICKS_DIR 指定的本地模板目录。';

	/// zh: '正在使用环境变量 FLUZER_TEMPLATE_ZIP_URL 指定的远程模板地址。'
	String get usingZipUrl => '正在使用环境变量 FLUZER_TEMPLATE_ZIP_URL 指定的远程模板地址。';

	/// zh: '模板 registry 拉取失败，回退默认模板 zip：$error'
	String registryFallback({required Object error}) => '模板 registry 拉取失败，回退默认模板 zip：${error}';

	/// zh: '无法拉取模板 registry，无法定位模板版本 $version 的下载源。 请确认网络连接或检查模板 registry。'
	String registryUnavailable({required Object version}) => '无法拉取模板 registry，无法定位模板版本 ${version} 的下载源。\n请确认网络连接或检查模板 registry。';

	/// zh: '模板版本 $version 在 registry 中缺少有效的 url 字段。'
	String registryMissingUrl({required Object version}) => '模板版本 ${version} 在 registry 中缺少有效的 url 字段。';

	/// zh: '当前模板 registry 未收录版本 $version，请确认该模板版本已发布，或升级 fluzer 到支持该模板的版本。'
	String registryVersionNotFound({required Object version}) => '当前模板 registry 未收录版本 ${version}，请确认该模板版本已发布，或升级 fluzer 到支持该模板的版本。';

	/// zh: '定位模板版本 $version 的下载源失败：$error'
	String registryLocateFailed({required Object version, required Object error}) => '定位模板版本 ${version} 的下载源失败：${error}';
}

// Path: versionCheck
class Translations$versionCheck$zh {
	Translations$versionCheck$zh._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '（缓存）已是最新版本。'
	String get cacheLatest => '（缓存）已是最新版本。';

	/// zh: '（pub.dev）已是最新版本。'
	String get pubdevLatest => '（pub.dev）已是最新版本。';

	/// zh: '版本检查缓存已过期（$packageName），将重新获取'
	String detailCacheExpired({required Object packageName}) => '版本检查缓存已过期（${packageName}），将重新获取';

	/// zh: '版本检查缓存：$packageName 不可用'
	String detailCacheUnavailable({required Object packageName}) => '版本检查缓存：${packageName} 不可用';

	/// zh: '版本检查缓存：$packageName latest=$latest, hasUpdate=$hasUpdate'
	String detailCacheHit({required Object packageName, required Object latest, required Object hasUpdate}) => '版本检查缓存：${packageName} latest=${latest}, hasUpdate=${hasUpdate}';

	/// zh: '版本检查：使用 $packageName 的缓存结果'
	String detailUsingCached({required Object packageName}) => '版本检查：使用 ${packageName} 的缓存结果';

	/// zh: '正在 pub.dev 检查 $packageName 的更新…'
	String detailCheckingPubdev({required Object packageName}) => '正在 pub.dev 检查 ${packageName} 的更新…';

	/// zh: 'pub.dev 返回 $statusCode（$packageName），视为不可用'
	String detailPubdevStatus({required Object statusCode, required Object packageName}) => 'pub.dev 返回 ${statusCode}（${packageName}），视为不可用';

	/// zh: 'pub.dev：$packageName current=$current, latest=$latest, hasUpdate=$hasUpdate'
	String detailPubdevResult({required Object packageName, required Object current, required Object latest, required Object hasUpdate}) => 'pub.dev：${packageName} current=${current}, latest=${latest}, hasUpdate=${hasUpdate}';

	/// zh: '版本检查失败（$packageName）：$error'
	String detailCheckFailed({required Object packageName, required Object error}) => '版本检查失败（${packageName}）：${error}';

	/// zh: '缓存读取失败：$error'
	String detailCacheReadFailed({required Object error}) => '缓存读取失败：${error}';

	/// zh: '缓存写入失败：$error'
	String detailCacheWriteFailed({required Object error}) => '缓存写入失败：${error}';
}

// Path: http
class Translations$http$zh {
	Translations$http$zh._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '所有候选地址（直连 + 镜像）请求均失败。'
	String get allRequestsFailed => '所有候选地址（直连 + 镜像）请求均失败。';

	/// zh: '所有候选地址（直连 + 镜像）下载均失败。'
	String get allDownloadsFailed => '所有候选地址（直连 + 镜像）下载均失败。';

	/// zh: '候选地址请求失败：$url ($error)'
	String requestFailed({required Object url, required Object error}) => '候选地址请求失败：${url} (${error})';

	/// zh: '下载模板: [$bar] $percent%'
	String downloadProgress({required Object bar, required Object percent}) => '下载模板: [${bar}] ${percent}%';

	/// zh: '直连请求成功：$url'
	String directSuccess({required Object url}) => '直连请求成功：${url}';

	/// zh: '镜像请求成功：$url'
	String mirrorSuccess({required Object url}) => '镜像请求成功：${url}';

	/// zh: '直连下载成功：$url'
	String directDownloadSuccess({required Object url}) => '直连下载成功：${url}';

	/// zh: '镜像下载成功：$url'
	String mirrorDownloadSuccess({required Object url}) => '镜像下载成功：${url}';
}

// Path: codemod
class Translations$codemod$zh {
	Translations$codemod$zh._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '格式化失败：$error'
	String formatFailed({required Object error}) => '格式化失败：${error}';
}

// Path: l10nParser
class Translations$l10nParser$zh {
	Translations$l10nParser$zh._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '$name 声明后未找到类体。'
	String classBodyNotFound({required Object name}) => '${name} 声明后未找到类体。';

	/// zh: '$name 类体未闭合。'
	String classBodyUnclosed({required Object name}) => '${name} 类体未闭合。';

	/// zh: '未找到 abstract class $name 声明，请检查 l10n.yaml 的 output-class 配置。'
	String classNotFound({required Object name}) => '未找到 abstract class ${name} 声明，请检查 l10n.yaml 的 output-class 配置。';

	/// zh: '无法解析成员 $member 的参数声明: "$param"。'
	String paramParseFailed({required Object member, required Object param}) => '无法解析成员 ${member} 的参数声明: "${param}"。';
}

// Path: spinner
class Translations$spinner$zh {
	Translations$spinner$zh._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '步骤 $index/$total'
	String stepLabel({required Object index, required Object total}) => '步骤 ${index}/${total}';

	/// zh: '$label 完成'
	String stepCompleted({required Object label}) => '${label} 完成';

	/// zh: '$label 失败'
	String stepFailed({required Object label}) => '${label} 失败';
}

// Path: config
class Translations$config$zh {
	Translations$config$zh._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '未找到 $fileName，请确保在 flutter_zero 模板项目根目录下执行命令。'
	String notFound({required Object fileName}) => '未找到 ${fileName}，请确保在 flutter_zero 模板项目根目录下执行命令。';

	/// zh: '$fileName 格式错误：根节点必须是 Map。'
	String rootNotMap({required Object fileName}) => '${fileName} 格式错误：根节点必须是 Map。';

	/// zh: '$fileName 中缺少有效的 version 字段。'
	String missingVersion({required Object fileName}) => '${fileName} 中缺少有效的 version 字段。';

	/// zh: '$fileName 中 template_name 必须是 "flutter_zero"。'
	String templateNameInvalid({required Object fileName}) => '${fileName} 中 template_name 必须是 "flutter_zero"。';

	/// zh: '项目目录缺少 pubspec.yaml。'
	String get missingPubspec => '项目目录缺少 pubspec.yaml。';

	/// zh: 'pubspec.yaml 中缺少有效的 name 字段。'
	String get missingPubspecName => 'pubspec.yaml 中缺少有效的 name 字段。';
}

/// The flat map containing all translations for locale <zh>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.description' => 'Flutter MVI 模板项目脚手架工具',
			'app.logFlagHelp' => '调试模式：显示详细日志、子进程原始输出与异常堆栈',
			'app.unexpectedError' => '执行出错：',
			'app.localeFlagHelp' => '指定界面语言（zh/en/ja），默认跟随系统',
			'create.description' => '从模板创建全新 Flutter 项目',
			'create.orgHelp' => '组织标识（影响 bundle ID）',
			'create.nameRequired' => '错误：请指定项目名',
			'create.step1Validate' => '校验项目名与目录',
			'create.step2Render' => '用 Mason 渲染 project 模板',
			'create.step3FlutterCreate' => '执行 flutter create .',
			'create.step4CleanTest' => '清理 flutter create 生成的多余测试文件',
			'create.step5PubGet' => '执行 flutter pub get',
			'create.step6GenL10n' => '执行 flutter gen-l10n',
			'create.detailProject' => ({required Object name, required Object org}) => '  项目名: ${name}, 组织: ${org}',
			'create.detailGenerated' => ({required Object path}) => '  已生成 ${path}',
			'create.created' => '项目创建完成！',
			'create.nextSteps' => '后续步骤：',
			'create.stepNewFeature' => '  2. fluzer new my_feature （可选：添加功能模块）',
			'create.stepFlutterRun' => '  3. flutter run           （启动应用）',
			'create.removedWidgetTest' => '  已删除：test/widget_test.dart',
			'create.removeWidgetTestFailed' => ({required Object error}) => '  删除 widget_test.dart 失败：${error}',
			'create.cleanedFailedDir' => '  已清理失败目录',
			'create.cleanupFailedDir' => ({required Object error}) => '  清理失败目录失败：${error}',
			'create.nameInvalid' => '项目名不合法：必须只包含小写字母、数字和下划线，且以字母开头。',
			'create.dirExists' => ({required Object name}) => '目录 ${name} 已存在，请选择不同的项目名。',
			'create.flutterNotFound' => ({required Object error}) => '未找到 Flutter 命令。请确保 Flutter SDK 已正确安装并在 PATH 中。\n原始错误：${error}',
			'create.failed' => ({required Object error}) => '创建失败：${error}',
			'create.stepFailedWithCode' => ({required Object step, required Object code}) => '${step} 执行失败 (exit code: ${code})',
			'feature.description' => '新增功能模块',
			'feature.nameRequired' => '错误：请指定功能名',
			'feature.featureNameEmpty' => '功能名不能为空。',
			'feature.step1Load' => '加载项目配置',
			'feature.step2Template' => '解析模板加载器（本地或远程下载）',
			'feature.step3Generate' => ({required Object feature}) => '生成功能模块 ${feature}',
			'feature.step4BuildRunner' => '运行 build_runner',
			'feature.detailProjectRoot' => ({required Object path}) => '  项目根目录: ${path}',
			'feature.detailPinnedVersion' => ({required Object version}) => '  按项目模板版本 ${version} 钉死下载源',
			'feature.detailGenerated' => ({required Object feature}) => '  已生成功能模块 ${feature}',
			'feature.buildRunnerFailed' => 'build_runner 执行失败。',
			'feature.buildRunnerCompleted' => 'build_runner 执行完成。',
			'feature.generationFailed' => ({required Object error}) => '生成失败：${error}',
			'feature.successCreated' => ({required Object feature}) => '功能模块 ${feature} 已创建并注册到 DI。',
			'feature.featureExists' => ({required Object feature}) => '功能模块 ${feature} 已存在。',
			'feature.featureNameInvalid' => '功能名必须是 snake_case 且以小写字母开头，例如 user_profile。',
			'genL10n.description' => '生成国际化代码并自动创建 L10nCode 类',
			'genL10n.step1Validate' => '校验项目',
			'genL10n.step2Parse' => '解析 l10n.yaml 与 ARB 目录',
			'genL10n.step3GenL10n' => '执行 flutter gen-l10n',
			'genL10n.step4Members' => '解析本地化成员',
			'genL10n.step5Generate' => '生成 L10nCode 等文件',
			'genL10n.step6Wire' => '接线 defaultToastHandle',
			'genL10n.detailMembers' => ({required Object names}) => '  成员: ${names}',
			'genL10n.generated' => ({required Object path}) => '已生成：${path}',
			'genL10n.failed' => ({required Object error}) => 'gen-l10n 执行失败：${error}',
			'genL10n.alreadyWired' => 'defaultToastHandle 已接线，跳过（幂等）',
			'genL10n.skipHandlePatchHelp' => '跳过 defaultToastHandle 自动接线',
			'genL10n.forceHandlePatchHelp' => 'l10nCode 分支已被自定义时也强制覆盖',
			'genL10n.arbDirNotFound' => ({required Object dir}) => '未找到 ${dir} 目录，请确保项目已配置国际化。',
			'genL10n.noArbFiles' => ({required Object dir}) => '${dir} 目录中没有找到 .arb 文件。',
			'genL10n.foundArbFiles' => ({required Object count}) => '找到 ${count} 个 .arb 文件',
			'genL10n.flutterFailed' => ({required Object code}) => 'flutter gen-l10n 执行失败（退出码: ${code}）。',
			'genL10n.generatedFileNotFound' => ({required Object file}) => '未找到生成的 ${file}，请检查 l10n.yaml 中 output-dir 配置。',
			'genL10n.parsedMembers' => ({required Object total, required Object noParam, required Object withParam}) => '解析到 ${total} 个本地化成员（${noParam} 无参, ${withParam} 有参）',
			'genL10n.noMembers' => '未解析到任何本地化成员，请检查 arb 文件是否包含翻译 key。',
			'genL10n.skippedHandlePatch' => '已跳过 defaultToastHandle 接线（--skip-handle-patch）',
			'genL10n.patched' => ({required Object replaced}) => 'defaultToastHandle 已接线 L10nToastEffectHelper。\n被替换的分支原文：\n${replaced}',
			'genL10n.customSkipped' => '检测到 l10nCode 分支已被自定义，跳过接线。\n如需强制覆盖请使用 --force-handle-patch。',
			'genL10n.handleFileNotFound' => '未找到 default_toast_effect_handle.dart，跳过自动接线。\n请手动将 L10nToastEffectHelper 接入 defaultToastHandle。',
			'genL10n.branchAnchorNotFound' => '未找到 defaultToastHandle 的 l10nCode 分支锚点，跳过接线。\n请手动接入 L10nToastEffectHelper。',
			'cache.description' => '管理模板缓存',
			'cache.listDescription' => '查看已缓存的模板版本',
			'cache.cleanDescription' => '清空所有缓存的模板版本',
			'cache.noneNotExist' => '暂无缓存（缓存目录不存在）。',
			'cache.noneVersions' => '暂无缓存版本。',
			'cache.directory' => ({required Object path}) => '缓存目录：${path}',
			'cache.cleanNotExist' => '缓存目录不存在，无需清理。',
			'cache.cleanNone' => '暂无缓存版本，无需清理。',
			'cache.deleteFailed' => ({required Object name, required Object error}) => '删除失败 ${name}：${error}',
			'cache.cleared' => ({required Object count}) => '已清空 ${count} 个缓存版本。',
			'version.description' => '查看当前版本并检查更新',
			'version.checking' => '正在检查更新…',
			'version.checkUnavailable' => '（无法检查更新：包尚未发布或网络异常）',
			'version.newVersionFound' => ({required Object latest}) => '发现新版本 ${latest}，运行以下命令升级：',
			'version.alreadyLatest' => '已是最新版本',
			'version.updateHint' => ({required Object latest}) => '发现新版本 ${latest}，运行 dart pub global activate fluzer 升级',
			'template.localTemplateNotFound' => ({required Object path}) => '本地模板不存在：\n${path}',
			'template.remoteBrickNotFound' => ({required Object brickName}) => '远程模板中未找到 brick：${brickName}',
			'template.usingCachedDetail' => ({required Object path}) => '使用缓存模板：${path}',
			'template.downloadFailed' => ({required Object url}) => '模板下载失败（直连与镜像均不可达）：${url}',
			'template.zipIllegalPath' => ({required Object name}) => '模板 zip 包含非法路径：${name}',
			'template.bricksDirNotFound' => '远程模板中未找到 bricks 目录。',
			'template.usingBricksDir' => '正在使用环境变量 FLUZER_BRICKS_DIR 指定的本地模板目录。',
			'template.usingZipUrl' => '正在使用环境变量 FLUZER_TEMPLATE_ZIP_URL 指定的远程模板地址。',
			'template.registryFallback' => ({required Object error}) => '模板 registry 拉取失败，回退默认模板 zip：${error}',
			'template.registryUnavailable' => ({required Object version}) => '无法拉取模板 registry，无法定位模板版本 ${version} 的下载源。\n请确认网络连接或检查模板 registry。',
			'template.registryMissingUrl' => ({required Object version}) => '模板版本 ${version} 在 registry 中缺少有效的 url 字段。',
			'template.registryVersionNotFound' => ({required Object version}) => '当前模板 registry 未收录版本 ${version}，请确认该模板版本已发布，或升级 fluzer 到支持该模板的版本。',
			'template.registryLocateFailed' => ({required Object version, required Object error}) => '定位模板版本 ${version} 的下载源失败：${error}',
			'versionCheck.cacheLatest' => '（缓存）已是最新版本。',
			'versionCheck.pubdevLatest' => '（pub.dev）已是最新版本。',
			'versionCheck.detailCacheExpired' => ({required Object packageName}) => '版本检查缓存已过期（${packageName}），将重新获取',
			'versionCheck.detailCacheUnavailable' => ({required Object packageName}) => '版本检查缓存：${packageName} 不可用',
			'versionCheck.detailCacheHit' => ({required Object packageName, required Object latest, required Object hasUpdate}) => '版本检查缓存：${packageName} latest=${latest}, hasUpdate=${hasUpdate}',
			'versionCheck.detailUsingCached' => ({required Object packageName}) => '版本检查：使用 ${packageName} 的缓存结果',
			'versionCheck.detailCheckingPubdev' => ({required Object packageName}) => '正在 pub.dev 检查 ${packageName} 的更新…',
			'versionCheck.detailPubdevStatus' => ({required Object statusCode, required Object packageName}) => 'pub.dev 返回 ${statusCode}（${packageName}），视为不可用',
			'versionCheck.detailPubdevResult' => ({required Object packageName, required Object current, required Object latest, required Object hasUpdate}) => 'pub.dev：${packageName} current=${current}, latest=${latest}, hasUpdate=${hasUpdate}',
			'versionCheck.detailCheckFailed' => ({required Object packageName, required Object error}) => '版本检查失败（${packageName}）：${error}',
			'versionCheck.detailCacheReadFailed' => ({required Object error}) => '缓存读取失败：${error}',
			'versionCheck.detailCacheWriteFailed' => ({required Object error}) => '缓存写入失败：${error}',
			'http.allRequestsFailed' => '所有候选地址（直连 + 镜像）请求均失败。',
			'http.allDownloadsFailed' => '所有候选地址（直连 + 镜像）下载均失败。',
			'http.requestFailed' => ({required Object url, required Object error}) => '候选地址请求失败：${url} (${error})',
			'http.downloadProgress' => ({required Object bar, required Object percent}) => '下载模板: [${bar}] ${percent}%',
			'http.directSuccess' => ({required Object url}) => '直连请求成功：${url}',
			'http.mirrorSuccess' => ({required Object url}) => '镜像请求成功：${url}',
			'http.directDownloadSuccess' => ({required Object url}) => '直连下载成功：${url}',
			'http.mirrorDownloadSuccess' => ({required Object url}) => '镜像下载成功：${url}',
			'codemod.formatFailed' => ({required Object error}) => '格式化失败：${error}',
			'l10nParser.classBodyNotFound' => ({required Object name}) => '${name} 声明后未找到类体。',
			'l10nParser.classBodyUnclosed' => ({required Object name}) => '${name} 类体未闭合。',
			'l10nParser.classNotFound' => ({required Object name}) => '未找到 abstract class ${name} 声明，请检查 l10n.yaml 的 output-class 配置。',
			'l10nParser.paramParseFailed' => ({required Object member, required Object param}) => '无法解析成员 ${member} 的参数声明: "${param}"。',
			'spinner.stepLabel' => ({required Object index, required Object total}) => '步骤 ${index}/${total}',
			'spinner.stepCompleted' => ({required Object label}) => '${label} 完成',
			'spinner.stepFailed' => ({required Object label}) => '${label} 失败',
			'config.notFound' => ({required Object fileName}) => '未找到 ${fileName}，请确保在 flutter_zero 模板项目根目录下执行命令。',
			'config.rootNotMap' => ({required Object fileName}) => '${fileName} 格式错误：根节点必须是 Map。',
			'config.missingVersion' => ({required Object fileName}) => '${fileName} 中缺少有效的 version 字段。',
			'config.templateNameInvalid' => ({required Object fileName}) => '${fileName} 中 template_name 必须是 "flutter_zero"。',
			'config.missingPubspec' => '项目目录缺少 pubspec.yaml。',
			'config.missingPubspecName' => 'pubspec.yaml 中缺少有效的 name 字段。',
			'unsupportedTooNew' => ({required Object version, required Object maxSupported}) => '模板版本 ${version} 超出当前 fluzer 支持范围（最高 ${maxSupported}）。请更新 fluzer：dart pub global activate fluzer',
			'unsupportedTooOld' => ({required Object version}) => '模板版本 ${version} 过低，当前 fluzer 不支持，请升级项目模板或 fluzer。',
			_ => null,
		};
	}
}
