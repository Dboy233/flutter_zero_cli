# fluzer

Flutter Zero 模板项目脚手架工具 / CLI tool for scaffolding Flutter Zero projects

## 快速开始 / Quick Start

### 开发模式 / Development

```bash
dart run bin/main.dart new user
```

### 全局安装 / Global Install

```bash
dart pub global activate fluzer

fluzer create my_app
fluzer new user
```

## 命令 / Commands

### `new` — 新增功能模块 / Add feature module

在当前 `flutter_zero` 模板项目中生成功能模块骨架，并自动注册到 DI。

Generates a feature module skeleton in the current `flutter_zero` template project, and auto-registers it in DI.

```bash
fluzer new <feature_name>

# 选项 / Options:
#   --build-runner     生成后是否运行 build_runner（默认启用）/ Run build_runner after generation (default: true)
#   --no-build-runner  跳过 build_runner / Skip build_runner
```

### `create` — 创建新项目 / Create new project

从模板创建全新的 Flutter 项目，包含完整的 core 基础设施、示例模块和配置。

Creates a new Flutter project from the template, with full core infrastructure, example modules, and configuration.

执行步骤 / Steps:
1. 校验项目名合法性 / Validate project name
2. 复制模板目录到目标位置 / Copy template to target
3. 全局替换包名 / Global package name replacement
4. 重命名 .iml 文件 / Rename .iml file
5. 执行 `flutter create . --org --project-name` / Run flutter create
6. 清理 flutter create 生成的多余测试文件 / Clean up extra test file (widget_test.dart)
7. 执行 `flutter pub get` / Run flutter pub get
8. 执行 `flutter gen-l10n` / Run flutter gen-l10n
9. 执行 `build_runner`（可选）/ Run build_runner (optional)

```bash
fluzer create my_app

# 选项 / Options:
#   --org <org>             组织名（默认 com.example，影响 bundle ID）/ Organization (default: com.example, affects bundle ID)
#   --desc <description>    项目描述 / Project description
#   --build-runner          生成后是否运行 build_runner（默认启用）/ Run build_runner after creation (default: true)
#   --no-build-runner       跳过 build_runner / Skip build_runner
```

## 目录结构 / Project Structure

```
fluzer/
├── bin/
│   └── main.dart                    # 入口 / Entry point
├── lib/
│   ├── fluzer.dart                  # 公共导出 / Public exports
│   └── src/
│       ├── fluzer.dart              # CLI 根控制器 / Root controller
│       ├── commands/
│       │   ├── create_command.dart  # create 命令 / create command
│       │   └── new_command.dart     # new 命令 / new command
│       ├── codemod/
│       │   ├── codemod_file_editor.dart       # 通用文件编辑器 / Generic file editor
│       │   ├── feature_registration.dart      # DI 注册封装 / DI registration wrapper
│       │   ├── insert_at_method_end_transform.dart  # 方法末尾插入 / Insert at method end
│       │   └── ordered_import_transform.dart  # import 顺序插入 / Ordered import insertion
│       ├── config/
│       │   └── project_config.dart  # 项目配置与 CliException / Project config & CliException
│       └── templates/
│           ├── feature_generator.dart # 功能模块生成器 / Feature module generator
│           └── template_engine.dart   # 模板渲染引擎 / Template rendering engine
├── templates/
│   └── v1/
│       ├── feature/                 # 功能模块模板 / Feature module templates
│       └── project/                 # 完整项目模板 / Full project template
├── test/
│   └── fluzer_test.dart             # 单元测试 / Unit tests
└── pubspec.yaml
```

## 配置文件 / Configuration

CLI 依赖模板项目根目录的 `flutter_zero_config.yaml`：

The CLI depends on `flutter_zero_config.yaml` in the template project root:

```yaml
version: 1
template_name: flutter_zero
```

## 技术栈 / Tech Stack

| 类别 | 方案 |
|------|------|
| 参数解析 | args |
| 日志输出 | mason_logger |
| AST 修改 | analyzer + codemod_recipe |
| 模板渲染 | 自定义 TemplateEngine（`{{key}}` 占位符） |
| YAML 解析 | yaml |
| 路径操作 | path |
