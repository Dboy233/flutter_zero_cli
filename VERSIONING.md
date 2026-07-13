# CLI 版本规范 / CLI Versioning

本规范定义 `flutter_zero_cli`（fluzer 工具）的版本号管理规则，以及与
`flutter_zero_template`（bricks 模板仓库）的兼容性约束。

CLI 与模板是两条独立的版本线，二者通过 `template_registry.json` 中的
`minCliVersion` 字段桥接：CLI 运行时读取该字段，校验自身版本是否满足模板要求。

## 语义化版本（SemVer）

版本号格式 `主版本.次版本.补丁`（`MAJOR.MINOR.PATCH`），例如 `1.0.0`。

## CLI 版本号 bump 规则

| 位 | 触发条件 | 对模板的影响 | 备注 |
|----|----------|--------------|------|
| **PATCH** `1.0.x` | CLI bug 修复（如 http 超时未兜底、codemod 边界错误） | 无感 | 模板 `minCliVersion` 仍满足 |
| **MINOR** `1.x.0` | 向下兼容地**新增**功能：新命令、registry 拉取支持、新环境变量 | 现有模板照常加载 | `minCliVersion` 不变 |
| **MAJOR** `x.0.0` | **破坏性变更**：开始向 brick 传**新必填变量**而老模板没有、重写 codemod 注入逻辑导致老模板锚点失效 | 老模板可能生成失败 | 需同步推新模板或做兼容分支 |

## resolveBrickLoader 兼容逻辑

CLI 运行时的模板来源解析流程（`lib/src/template/template_source.dart`）：

1. `FLUZER_BRICKS_DIR` 非空 → 本地加载（开发/调试）。
2. 否则拉取 `template_registry.json`（硬编码的 registry URL）：
   - 成功 → 读取 `url` 与 `minCliVersion`；若 `自身版本 < minCliVersion` → 报错提示升级。
   - 失败（断网/网络差）→ 回退到内置 `_defaultTemplateZipUrl` 兜底。
3. 用解析出的 `url` 构造 `RemoteBrickLoader`。

> zip 缓存基于 URL 哈希。registry 中不同版本的 `url` 天然命中不同缓存目录，
> 旧版本缓存不会被误用，无需手动清理。

## minCliVersion 校验

- CLI 启动时校验自身版本是否 ≥ registry 的 `minCliVersion`。
- 不满足 → 终止并提示用户升级 CLI，避免用不兼容的 CLI 生成坏代码。

## 兼容性契约分水岭（CLI 侧）

判断 bump 哪一位，关键看是否动了**契约**：

1. **Mason 变量契约**：若 CLI 开始向 brick 传新必填变量（超出 `name` + `package_name`），老模板未声明 → 破坏 → CLI MAJOR。
2. **生成代码结构契约**：`CodeMod`（`addImport` / `insertAtMethodEnd`）依赖生成代码的类名/方法名定位。若 CLI 重写注入逻辑导致老模板锚点失效 → CLI MAJOR。
3. **DI 注册锚点**：`registerFeatureModules()` 注入区域的方法签名变化 → CLI MAJOR。

> 经验法则：**只动"内容/内部实现"不 bump 主版本；动了"契约/锚点"必 bump 主版本并通知模板侧同步。**

## 发布流程（CLI）

1. 修改 CLI 代码。
2. 按上表 bump 版本号（`pubspec.yaml` 的 `version`）。
3. 若本次为 **MAJOR 且影响模板契约** → 通知模板侧发对应版本并提升其 `minCliVersion`。
4. 发版：`dart pub publish` 或 `dart pub global activate fluzer`。

## 相关文档

- 模板版本规范见 `../flutter_zero_template/VERSIONING.md`。
