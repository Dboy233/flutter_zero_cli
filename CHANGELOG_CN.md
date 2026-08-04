## 1.1.2

### 新增

- 模板下载采用并发镜像竞速 HTTP 客户端：直连 URL 与配置的 GitHub 镜像前缀并发请求，首个成功响应胜出、其余取消，消除了此前「先等直连超时再回退镜像」的串行等待。

### 变更

- 日志系统重构：移除 `LogPolicy` 封装，可见性完全由 `Logger.level` 驱动。每个命令步骤都用 `runWithSpinner` 包裹以提供实时进度提示；`--log` 模式下不显示 spinner，改为实时透传子命令输出。
- 下载进度条仅在 `--log`（verbose）模式下显示；默认模式由步骤 spinner 体现进度，避免重复或重叠输出。
- 内部重构（无用户可见行为变化）：`TemplateSourceResolver` 成为唯一公开的模板来源 API（移除顶层辅助函数）；`gen-l10n` 参数类型的 switch 替换为可扩展的 `L10nParamType` 注册表（符合开闭原则）；配置 / 版本 / 工具包结构调整以消除循环依赖。

### 修复

- 修复 Windows CI 崩溃：测试在 `tearDown` 中将全局 `Directory.current` 恢复到一个已被并行测试删除的临时目录，导致 `NewCommand` 完整流程测试失败。命令与 CLI 入口现在接受显式的 `workingDirectory`，不再修改全局 cwd。
- 提升 Linux / macOS / Windows CI 矩阵上的跨平台测试稳定性：`Platform.resolvedExecutable` 替换 `'dart'` 字符串命令，`path.join` 替换硬编码路径分隔符，临时目录删除在 Windows 文件锁定时增加重试。

## 1.1.1

### 新增

- `new` 与 `gen-l10n` 命令新增**版本兼容性门禁**：CLI 在执行前会依据项目模板所需的最低版本（项目 `flutter_zero_config.yaml` 中的 `minCliVersion` 字段）校验当前运行的 CLI 版本。版本不兼容时拒绝执行并给出明确的升级提示。可通过 `--skip-version-check` 开关绕过门禁（仅用于调试）。
- `new` 命令现在在解析下载来源时，会按项目配置中声明的模板版本（`flutter_zero_config.yaml` 的 `version`）精确钉死下载源，而不再总是选取最新的 CLI 兼容模板。
- `ProjectConfig` 新增 `minCliVersion` 字段与 `isCliCompatible(currentCliVersion)` 辅助方法。未写入该字段的老项目默认视为 `"0.0.0"`（可被任意 CLI 版本接受）。

### 修复

- `SemanticVersion` 缺少值相等比较（`==` / `hashCode`），导致版本比较不稳定；现已实现值相等。

## 1.1.0

### 新增

- **`fluzer gen-l10n`**：运行 `flutter gen-l10n` 并自动生成类型安全的国际化访问层。
  - 解析 `l10n.yaml`（`arb-dir` / `output-dir` / `output-class`，含回退探测）以及生成的 `AppLocalizations` 抽象类（基于大括号计数的类体扫描器）。
  - 生成 `l10n_code.dart`：包含类型化工厂构造函数的 `L10nCode` 值对象，对称的 `toString`/`parse` 序列化，`==`/`hashCode`，以及不可变的 `Map<String, String>` 参数。
  - 生成 `l10n_code_ext.dart`：`typeS()`/`typeE()`/`typeI()`/`typeW()` Toast 类型标记，以及用于从 BLoC 直接发出 effect 的 `toToastEffect()` 快捷方法。
  - 生成 `l10n_toast_effect_helper.dart`：覆盖每个 ARB key 的集中式 switch 分发器，按声明类型（`int.tryParse`、`DateTime.tryParse` 等）反序列化参数。
  - 通过基于 AST 的补丁将 `L10nToastEffectHelper` 自动接线到 `defaultToastHandle`，支持三态检测（模板态 / 已接线 / 已自定义），重复运行幂等。开关：`--skip-handle-patch`、`--force-handle-patch`。
  - 生成的源码使用 `dart_style` 格式化，并标注 CLI 版本。

### 修复

- ARB 中声明的占位符类型（如 `"type": "int"`）不再破坏生成：参数类型端到端保留，而非硬编码为 `Object`；无法解析的参数声明现在会以 `FormatException` 明确失败，而非被静默丢弃。
- `L10nCode.parse` 能容忍畸形输入（如不完整的百分号编码），而不再在 effect 链内部抛异常。
- 命名为 `code`/`parameters` 的工厂参数被重命名（`codeParam`/`parametersParam`）以避免遮蔽类成员；Map 的键保持不变。

## 1.0.1

### 变更

- 将 `README.md` 切换为英文（中文版保留为 `README_CN.md`）。
- 将 `CHANGELOG.md` 改写为英文。
- 将 `pubspec.yaml` 的 `description` 改为纯英文。

### 新增

- 新增 `example/` 目录，包含 CLI 使用示例与编程式 API 演示。
- 为 `lib/fluzer.dart` 添加库级 dartdoc。

### 修复

- 提升 pub.dev 评分：将 `analyzer` 约束从 `^10.2.0` 放宽到 `>=10.0.1 <15.0.0`，以支持最新版本（实际解析版本仍受 `codemod_recipe` 传递依赖 `^10.0.1` 限制在上限 10.x）。

## 1.0.0

首次发布。

### 新增

- `fluzer create <name>`：一步生成 Flutter Zero 项目（支持本地路径、远程 zip、模板注册表来源）。
- `fluzer new <feature>`：在已有项目中生成功能模块，并自动注入 DI 注册。
- `fluzer version`：检查最新的 CLI 与模板版本，并给出更新提示。
- `fluzer cache list|clean`：查看或清理本地模板缓存。
- 内置国内镜像降级（ghfast.top / api.gitproxy.dev），提升国内访问稳定性。
- 彩色日志输出与清晰的命令帮助信息。
