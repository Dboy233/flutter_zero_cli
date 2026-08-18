// `version` 命令上下文。
//
// 该命令行为完全由命令行标志决定（打印 CLI 版本 + 检查 pub.dev 更新），
// 无额外解析状态，故上下文为空，仅用于满足 [BaseCommand] 契约。
//
// `version` command context.
//
// The command's behavior is fully determined by its flags (print the CLI
// version and check pub.dev for updates), so it carries no extra parsed
// state; the context exists only to satisfy the [BaseCommand] contract.
class VersionCommandContext {
  const VersionCommandContext();
}
