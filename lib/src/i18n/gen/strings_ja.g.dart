///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsJa with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsJa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsJa _root = this; // ignore: unused_field

	@override 
	TranslationsJa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsJa(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$ja app = _Translations$app$ja._(_root);
	@override late final _Translations$create$ja create = _Translations$create$ja._(_root);
	@override late final _Translations$feature$ja feature = _Translations$feature$ja._(_root);
	@override late final _Translations$genL10n$ja genL10n = _Translations$genL10n$ja._(_root);
	@override late final _Translations$cache$ja cache = _Translations$cache$ja._(_root);
	@override late final _Translations$version$ja version = _Translations$version$ja._(_root);
	@override late final _Translations$template$ja template = _Translations$template$ja._(_root);
	@override late final _Translations$versionCheck$ja versionCheck = _Translations$versionCheck$ja._(_root);
	@override late final _Translations$http$ja http = _Translations$http$ja._(_root);
	@override late final _Translations$codemod$ja codemod = _Translations$codemod$ja._(_root);
	@override late final _Translations$l10nParser$ja l10nParser = _Translations$l10nParser$ja._(_root);
	@override late final _Translations$spinner$ja spinner = _Translations$spinner$ja._(_root);
	@override late final _Translations$config$ja config = _Translations$config$ja._(_root);
	@override String unsupportedTooNew({required Object version, required Object maxSupported}) => 'テンプレートバージョン ${version} は現在の fluzer の対応範囲（最大 ${maxSupported}）を超えています。fluzer を更新してください: dart pub global activate fluzer';
	@override String unsupportedTooOld({required Object version}) => 'テンプレートバージョン ${version} は古すぎて、現在の fluzer ではサポートされていません。テンプレートまたは fluzer をアップグレードしてください。';
}

// Path: app
class _Translations$app$ja implements Translations$app$zh {
	_Translations$app$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'Flutter MVI テンプレートプロジェクトのスキャフォールドツール';
	@override String get logFlagHelp => 'デバッグモード：詳細ログ・サブプロセスの生出力・スタックトレースを表示';
	@override String get unexpectedError => '予期しないエラーが発生しました：';
	@override String get localeFlagHelp => 'UI 言語を指定（zh/en/ja）、デフォルトはシステムに従う';
}

// Path: create
class _Translations$create$ja implements Translations$create$zh {
	_Translations$create$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'テンプレートから新規 Flutter プロジェクトを作成';
	@override String get orgHelp => '組織識別子（bundle ID に影響）';
	@override String get nameRequired => 'エラー：プロジェクト名を指定してください';
	@override String get step1Validate => 'プロジェクト名とディレクトリの検証';
	@override String get step2Render => 'Mason でプロジェクトテンプレートをレンダリング';
	@override String get step3FlutterCreate => 'flutter create . を実行';
	@override String get step4CleanTest => 'flutter create が生成した不要なテストファイルを削除';
	@override String get step5PubGet => 'flutter pub get を実行';
	@override String get step6GenL10n => 'flutter gen-l10n を実行';
	@override String detailProject({required Object name, required Object org}) => '  プロジェクト名: ${name}, 組織: ${org}';
	@override String detailGenerated({required Object path}) => '  生成済み: ${path}';
	@override String get created => 'プロジェクトの作成が完了しました！';
	@override String get nextSteps => '次のステップ：';
	@override String get stepNewFeature => '  2. fluzer new my_feature （任意：機能モジュールを追加）';
	@override String get stepFlutterRun => '  3. flutter run           （アプリを起動）';
	@override String get removedWidgetTest => '  削除済み: test/widget_test.dart';
	@override String removeWidgetTestFailed({required Object error}) => '  widget_test.dart の削除に失敗: ${error}';
	@override String get cleanedFailedDir => '  失敗したディレクトリを削除しました';
	@override String cleanupFailedDir({required Object error}) => '  ディレクトリの削除に失敗: ${error}';
	@override String get nameInvalid => 'プロジェクト名が不正です：小文字・数字・アンダースコアのみ、かつ英字で始まる必要があります。';
	@override String dirExists({required Object name}) => 'ディレクトリ ${name} は既に存在します。別のプロジェクト名を指定してください。';
	@override String flutterNotFound({required Object error}) => 'Flutter コマンドが見つかりません。Flutter SDK が正しくインストールされ PATH に含まれているか確認してください。\n元のエラー: ${error}';
	@override String failed({required Object error}) => '作成失敗: ${error}';
	@override String stepFailedWithCode({required Object step, required Object code}) => '${step} が失敗しました (終了コード: ${code})';
}

// Path: feature
class _Translations$feature$ja implements Translations$feature$zh {
	_Translations$feature$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => '新規機能モジュールを追加';
	@override String get nameRequired => 'エラー：機能名を指定してください';
	@override String get featureNameEmpty => '機能名は空にできません。';
	@override String get buildRunnerHelp => '生成後に build_runner を実行するか';
	@override String get step1Load => 'プロジェクト設定を読み込み';
	@override String get step2Template => 'テンプレートローダーを解決（ローカルまたはリモート）';
	@override String step3Generate({required Object feature}) => '機能モジュール ${feature} を生成';
	@override String get step4BuildRunner => 'build_runner を実行';
	@override String detailProjectRoot({required Object path}) => '  プロジェクトルート: ${path}';
	@override String detailPinnedVersion({required Object version}) => '  プロジェクトテンプレートバージョン ${version} にダウンロード元を固定';
	@override String detailGenerated({required Object feature}) => '  機能モジュール ${feature} を生成しました';
	@override String get buildRunnerFailed => 'build_runner の実行に失敗しました。';
	@override String get buildRunnerCompleted => 'build_runner の実行が完了しました。';
	@override String generationFailed({required Object error}) => '生成失敗: ${error}';
	@override String successCreated({required Object feature}) => '機能モジュール ${feature} を作成し、DI に登録しました。';
	@override String get skipBuildRunner => 'build_runner をスキップしました。手動で実行：\n  dart run build_runner build';
	@override String featureExists({required Object feature}) => '機能モジュール ${feature} は既に存在します。';
	@override String get featureNameInvalid => '機能名は snake_case で、かつ小文字の英字で始まる必要があります（例: user_profile）。';
}

// Path: genL10n
class _Translations$genL10n$ja implements Translations$genL10n$zh {
	_Translations$genL10n$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => '国際化コードを生成し L10nCode クラスを自動作成';
	@override String get step1Validate => 'プロジェクトを検証';
	@override String get step2Parse => 'l10n.yaml と ARB ディレクトリを解析';
	@override String get step3GenL10n => 'flutter gen-l10n を実行';
	@override String get step4Members => 'ローカライゼーションメンバーを解析';
	@override String get step5Generate => 'L10nCode などのファイルを生成';
	@override String get step6Wire => 'defaultToastHandle を接続';
	@override String detailMembers({required Object names}) => '  メンバー: ${names}';
	@override String generated({required Object path}) => '生成済み: ${path}';
	@override String failed({required Object error}) => 'gen-l10n 失敗: ${error}';
	@override String get alreadyWired => '既に接続済み、スキップ（べき等）';
	@override String get skipHandlePatchHelp => 'defaultToastHandle の自動接続をスキップ';
	@override String get forceHandlePatchHelp => 'l10nCode ブランチがカスタマイズされていても上書きする';
	@override String arbDirNotFound({required Object dir}) => '${dir} ディレクトリが見つかりません。プロジェクトで国際化が設定されているか確認してください。';
	@override String noArbFiles({required Object dir}) => '${dir} に .arb ファイルが見つかりません。';
	@override String foundArbFiles({required Object count}) => '${count} 個の .arb ファイルが見つかりました';
	@override String flutterFailed({required Object code}) => 'flutter gen-l10n が失敗しました（終了コード: ${code}）。';
	@override String generatedFileNotFound({required Object file}) => '生成された ${file} が見つかりません。l10n.yaml の output-dir を確認してください。';
	@override String parsedMembers({required Object total, required Object noParam, required Object withParam}) => '${total} 個のローカライゼーションメンバーを解析（${noParam} 個は引数なし, ${withParam} 個は引数あり）';
	@override String get noMembers => 'ローカライゼーションメンバーが見つかりません。arb ファイルに翻訳キーが含まれているか確認してください。';
	@override String get skippedHandlePatch => 'defaultToastHandle の接続をスキップしました（--skip-handle-patch）。';
	@override String patched({required Object replaced}) => 'defaultToastHandle に L10nToastEffectHelper を接続しました。\n置換されたブランチ:\n${replaced}';
	@override String get customSkipped => 'l10nCode ブランチがカスタマイズされていることを検出、スキップしました。上書きするには --force-handle-patch を使用してください。';
	@override String get handleFileNotFound => 'default_toast_effect_handle.dart が見つかりません。L10nToastEffectHelper を手動で接続してください。';
	@override String get branchAnchorNotFound => 'defaultToastHandle の l10nCode ブランチのアンカーが見つかりません。L10nToastEffectHelper を手動で接続してください。';
}

// Path: cache
class _Translations$cache$ja implements Translations$cache$zh {
	_Translations$cache$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'テンプレートキャッシュを管理';
	@override String get listDescription => 'キャッシュ済みのテンプレートバージョンを表示';
	@override String get cleanDescription => 'すべてのキャッシュ済みテンプレートバージョンを削除';
	@override String get noneNotExist => 'キャッシュはありません（キャッシュディレクトリが存在しません）。';
	@override String get noneVersions => 'キャッシュされたバージョンはありません。';
	@override String directory({required Object path}) => 'キャッシュディレクトリ: ${path}';
	@override String get cleanNotExist => 'キャッシュディレクトリは存在しません。';
	@override String get cleanNone => '削除するキャッシュバージョンはありません。';
	@override String deleteFailed({required Object name, required Object error}) => '${name} の削除に失敗: ${error}';
	@override String cleared({required Object count}) => '${count} 個のキャッシュバージョンを削除しました。';
}

// Path: version
class _Translations$version$ja implements Translations$version$zh {
	_Translations$version$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'バージョンを表示し更新を確認';
	@override String get checking => '更新を確認しています…';
	@override String get checkUnavailable => '（更新を確認できません：パッケージが未公開またはネットワークエラー）';
	@override String newVersionFound({required Object latest}) => '新しいバージョン ${latest} が見つかりました。以下でアップグレード：';
	@override String get alreadyLatest => '最新バージョンです';
	@override String updateHint({required Object latest}) => '新しいバージョン ${latest} が見つかりました。dart pub global activate fluzer でアップグレード';
}

// Path: template
class _Translations$template$ja implements Translations$template$zh {
	_Translations$template$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String localTemplateNotFound({required Object path}) => 'ローカルテンプレートが見つかりません：\n${path}';
	@override String remoteBrickNotFound({required Object brickName}) => 'リモートテンプレートに brick が見つかりません：${brickName}';
	@override String usingCachedDetail({required Object path}) => 'キャッシュ済みテンプレートを使用: ${path}';
	@override String downloadFailed({required Object url}) => 'テンプレートのダウンロードに失敗しました（直接接続とミラー両方不可）：${url}';
	@override String zipIllegalPath({required Object name}) => 'テンプレート zip に不正なパスが含まれています：${name}';
	@override String get bricksDirNotFound => 'リモートテンプレートに bricks ディレクトリが見つかりません。';
	@override String get usingBricksDir => '環境変数 FLUZER_BRICKS_DIR が指定するローカルテンプレートディレクトリを使用しています。';
	@override String get usingZipUrl => '環境変数 FLUZER_TEMPLATE_ZIP_URL が指定するリモートテンプレートアドレスを使用しています。';
	@override String registryFallback({required Object error}) => 'テンプレート registry の取得に失敗、デフォルトテンプレート zip にフォールバック：${error}';
	@override String registryUnavailable({required Object version}) => 'テンプレート registry を取得できず、テンプレートバージョン ${version} のダウンロード元を特定できません。\nネットワークまたはテンプレート registry を確認してください。';
	@override String registryMissingUrl({required Object version}) => 'テンプレートバージョン ${version} は registry に有効な url フィールドがありません。';
	@override String registryVersionNotFound({required Object version}) => '現在のテンプレート registry にバージョン ${version} が登録されていません。そのテンプレートバージョンが公開されているか、またはこのテンプレートをサポートする fluzer にアップグレードしてください。';
	@override String registryLocateFailed({required Object version, required Object error}) => 'テンプレートバージョン ${version} のダウンロード元の特定に失敗：${error}';
}

// Path: versionCheck
class _Translations$versionCheck$ja implements Translations$versionCheck$zh {
	_Translations$versionCheck$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get cacheLatest => '（キャッシュ）最新バージョンです。';
	@override String get pubdevLatest => '（pub.dev）最新バージョンです。';
	@override String detailCacheExpired({required Object packageName}) => 'バージョン確認キャッシュの有効期限切れ（${packageName}）、再取得します';
	@override String detailCacheUnavailable({required Object packageName}) => 'バージョン確認キャッシュ：${packageName} は利用不可';
	@override String detailCacheHit({required Object packageName, required Object latest, required Object hasUpdate}) => 'バージョン確認キャッシュ：${packageName} latest=${latest}, hasUpdate=${hasUpdate}';
	@override String detailUsingCached({required Object packageName}) => 'バージョン確認：${packageName} のキャッシュ結果を使用';
	@override String detailCheckingPubdev({required Object packageName}) => 'pub.dev で ${packageName} の更新を確認中…';
	@override String detailPubdevStatus({required Object statusCode, required Object packageName}) => 'pub.dev が ${statusCode} を返しました（${packageName}）、利用不可と扱います';
	@override String detailPubdevResult({required Object packageName, required Object current, required Object latest, required Object hasUpdate}) => 'pub.dev：${packageName} current=${current}, latest=${latest}, hasUpdate=${hasUpdate}';
	@override String detailCheckFailed({required Object packageName, required Object error}) => 'バージョン確認失敗（${packageName}）：${error}';
	@override String detailCacheReadFailed({required Object error}) => 'キャッシュ読み込み失敗：${error}';
	@override String detailCacheWriteFailed({required Object error}) => 'キャッシュ書き込み失敗：${error}';
}

// Path: http
class _Translations$http$ja implements Translations$http$zh {
	_Translations$http$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get allRequestsFailed => 'すべての候補アドレス（直接 + ミラー）のリクエストが失敗しました。';
	@override String get allDownloadsFailed => 'すべての候補アドレス（直接 + ミラー）のダウンロードが失敗しました。';
	@override String requestFailed({required Object url, required Object error}) => '候補アドレスのリクエストに失敗: ${url} (${error})';
	@override String downloadProgress({required Object bar, required Object percent}) => 'テンプレートをダウンロード中: [${bar}] ${percent}%';
	@override String directSuccess({required Object url}) => '直接リクエスト成功: ${url}';
	@override String mirrorSuccess({required Object url}) => 'ミラーリクエスト成功: ${url}';
	@override String directDownloadSuccess({required Object url}) => '直接ダウンロード成功: ${url}';
	@override String mirrorDownloadSuccess({required Object url}) => 'ミラーダウンロード成功: ${url}';
}

// Path: codemod
class _Translations$codemod$ja implements Translations$codemod$zh {
	_Translations$codemod$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String formatFailed({required Object error}) => 'フォーマット失敗: ${error}';
}

// Path: l10nParser
class _Translations$l10nParser$ja implements Translations$l10nParser$zh {
	_Translations$l10nParser$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String classBodyNotFound({required Object name}) => '${name} の宣言後にクラス本体が見つかりません。';
	@override String classBodyUnclosed({required Object name}) => '${name} のクラス本体が閉じられていません。';
	@override String classNotFound({required Object name}) => 'abstract class ${name} の宣言が見つかりません。l10n.yaml の output-class 設定を確認してください。';
	@override String paramParseFailed({required Object member, required Object param}) => 'メンバー ${member} のパラメータ宣言を解析できません: "${param}"。';
}

// Path: spinner
class _Translations$spinner$ja implements Translations$spinner$zh {
	_Translations$spinner$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String stepLabel({required Object index, required Object total}) => 'ステップ ${index}/${total}';
	@override String stepCompleted({required Object label}) => '${label} 完了';
	@override String stepFailed({required Object label}) => '${label} 失敗';
}

// Path: config
class _Translations$config$ja implements Translations$config$zh {
	_Translations$config$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String notFound({required Object fileName}) => '${fileName} が見つかりません。flutter_zero テンプレートプロジェクトのルートディレクトリからコマンドを実行してください。';
	@override String rootNotMap({required Object fileName}) => '${fileName} の形式が不正です：ルートノードは Map である必要があります。';
	@override String missingVersion({required Object fileName}) => '${fileName} に有効な version フィールドがありません。';
	@override String templateNameInvalid({required Object fileName}) => '${fileName} の template_name は "flutter_zero" である必要があります。';
	@override String get missingPubspec => 'プロジェクトルートに pubspec.yaml がありません。';
	@override String get missingPubspecName => 'pubspec.yaml に有効な name フィールドがありません。';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.description' => 'Flutter MVI テンプレートプロジェクトのスキャフォールドツール',
			'app.logFlagHelp' => 'デバッグモード：詳細ログ・サブプロセスの生出力・スタックトレースを表示',
			'app.unexpectedError' => '予期しないエラーが発生しました：',
			'app.localeFlagHelp' => 'UI 言語を指定（zh/en/ja）、デフォルトはシステムに従う',
			'create.description' => 'テンプレートから新規 Flutter プロジェクトを作成',
			'create.orgHelp' => '組織識別子（bundle ID に影響）',
			'create.nameRequired' => 'エラー：プロジェクト名を指定してください',
			'create.step1Validate' => 'プロジェクト名とディレクトリの検証',
			'create.step2Render' => 'Mason でプロジェクトテンプレートをレンダリング',
			'create.step3FlutterCreate' => 'flutter create . を実行',
			'create.step4CleanTest' => 'flutter create が生成した不要なテストファイルを削除',
			'create.step5PubGet' => 'flutter pub get を実行',
			'create.step6GenL10n' => 'flutter gen-l10n を実行',
			'create.detailProject' => ({required Object name, required Object org}) => '  プロジェクト名: ${name}, 組織: ${org}',
			'create.detailGenerated' => ({required Object path}) => '  生成済み: ${path}',
			'create.created' => 'プロジェクトの作成が完了しました！',
			'create.nextSteps' => '次のステップ：',
			'create.stepNewFeature' => '  2. fluzer new my_feature （任意：機能モジュールを追加）',
			'create.stepFlutterRun' => '  3. flutter run           （アプリを起動）',
			'create.removedWidgetTest' => '  削除済み: test/widget_test.dart',
			'create.removeWidgetTestFailed' => ({required Object error}) => '  widget_test.dart の削除に失敗: ${error}',
			'create.cleanedFailedDir' => '  失敗したディレクトリを削除しました',
			'create.cleanupFailedDir' => ({required Object error}) => '  ディレクトリの削除に失敗: ${error}',
			'create.nameInvalid' => 'プロジェクト名が不正です：小文字・数字・アンダースコアのみ、かつ英字で始まる必要があります。',
			'create.dirExists' => ({required Object name}) => 'ディレクトリ ${name} は既に存在します。別のプロジェクト名を指定してください。',
			'create.flutterNotFound' => ({required Object error}) => 'Flutter コマンドが見つかりません。Flutter SDK が正しくインストールされ PATH に含まれているか確認してください。\n元のエラー: ${error}',
			'create.failed' => ({required Object error}) => '作成失敗: ${error}',
			'create.stepFailedWithCode' => ({required Object step, required Object code}) => '${step} が失敗しました (終了コード: ${code})',
			'feature.description' => '新規機能モジュールを追加',
			'feature.nameRequired' => 'エラー：機能名を指定してください',
			'feature.featureNameEmpty' => '機能名は空にできません。',
			'feature.buildRunnerHelp' => '生成後に build_runner を実行するか',
			'feature.step1Load' => 'プロジェクト設定を読み込み',
			'feature.step2Template' => 'テンプレートローダーを解決（ローカルまたはリモート）',
			'feature.step3Generate' => ({required Object feature}) => '機能モジュール ${feature} を生成',
			'feature.step4BuildRunner' => 'build_runner を実行',
			'feature.detailProjectRoot' => ({required Object path}) => '  プロジェクトルート: ${path}',
			'feature.detailPinnedVersion' => ({required Object version}) => '  プロジェクトテンプレートバージョン ${version} にダウンロード元を固定',
			'feature.detailGenerated' => ({required Object feature}) => '  機能モジュール ${feature} を生成しました',
			'feature.buildRunnerFailed' => 'build_runner の実行に失敗しました。',
			'feature.buildRunnerCompleted' => 'build_runner の実行が完了しました。',
			'feature.generationFailed' => ({required Object error}) => '生成失敗: ${error}',
			'feature.successCreated' => ({required Object feature}) => '機能モジュール ${feature} を作成し、DI に登録しました。',
			'feature.skipBuildRunner' => 'build_runner をスキップしました。手動で実行：\n  dart run build_runner build',
			'feature.featureExists' => ({required Object feature}) => '機能モジュール ${feature} は既に存在します。',
			'feature.featureNameInvalid' => '機能名は snake_case で、かつ小文字の英字で始まる必要があります（例: user_profile）。',
			'genL10n.description' => '国際化コードを生成し L10nCode クラスを自動作成',
			'genL10n.step1Validate' => 'プロジェクトを検証',
			'genL10n.step2Parse' => 'l10n.yaml と ARB ディレクトリを解析',
			'genL10n.step3GenL10n' => 'flutter gen-l10n を実行',
			'genL10n.step4Members' => 'ローカライゼーションメンバーを解析',
			'genL10n.step5Generate' => 'L10nCode などのファイルを生成',
			'genL10n.step6Wire' => 'defaultToastHandle を接続',
			'genL10n.detailMembers' => ({required Object names}) => '  メンバー: ${names}',
			'genL10n.generated' => ({required Object path}) => '生成済み: ${path}',
			'genL10n.failed' => ({required Object error}) => 'gen-l10n 失敗: ${error}',
			'genL10n.alreadyWired' => '既に接続済み、スキップ（べき等）',
			'genL10n.skipHandlePatchHelp' => 'defaultToastHandle の自動接続をスキップ',
			'genL10n.forceHandlePatchHelp' => 'l10nCode ブランチがカスタマイズされていても上書きする',
			'genL10n.arbDirNotFound' => ({required Object dir}) => '${dir} ディレクトリが見つかりません。プロジェクトで国際化が設定されているか確認してください。',
			'genL10n.noArbFiles' => ({required Object dir}) => '${dir} に .arb ファイルが見つかりません。',
			'genL10n.foundArbFiles' => ({required Object count}) => '${count} 個の .arb ファイルが見つかりました',
			'genL10n.flutterFailed' => ({required Object code}) => 'flutter gen-l10n が失敗しました（終了コード: ${code}）。',
			'genL10n.generatedFileNotFound' => ({required Object file}) => '生成された ${file} が見つかりません。l10n.yaml の output-dir を確認してください。',
			'genL10n.parsedMembers' => ({required Object total, required Object noParam, required Object withParam}) => '${total} 個のローカライゼーションメンバーを解析（${noParam} 個は引数なし, ${withParam} 個は引数あり）',
			'genL10n.noMembers' => 'ローカライゼーションメンバーが見つかりません。arb ファイルに翻訳キーが含まれているか確認してください。',
			'genL10n.skippedHandlePatch' => 'defaultToastHandle の接続をスキップしました（--skip-handle-patch）。',
			'genL10n.patched' => ({required Object replaced}) => 'defaultToastHandle に L10nToastEffectHelper を接続しました。\n置換されたブランチ:\n${replaced}',
			'genL10n.customSkipped' => 'l10nCode ブランチがカスタマイズされていることを検出、スキップしました。上書きするには --force-handle-patch を使用してください。',
			'genL10n.handleFileNotFound' => 'default_toast_effect_handle.dart が見つかりません。L10nToastEffectHelper を手動で接続してください。',
			'genL10n.branchAnchorNotFound' => 'defaultToastHandle の l10nCode ブランチのアンカーが見つかりません。L10nToastEffectHelper を手動で接続してください。',
			'cache.description' => 'テンプレートキャッシュを管理',
			'cache.listDescription' => 'キャッシュ済みのテンプレートバージョンを表示',
			'cache.cleanDescription' => 'すべてのキャッシュ済みテンプレートバージョンを削除',
			'cache.noneNotExist' => 'キャッシュはありません（キャッシュディレクトリが存在しません）。',
			'cache.noneVersions' => 'キャッシュされたバージョンはありません。',
			'cache.directory' => ({required Object path}) => 'キャッシュディレクトリ: ${path}',
			'cache.cleanNotExist' => 'キャッシュディレクトリは存在しません。',
			'cache.cleanNone' => '削除するキャッシュバージョンはありません。',
			'cache.deleteFailed' => ({required Object name, required Object error}) => '${name} の削除に失敗: ${error}',
			'cache.cleared' => ({required Object count}) => '${count} 個のキャッシュバージョンを削除しました。',
			'version.description' => 'バージョンを表示し更新を確認',
			'version.checking' => '更新を確認しています…',
			'version.checkUnavailable' => '（更新を確認できません：パッケージが未公開またはネットワークエラー）',
			'version.newVersionFound' => ({required Object latest}) => '新しいバージョン ${latest} が見つかりました。以下でアップグレード：',
			'version.alreadyLatest' => '最新バージョンです',
			'version.updateHint' => ({required Object latest}) => '新しいバージョン ${latest} が見つかりました。dart pub global activate fluzer でアップグレード',
			'template.localTemplateNotFound' => ({required Object path}) => 'ローカルテンプレートが見つかりません：\n${path}',
			'template.remoteBrickNotFound' => ({required Object brickName}) => 'リモートテンプレートに brick が見つかりません：${brickName}',
			'template.usingCachedDetail' => ({required Object path}) => 'キャッシュ済みテンプレートを使用: ${path}',
			'template.downloadFailed' => ({required Object url}) => 'テンプレートのダウンロードに失敗しました（直接接続とミラー両方不可）：${url}',
			'template.zipIllegalPath' => ({required Object name}) => 'テンプレート zip に不正なパスが含まれています：${name}',
			'template.bricksDirNotFound' => 'リモートテンプレートに bricks ディレクトリが見つかりません。',
			'template.usingBricksDir' => '環境変数 FLUZER_BRICKS_DIR が指定するローカルテンプレートディレクトリを使用しています。',
			'template.usingZipUrl' => '環境変数 FLUZER_TEMPLATE_ZIP_URL が指定するリモートテンプレートアドレスを使用しています。',
			'template.registryFallback' => ({required Object error}) => 'テンプレート registry の取得に失敗、デフォルトテンプレート zip にフォールバック：${error}',
			'template.registryUnavailable' => ({required Object version}) => 'テンプレート registry を取得できず、テンプレートバージョン ${version} のダウンロード元を特定できません。\nネットワークまたはテンプレート registry を確認してください。',
			'template.registryMissingUrl' => ({required Object version}) => 'テンプレートバージョン ${version} は registry に有効な url フィールドがありません。',
			'template.registryVersionNotFound' => ({required Object version}) => '現在のテンプレート registry にバージョン ${version} が登録されていません。そのテンプレートバージョンが公開されているか、またはこのテンプレートをサポートする fluzer にアップグレードしてください。',
			'template.registryLocateFailed' => ({required Object version, required Object error}) => 'テンプレートバージョン ${version} のダウンロード元の特定に失敗：${error}',
			'versionCheck.cacheLatest' => '（キャッシュ）最新バージョンです。',
			'versionCheck.pubdevLatest' => '（pub.dev）最新バージョンです。',
			'versionCheck.detailCacheExpired' => ({required Object packageName}) => 'バージョン確認キャッシュの有効期限切れ（${packageName}）、再取得します',
			'versionCheck.detailCacheUnavailable' => ({required Object packageName}) => 'バージョン確認キャッシュ：${packageName} は利用不可',
			'versionCheck.detailCacheHit' => ({required Object packageName, required Object latest, required Object hasUpdate}) => 'バージョン確認キャッシュ：${packageName} latest=${latest}, hasUpdate=${hasUpdate}',
			'versionCheck.detailUsingCached' => ({required Object packageName}) => 'バージョン確認：${packageName} のキャッシュ結果を使用',
			'versionCheck.detailCheckingPubdev' => ({required Object packageName}) => 'pub.dev で ${packageName} の更新を確認中…',
			'versionCheck.detailPubdevStatus' => ({required Object statusCode, required Object packageName}) => 'pub.dev が ${statusCode} を返しました（${packageName}）、利用不可と扱います',
			'versionCheck.detailPubdevResult' => ({required Object packageName, required Object current, required Object latest, required Object hasUpdate}) => 'pub.dev：${packageName} current=${current}, latest=${latest}, hasUpdate=${hasUpdate}',
			'versionCheck.detailCheckFailed' => ({required Object packageName, required Object error}) => 'バージョン確認失敗（${packageName}）：${error}',
			'versionCheck.detailCacheReadFailed' => ({required Object error}) => 'キャッシュ読み込み失敗：${error}',
			'versionCheck.detailCacheWriteFailed' => ({required Object error}) => 'キャッシュ書き込み失敗：${error}',
			'http.allRequestsFailed' => 'すべての候補アドレス（直接 + ミラー）のリクエストが失敗しました。',
			'http.allDownloadsFailed' => 'すべての候補アドレス（直接 + ミラー）のダウンロードが失敗しました。',
			'http.requestFailed' => ({required Object url, required Object error}) => '候補アドレスのリクエストに失敗: ${url} (${error})',
			'http.downloadProgress' => ({required Object bar, required Object percent}) => 'テンプレートをダウンロード中: [${bar}] ${percent}%',
			'http.directSuccess' => ({required Object url}) => '直接リクエスト成功: ${url}',
			'http.mirrorSuccess' => ({required Object url}) => 'ミラーリクエスト成功: ${url}',
			'http.directDownloadSuccess' => ({required Object url}) => '直接ダウンロード成功: ${url}',
			'http.mirrorDownloadSuccess' => ({required Object url}) => 'ミラーダウンロード成功: ${url}',
			'codemod.formatFailed' => ({required Object error}) => 'フォーマット失敗: ${error}',
			'l10nParser.classBodyNotFound' => ({required Object name}) => '${name} の宣言後にクラス本体が見つかりません。',
			'l10nParser.classBodyUnclosed' => ({required Object name}) => '${name} のクラス本体が閉じられていません。',
			'l10nParser.classNotFound' => ({required Object name}) => 'abstract class ${name} の宣言が見つかりません。l10n.yaml の output-class 設定を確認してください。',
			'l10nParser.paramParseFailed' => ({required Object member, required Object param}) => 'メンバー ${member} のパラメータ宣言を解析できません: "${param}"。',
			'spinner.stepLabel' => ({required Object index, required Object total}) => 'ステップ ${index}/${total}',
			'spinner.stepCompleted' => ({required Object label}) => '${label} 完了',
			'spinner.stepFailed' => ({required Object label}) => '${label} 失敗',
			'config.notFound' => ({required Object fileName}) => '${fileName} が見つかりません。flutter_zero テンプレートプロジェクトのルートディレクトリからコマンドを実行してください。',
			'config.rootNotMap' => ({required Object fileName}) => '${fileName} の形式が不正です：ルートノードは Map である必要があります。',
			'config.missingVersion' => ({required Object fileName}) => '${fileName} に有効な version フィールドがありません。',
			'config.templateNameInvalid' => ({required Object fileName}) => '${fileName} の template_name は "flutter_zero" である必要があります。',
			'config.missingPubspec' => 'プロジェクトルートに pubspec.yaml がありません。',
			'config.missingPubspecName' => 'pubspec.yaml に有効な name フィールドがありません。',
			'unsupportedTooNew' => ({required Object version, required Object maxSupported}) => 'テンプレートバージョン ${version} は現在の fluzer の対応範囲（最大 ${maxSupported}）を超えています。fluzer を更新してください: dart pub global activate fluzer',
			'unsupportedTooOld' => ({required Object version}) => 'テンプレートバージョン ${version} は古すぎて、現在の fluzer ではサポートされていません。テンプレートまたは fluzer をアップグレードしてください。',
			_ => null,
		};
	}
}
