// `cache` 命令上下文。
//
// 该命令是 `list` / `clean` 子命令的容器，实际工作由子命令完成，
// 故顶层命令无额外解析状态，上下文为空，仅用于满足 [BaseCommand] 契约。
//
// `cache` command context.
//
// This command is a container for the `list` / `clean` subcommands, which do
// the real work, so the top-level command carries no extra parsed state; the
// context exists only to satisfy the [BaseCommand] contract.
class CacheCommandContext {
  const CacheCommandContext();
}
