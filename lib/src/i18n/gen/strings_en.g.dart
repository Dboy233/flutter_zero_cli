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
class TranslationsEn with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$en app = _Translations$app$en._(_root);
	@override late final _Translations$create$en create = _Translations$create$en._(_root);
	@override late final _Translations$feature$en feature = _Translations$feature$en._(_root);
	@override late final _Translations$genL10n$en genL10n = _Translations$genL10n$en._(_root);
	@override late final _Translations$cache$en cache = _Translations$cache$en._(_root);
	@override late final _Translations$version$en version = _Translations$version$en._(_root);
	@override late final _Translations$template$en template = _Translations$template$en._(_root);
	@override late final _Translations$versionCheck$en versionCheck = _Translations$versionCheck$en._(_root);
	@override late final _Translations$http$en http = _Translations$http$en._(_root);
	@override late final _Translations$codemod$en codemod = _Translations$codemod$en._(_root);
	@override late final _Translations$l10nParser$en l10nParser = _Translations$l10nParser$en._(_root);
	@override late final _Translations$spinner$en spinner = _Translations$spinner$en._(_root);
	@override late final _Translations$config$en config = _Translations$config$en._(_root);
	@override String unsupportedTooNew({required Object version, required Object maxSupported}) => 'Template version ${version} is outside the supported range of the current fluzer (max ${maxSupported}). Please update fluzer: dart pub global activate fluzer';
	@override String unsupportedTooOld({required Object version}) => 'Template version ${version} is too old and not supported by the current fluzer. Please upgrade the template or fluzer.';
}

// Path: app
class _Translations$app$en implements Translations$app$zh {
	_Translations$app$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get description => 'Flutter MVI template project scaffolding tool';
	@override String get logFlagHelp => 'Debug mode: verbose logs, raw subprocess output and stack traces';
	@override String get unexpectedError => 'An unexpected error occurred:';
	@override String get localeFlagHelp => 'Specify the UI language (zh/en/ja); defaults to the system locale';
}

// Path: create
class _Translations$create$en implements Translations$create$zh {
	_Translations$create$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get description => 'Create a new Flutter project from the template';
	@override String get orgHelp => 'Organization identifier (affects bundle ID)';
	@override String get nameRequired => 'Error: please specify a project name';
	@override String get step1Validate => 'Validate project name and directory';
	@override String get step2Render => 'Render project template with Mason';
	@override String get step3FlutterCreate => 'Run flutter create .';
	@override String get step4CleanTest => 'Clean up extra test files from flutter create';
	@override String get step5PubGet => 'Run flutter pub get';
	@override String get step6GenL10n => 'Run flutter gen-l10n';
	@override String detailProject({required Object name, required Object org}) => '  Project name: ${name}, org: ${org}';
	@override String detailGenerated({required Object path}) => '  Generated ${path}';
	@override String get created => 'Project created successfully!';
	@override String get nextSteps => 'Next steps:';
	@override String get stepNewFeature => '  2. fluzer new my_feature (optional: add a feature module)';
	@override String get stepFlutterRun => '  3. flutter run           (launch the app)';
	@override String get removedWidgetTest => '  Removed: test/widget_test.dart';
	@override String removeWidgetTestFailed({required Object error}) => '  Failed to remove widget_test.dart: ${error}';
	@override String get cleanedFailedDir => '  Cleaned up failed directory';
	@override String cleanupFailedDir({required Object error}) => '  Failed to clean up directory: ${error}';
	@override String get nameInvalid => 'Invalid project name: must contain only lowercase letters, digits, and underscores, starting with a letter.';
	@override String dirExists({required Object name}) => 'Directory ${name} already exists. Please choose a different project name.';
	@override String flutterNotFound({required Object error}) => 'Flutter command not found. Make sure Flutter SDK is installed and in PATH.\nOriginal error: ${error}';
	@override String failed({required Object error}) => 'Creation failed: ${error}';
	@override String stepFailedWithCode({required Object step, required Object code}) => '${step} failed (exit code: ${code})';
}

// Path: feature
class _Translations$feature$en implements Translations$feature$zh {
	_Translations$feature$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get description => 'Add a new feature module';
	@override String get nameRequired => 'Error: please specify a feature name';
	@override String get featureNameEmpty => 'Feature name cannot be empty.';
	@override String get step1Load => 'load project config';
	@override String get step2Template => 'resolve template loader (local or remote download)';
	@override String step3Generate({required Object feature}) => 'generate feature module ${feature}';
	@override String get step4BuildRunner => 'run build_runner';
	@override String detailProjectRoot({required Object path}) => '  Project root: ${path}';
	@override String detailPinnedVersion({required Object version}) => '  Pinned download source to project template version ${version}';
	@override String detailGenerated({required Object feature}) => '  Generated feature module ${feature}';
	@override String get buildRunnerFailed => 'build_runner failed.';
	@override String get buildRunnerCompleted => 'build_runner completed.';
	@override String generationFailed({required Object error}) => 'Generation failed: ${error}';
	@override String successCreated({required Object feature}) => 'Feature module ${feature} has been created and registered in DI.';
	@override String featureExists({required Object feature}) => 'Feature module ${feature} already exists.';
	@override String get featureNameInvalid => 'Feature name must be snake_case and start with a lowercase letter, e.g. user_profile.';
}

// Path: genL10n
class _Translations$genL10n$en implements Translations$genL10n$zh {
	_Translations$genL10n$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get description => 'Generate localization code and create L10nCode class';
	@override String get step1Validate => 'validate project';
	@override String get step2Parse => 'parse l10n.yaml and ARB directory';
	@override String get step3GenL10n => 'run flutter gen-l10n';
	@override String get step4Members => 'parse localization members';
	@override String get step5Generate => 'generate L10nCode and other files';
	@override String get step6Wire => 'wire defaultToastHandle';
	@override String detailMembers({required Object names}) => '  Members: ${names}';
	@override String generated({required Object path}) => 'Generated: ${path}';
	@override String failed({required Object error}) => 'gen-l10n failed: ${error}';
	@override String get alreadyWired => 'Already wired, skipped (idempotent)';
	@override String get skipHandlePatchHelp => 'Skip patching defaultToastHandle';
	@override String get forceHandlePatchHelp => 'Overwrite even if the l10nCode branch was customized';
	@override String arbDirNotFound({required Object dir}) => 'Could not find ${dir} directory. Make sure l10n is configured.';
	@override String noArbFiles({required Object dir}) => 'No .arb files found in ${dir}.';
	@override String foundArbFiles({required Object count}) => 'Found ${count} .arb file(s)';
	@override String flutterFailed({required Object code}) => 'flutter gen-l10n failed (exit code: ${code}).';
	@override String generatedFileNotFound({required Object file}) => 'Generated ${file} not found. Check output-dir in l10n.yaml.';
	@override String parsedMembers({required Object total, required Object noParam, required Object withParam}) => 'Parsed ${total} localization members (${noParam} no-param, ${withParam} with-param)';
	@override String get noMembers => 'No localization members found. Check whether your arb files contain translation keys.';
	@override String get skippedHandlePatch => 'Skipped handle patch (--skip-handle-patch).';
	@override String patched({required Object replaced}) => 'Wired L10nToastEffectHelper into defaultToastHandle.\nReplaced branch:\n${replaced}';
	@override String get customSkipped => 'Customized l10nCode branch detected; skipped. Use --force-handle-patch to overwrite.';
	@override String get handleFileNotFound => 'Handle file not found; wire L10nToastEffectHelper manually.';
	@override String get branchAnchorNotFound => 'Branch anchor not found; wire L10nToastEffectHelper manually.';
}

// Path: cache
class _Translations$cache$en implements Translations$cache$zh {
	_Translations$cache$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get description => 'Manage the template cache';
	@override String get listDescription => 'List cached template versions';
	@override String get cleanDescription => 'Clear all cached template versions';
	@override String get noneNotExist => 'No cache (cache directory does not exist).';
	@override String get noneVersions => 'No cached versions.';
	@override String directory({required Object path}) => 'Cache directory: ${path}';
	@override String get cleanNotExist => 'Cache directory does not exist.';
	@override String get cleanNone => 'No cached versions to clean.';
	@override String deleteFailed({required Object name, required Object error}) => 'Failed to delete ${name}: ${error}';
	@override String cleared({required Object count}) => 'Cleared ${count} cached version(s).';
}

// Path: version
class _Translations$version$en implements Translations$version$zh {
	_Translations$version$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get description => 'Show version and check for updates';
	@override String get checking => 'Checking for updates...';
	@override String get checkUnavailable => '(Unable to check for updates: package not published or network error)';
	@override String newVersionFound({required Object latest}) => 'New version ${latest} found. Upgrade with:';
	@override String get alreadyLatest => 'Already up to date';
	@override String updateHint({required Object latest}) => 'New version ${latest} found. Upgrade with: dart pub global activate fluzer';
}

// Path: template
class _Translations$template$en implements Translations$template$zh {
	_Translations$template$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String localTemplateNotFound({required Object path}) => 'Local template not found:\n${path}';
	@override String remoteBrickNotFound({required Object brickName}) => 'Brick not found in remote templates: ${brickName}';
	@override String usingCachedDetail({required Object path}) => 'Using cached templates: ${path}';
	@override String downloadFailed({required Object url}) => 'Failed to download templates: ${url}';
	@override String zipIllegalPath({required Object name}) => 'Template zip contains an illegal path: ${name}';
	@override String get bricksDirNotFound => 'No "bricks" directory found in remote templates.';
	@override String get usingBricksDir => 'Using local template directory from env FLUZER_BRICKS_DIR.';
	@override String get usingZipUrl => 'Using remote template URL from env FLUZER_TEMPLATE_ZIP_URL.';
	@override String registryFallback({required Object error}) => 'Failed to fetch template registry, falling back to default template zip: ${error}';
	@override String registryUnavailable({required Object version}) => 'Could not fetch the template registry to locate download source for template version ${version}.\nCheck your network or the template registry.';
	@override String registryMissingUrl({required Object version}) => 'Template version ${version} has no valid "url" in the registry.';
	@override String registryVersionNotFound({required Object version}) => 'Template version ${version} was not found in the registry. Confirm it is published or upgrade fluzer.';
	@override String registryLocateFailed({required Object version, required Object error}) => 'Failed to locate download source for template version ${version}: ${error}';
	@override String zipUrlMissingVersion({required Object url}) => 'The template URL in FLUZER_TEMPLATE_ZIP_URL has no recognizable version: ${url}\nThe URL must contain a semantic version like 1.2.3 (e.g. .../1.0.0/bricks.zip).';
	@override String get templateVersionUnavailable => 'Failed to resolve the template version. Check the template registry or your network connection and try again.';
}

// Path: versionCheck
class _Translations$versionCheck$en implements Translations$versionCheck$zh {
	_Translations$versionCheck$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get cacheLatest => '(cache) Already up to date.';
	@override String get pubdevLatest => '(pub.dev) Already up to date.';
	@override String detailCacheExpired({required Object packageName}) => 'Version check cache expired for ${packageName}, will re-fetch';
	@override String detailCacheUnavailable({required Object packageName}) => 'Version check cache: ${packageName} unavailable';
	@override String detailCacheHit({required Object packageName, required Object latest, required Object hasUpdate}) => 'Version check cache: ${packageName} latest=${latest}, hasUpdate=${hasUpdate}';
	@override String detailUsingCached({required Object packageName}) => 'Version check: using cached result for ${packageName}';
	@override String detailCheckingPubdev({required Object packageName}) => 'Checking updates for ${packageName} on pub.dev...';
	@override String detailPubdevStatus({required Object statusCode, required Object packageName}) => 'pub.dev returned ${statusCode} for ${packageName}, treating as unavailable';
	@override String detailPubdevResult({required Object packageName, required Object current, required Object latest, required Object hasUpdate}) => 'pub.dev: ${packageName} current=${current}, latest=${latest}, hasUpdate=${hasUpdate}';
	@override String detailCheckFailed({required Object packageName, required Object error}) => 'Version check failed for ${packageName}: ${error}';
	@override String detailCacheReadFailed({required Object error}) => 'Cache read failed: ${error}';
	@override String detailCacheWriteFailed({required Object error}) => 'Cache write failed: ${error}';
}

// Path: http
class _Translations$http$en implements Translations$http$zh {
	_Translations$http$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get allRequestsFailed => 'All candidate addresses (direct + mirror) failed.';
	@override String get allDownloadsFailed => 'All candidate addresses (direct + mirror) failed to download.';
	@override String requestFailed({required Object url, required Object error}) => 'Candidate request failed: ${url} (${error})';
	@override String downloadProgress({required Object bar, required Object percent}) => 'Downloading template: [${bar}] ${percent}%';
	@override String directSuccess({required Object url}) => 'Direct request succeeded: ${url}';
	@override String mirrorSuccess({required Object url}) => 'Mirror request succeeded: ${url}';
	@override String directDownloadSuccess({required Object url}) => 'Direct download succeeded: ${url}';
	@override String mirrorDownloadSuccess({required Object url}) => 'Mirror download succeeded: ${url}';
}

// Path: codemod
class _Translations$codemod$en implements Translations$codemod$zh {
	_Translations$codemod$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String formatFailed({required Object error}) => 'Format failed: ${error}';
}

// Path: l10nParser
class _Translations$l10nParser$en implements Translations$l10nParser$zh {
	_Translations$l10nParser$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String classBodyNotFound({required Object name}) => 'Class body not found after ${name} declaration.';
	@override String classBodyUnclosed({required Object name}) => 'Class body of ${name} is not closed.';
	@override String classNotFound({required Object name}) => 'Declaration "abstract class ${name}" not found. Check "output-class" in l10n.yaml.';
	@override String paramParseFailed({required Object param, required Object member}) => 'Unable to parse parameter "${param}" of member "${member}".';
}

// Path: spinner
class _Translations$spinner$en implements Translations$spinner$zh {
	_Translations$spinner$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String stepLabel({required Object index, required Object total}) => 'Step ${index}/${total}';
	@override String stepCompleted({required Object label}) => '${label} completed';
	@override String stepFailed({required Object label}) => '${label} failed';
}

// Path: config
class _Translations$config$en implements Translations$config$zh {
	_Translations$config$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String notFound({required Object fileName}) => 'Could not find ${fileName}. Make sure you run this command from a flutter_zero template project root.';
	@override String rootNotMap({required Object fileName}) => 'Invalid ${fileName}: root must be a Map.';
	@override String missingVersion({required Object fileName}) => 'Missing valid "version" field in ${fileName}.';
	@override String templateNameInvalid({required Object fileName}) => 'The "template_name" field in ${fileName} must be "flutter_zero".';
	@override String get missingPubspec => 'Missing pubspec.yaml in project root.';
	@override String get missingPubspecName => 'Missing valid "name" field in pubspec.yaml.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.description' => 'Flutter MVI template project scaffolding tool',
			'app.logFlagHelp' => 'Debug mode: verbose logs, raw subprocess output and stack traces',
			'app.unexpectedError' => 'An unexpected error occurred:',
			'app.localeFlagHelp' => 'Specify the UI language (zh/en/ja); defaults to the system locale',
			'create.description' => 'Create a new Flutter project from the template',
			'create.orgHelp' => 'Organization identifier (affects bundle ID)',
			'create.nameRequired' => 'Error: please specify a project name',
			'create.step1Validate' => 'Validate project name and directory',
			'create.step2Render' => 'Render project template with Mason',
			'create.step3FlutterCreate' => 'Run flutter create .',
			'create.step4CleanTest' => 'Clean up extra test files from flutter create',
			'create.step5PubGet' => 'Run flutter pub get',
			'create.step6GenL10n' => 'Run flutter gen-l10n',
			'create.detailProject' => ({required Object name, required Object org}) => '  Project name: ${name}, org: ${org}',
			'create.detailGenerated' => ({required Object path}) => '  Generated ${path}',
			'create.created' => 'Project created successfully!',
			'create.nextSteps' => 'Next steps:',
			'create.stepNewFeature' => '  2. fluzer new my_feature (optional: add a feature module)',
			'create.stepFlutterRun' => '  3. flutter run           (launch the app)',
			'create.removedWidgetTest' => '  Removed: test/widget_test.dart',
			'create.removeWidgetTestFailed' => ({required Object error}) => '  Failed to remove widget_test.dart: ${error}',
			'create.cleanedFailedDir' => '  Cleaned up failed directory',
			'create.cleanupFailedDir' => ({required Object error}) => '  Failed to clean up directory: ${error}',
			'create.nameInvalid' => 'Invalid project name: must contain only lowercase letters, digits, and underscores, starting with a letter.',
			'create.dirExists' => ({required Object name}) => 'Directory ${name} already exists. Please choose a different project name.',
			'create.flutterNotFound' => ({required Object error}) => 'Flutter command not found. Make sure Flutter SDK is installed and in PATH.\nOriginal error: ${error}',
			'create.failed' => ({required Object error}) => 'Creation failed: ${error}',
			'create.stepFailedWithCode' => ({required Object step, required Object code}) => '${step} failed (exit code: ${code})',
			'feature.description' => 'Add a new feature module',
			'feature.nameRequired' => 'Error: please specify a feature name',
			'feature.featureNameEmpty' => 'Feature name cannot be empty.',
			'feature.step1Load' => 'load project config',
			'feature.step2Template' => 'resolve template loader (local or remote download)',
			'feature.step3Generate' => ({required Object feature}) => 'generate feature module ${feature}',
			'feature.step4BuildRunner' => 'run build_runner',
			'feature.detailProjectRoot' => ({required Object path}) => '  Project root: ${path}',
			'feature.detailPinnedVersion' => ({required Object version}) => '  Pinned download source to project template version ${version}',
			'feature.detailGenerated' => ({required Object feature}) => '  Generated feature module ${feature}',
			'feature.buildRunnerFailed' => 'build_runner failed.',
			'feature.buildRunnerCompleted' => 'build_runner completed.',
			'feature.generationFailed' => ({required Object error}) => 'Generation failed: ${error}',
			'feature.successCreated' => ({required Object feature}) => 'Feature module ${feature} has been created and registered in DI.',
			'feature.featureExists' => ({required Object feature}) => 'Feature module ${feature} already exists.',
			'feature.featureNameInvalid' => 'Feature name must be snake_case and start with a lowercase letter, e.g. user_profile.',
			'genL10n.description' => 'Generate localization code and create L10nCode class',
			'genL10n.step1Validate' => 'validate project',
			'genL10n.step2Parse' => 'parse l10n.yaml and ARB directory',
			'genL10n.step3GenL10n' => 'run flutter gen-l10n',
			'genL10n.step4Members' => 'parse localization members',
			'genL10n.step5Generate' => 'generate L10nCode and other files',
			'genL10n.step6Wire' => 'wire defaultToastHandle',
			'genL10n.detailMembers' => ({required Object names}) => '  Members: ${names}',
			'genL10n.generated' => ({required Object path}) => 'Generated: ${path}',
			'genL10n.failed' => ({required Object error}) => 'gen-l10n failed: ${error}',
			'genL10n.alreadyWired' => 'Already wired, skipped (idempotent)',
			'genL10n.skipHandlePatchHelp' => 'Skip patching defaultToastHandle',
			'genL10n.forceHandlePatchHelp' => 'Overwrite even if the l10nCode branch was customized',
			'genL10n.arbDirNotFound' => ({required Object dir}) => 'Could not find ${dir} directory. Make sure l10n is configured.',
			'genL10n.noArbFiles' => ({required Object dir}) => 'No .arb files found in ${dir}.',
			'genL10n.foundArbFiles' => ({required Object count}) => 'Found ${count} .arb file(s)',
			'genL10n.flutterFailed' => ({required Object code}) => 'flutter gen-l10n failed (exit code: ${code}).',
			'genL10n.generatedFileNotFound' => ({required Object file}) => 'Generated ${file} not found. Check output-dir in l10n.yaml.',
			'genL10n.parsedMembers' => ({required Object total, required Object noParam, required Object withParam}) => 'Parsed ${total} localization members (${noParam} no-param, ${withParam} with-param)',
			'genL10n.noMembers' => 'No localization members found. Check whether your arb files contain translation keys.',
			'genL10n.skippedHandlePatch' => 'Skipped handle patch (--skip-handle-patch).',
			'genL10n.patched' => ({required Object replaced}) => 'Wired L10nToastEffectHelper into defaultToastHandle.\nReplaced branch:\n${replaced}',
			'genL10n.customSkipped' => 'Customized l10nCode branch detected; skipped. Use --force-handle-patch to overwrite.',
			'genL10n.handleFileNotFound' => 'Handle file not found; wire L10nToastEffectHelper manually.',
			'genL10n.branchAnchorNotFound' => 'Branch anchor not found; wire L10nToastEffectHelper manually.',
			'cache.description' => 'Manage the template cache',
			'cache.listDescription' => 'List cached template versions',
			'cache.cleanDescription' => 'Clear all cached template versions',
			'cache.noneNotExist' => 'No cache (cache directory does not exist).',
			'cache.noneVersions' => 'No cached versions.',
			'cache.directory' => ({required Object path}) => 'Cache directory: ${path}',
			'cache.cleanNotExist' => 'Cache directory does not exist.',
			'cache.cleanNone' => 'No cached versions to clean.',
			'cache.deleteFailed' => ({required Object name, required Object error}) => 'Failed to delete ${name}: ${error}',
			'cache.cleared' => ({required Object count}) => 'Cleared ${count} cached version(s).',
			'version.description' => 'Show version and check for updates',
			'version.checking' => 'Checking for updates...',
			'version.checkUnavailable' => '(Unable to check for updates: package not published or network error)',
			'version.newVersionFound' => ({required Object latest}) => 'New version ${latest} found. Upgrade with:',
			'version.alreadyLatest' => 'Already up to date',
			'version.updateHint' => ({required Object latest}) => 'New version ${latest} found. Upgrade with: dart pub global activate fluzer',
			'template.localTemplateNotFound' => ({required Object path}) => 'Local template not found:\n${path}',
			'template.remoteBrickNotFound' => ({required Object brickName}) => 'Brick not found in remote templates: ${brickName}',
			'template.usingCachedDetail' => ({required Object path}) => 'Using cached templates: ${path}',
			'template.downloadFailed' => ({required Object url}) => 'Failed to download templates: ${url}',
			'template.zipIllegalPath' => ({required Object name}) => 'Template zip contains an illegal path: ${name}',
			'template.bricksDirNotFound' => 'No "bricks" directory found in remote templates.',
			'template.usingBricksDir' => 'Using local template directory from env FLUZER_BRICKS_DIR.',
			'template.usingZipUrl' => 'Using remote template URL from env FLUZER_TEMPLATE_ZIP_URL.',
			'template.registryFallback' => ({required Object error}) => 'Failed to fetch template registry, falling back to default template zip: ${error}',
			'template.registryUnavailable' => ({required Object version}) => 'Could not fetch the template registry to locate download source for template version ${version}.\nCheck your network or the template registry.',
			'template.registryMissingUrl' => ({required Object version}) => 'Template version ${version} has no valid "url" in the registry.',
			'template.registryVersionNotFound' => ({required Object version}) => 'Template version ${version} was not found in the registry. Confirm it is published or upgrade fluzer.',
			'template.registryLocateFailed' => ({required Object version, required Object error}) => 'Failed to locate download source for template version ${version}: ${error}',
			'template.zipUrlMissingVersion' => ({required Object url}) => 'The template URL in FLUZER_TEMPLATE_ZIP_URL has no recognizable version: ${url}\nThe URL must contain a semantic version like 1.2.3 (e.g. .../1.0.0/bricks.zip).',
			'template.templateVersionUnavailable' => 'Failed to resolve the template version. Check the template registry or your network connection and try again.',
			'versionCheck.cacheLatest' => '(cache) Already up to date.',
			'versionCheck.pubdevLatest' => '(pub.dev) Already up to date.',
			'versionCheck.detailCacheExpired' => ({required Object packageName}) => 'Version check cache expired for ${packageName}, will re-fetch',
			'versionCheck.detailCacheUnavailable' => ({required Object packageName}) => 'Version check cache: ${packageName} unavailable',
			'versionCheck.detailCacheHit' => ({required Object packageName, required Object latest, required Object hasUpdate}) => 'Version check cache: ${packageName} latest=${latest}, hasUpdate=${hasUpdate}',
			'versionCheck.detailUsingCached' => ({required Object packageName}) => 'Version check: using cached result for ${packageName}',
			'versionCheck.detailCheckingPubdev' => ({required Object packageName}) => 'Checking updates for ${packageName} on pub.dev...',
			'versionCheck.detailPubdevStatus' => ({required Object statusCode, required Object packageName}) => 'pub.dev returned ${statusCode} for ${packageName}, treating as unavailable',
			'versionCheck.detailPubdevResult' => ({required Object packageName, required Object current, required Object latest, required Object hasUpdate}) => 'pub.dev: ${packageName} current=${current}, latest=${latest}, hasUpdate=${hasUpdate}',
			'versionCheck.detailCheckFailed' => ({required Object packageName, required Object error}) => 'Version check failed for ${packageName}: ${error}',
			'versionCheck.detailCacheReadFailed' => ({required Object error}) => 'Cache read failed: ${error}',
			'versionCheck.detailCacheWriteFailed' => ({required Object error}) => 'Cache write failed: ${error}',
			'http.allRequestsFailed' => 'All candidate addresses (direct + mirror) failed.',
			'http.allDownloadsFailed' => 'All candidate addresses (direct + mirror) failed to download.',
			'http.requestFailed' => ({required Object url, required Object error}) => 'Candidate request failed: ${url} (${error})',
			'http.downloadProgress' => ({required Object bar, required Object percent}) => 'Downloading template: [${bar}] ${percent}%',
			'http.directSuccess' => ({required Object url}) => 'Direct request succeeded: ${url}',
			'http.mirrorSuccess' => ({required Object url}) => 'Mirror request succeeded: ${url}',
			'http.directDownloadSuccess' => ({required Object url}) => 'Direct download succeeded: ${url}',
			'http.mirrorDownloadSuccess' => ({required Object url}) => 'Mirror download succeeded: ${url}',
			'codemod.formatFailed' => ({required Object error}) => 'Format failed: ${error}',
			'l10nParser.classBodyNotFound' => ({required Object name}) => 'Class body not found after ${name} declaration.',
			'l10nParser.classBodyUnclosed' => ({required Object name}) => 'Class body of ${name} is not closed.',
			'l10nParser.classNotFound' => ({required Object name}) => 'Declaration "abstract class ${name}" not found. Check "output-class" in l10n.yaml.',
			'l10nParser.paramParseFailed' => ({required Object param, required Object member}) => 'Unable to parse parameter "${param}" of member "${member}".',
			'spinner.stepLabel' => ({required Object index, required Object total}) => 'Step ${index}/${total}',
			'spinner.stepCompleted' => ({required Object label}) => '${label} completed',
			'spinner.stepFailed' => ({required Object label}) => '${label} failed',
			'config.notFound' => ({required Object fileName}) => 'Could not find ${fileName}. Make sure you run this command from a flutter_zero template project root.',
			'config.rootNotMap' => ({required Object fileName}) => 'Invalid ${fileName}: root must be a Map.',
			'config.missingVersion' => ({required Object fileName}) => 'Missing valid "version" field in ${fileName}.',
			'config.templateNameInvalid' => ({required Object fileName}) => 'The "template_name" field in ${fileName} must be "flutter_zero".',
			'config.missingPubspec' => 'Missing pubspec.yaml in project root.',
			'config.missingPubspecName' => 'Missing valid "name" field in pubspec.yaml.',
			'unsupportedTooNew' => ({required Object version, required Object maxSupported}) => 'Template version ${version} is outside the supported range of the current fluzer (max ${maxSupported}). Please update fluzer: dart pub global activate fluzer',
			'unsupportedTooOld' => ({required Object version}) => 'Template version ${version} is too old and not supported by the current fluzer. Please upgrade the template or fluzer.',
			_ => null,
		};
	}
}
