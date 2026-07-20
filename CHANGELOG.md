## 1.0.0

首个正式版本。

### 新增

- `fluzer create <name>`：一键生成 Flutter Zero 项目（支持本地路径 / 远程 zip / 模板注册表三种模板源）。
- `fluzer new <feature>`：在现有项目中生成功能模块并自动注入 DI 注册。
- `fluzer version`：查看 CLI 与模板的最新版本及更新提示。
- `fluzer cache list|clean`：查看或清理本地模板缓存。
- 模板源内置国内镜像降级（ghfast.top / api.gitproxy.dev），提升国内访问稳定性。
- 彩色日志输出与清晰的命令帮助信息。
