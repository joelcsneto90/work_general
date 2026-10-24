# work_general

Instruções, skills, agents e configurações do Claude Code **e do Codex** que valem para
**todos** os meus projetos — comportamento do agente, boas práticas e como trabalhar comigo.
Nada específico de linguagem ou stack: isso fica no `CLAUDE.md`/`AGENTS.md` de cada projeto.

Cada peça é independente: instalo tudo ou só o que interessa.

## Estrutura

| Pasta | Conteúdo |
| --- | --- |
| `instructions/` | Módulos de instruções, importados via `@` no `CLAUDE.md` |
| `skills/` | Skills globais (`handoff`, `roadmap`, `execute-roadmap`, `web-fetch-spa`) |
| `agents/` | Subagents globais (vazio por enquanto) |
| `statusline/` | Status line do Claude (`statusline.js`, só Node built-in) e preset do Codex (`codex-status-line.json`) |
| `scripts/install.ps1` | Instalador seletivo |
| `scripts/vscode-profile.ps1` | Perfis do VS Code por stack (extensões, settings base, associação de workspace) |

### Módulos de instruções

| Módulo | O que cobre |
| --- | --- |
| `communication` | Voz enxuta inspirada no caveman (sem cerimônia, resposta primeiro, explica sem palestra), idioma, franqueza |
| `coding-discipline` | Karpathy geral + extras: pensar antes, ler antes de escrever, simplicidade, mudanças cirúrgicas, causa raiz, metas verificáveis; extras de debug/verificação do superpowers |
| `files-and-output` | Diretório temp `D:\Joel\AIs\temp\<projeto>`, pastas de handoff/roadmap, configs e secrets |
| `tooling` | Excluir `bin/obj/node_modules` em buscas no shell, SPA via Playwright, ambiente Windows |
| `sessions` | Handoff só quando pedido, roadmap e sua execução, memória |

### Skills

| Skill | Uso |
| --- | --- |
| `handoff` | Handoff de sessão em `D:\Joel\AIs\handoffs`, só quando pedido |
| `roadmap` | Plano de implementação em `D:\Joel\AIs\roadmaps` (só planeja) |
| `execute-roadmap` | Executa um roadmap task a task: pré-scan de dependências, inline ou subagent por task, revisão independente, verificação do "Done when", rulings no arquivo. Versão enxuta do `subagent-driven-development` do [obra/superpowers](https://github.com/obra/superpowers) |
| `web-fetch-spa` | Renderiza páginas SPA/JS com Playwright |

## Instalação

```powershell
./scripts/install.ps1 -List                     # o que está disponível
./scripts/install.ps1 -All                      # tudo no Claude Code (~/.claude)
./scripts/install.ps1 -All -Codex               # tudo no Codex (~/.codex)
./scripts/install.ps1 -Instructions communication,coding-discipline -Skills handoff,roadmap
./scripts/install.ps1 -Statusline
```

Sem `-Codex` o alvo é o Claude Code. `-Dir` troca a pasta de destino.

### Claude Code

Sempre com backup em `~/.claude/backups/work_general-<timestamp>/`:

- **Instruções** → bloco `<!-- work_general:begin/end -->` no `~/.claude/CLAUDE.md` com
  `@D:/.../instructions/<módulo>.md`. O resto do arquivo não é tocado. Rodar de novo substitui
  o bloco.
- **Skills** → junction `~/.claude/skills/<nome>` → `skills/<nome>` (não precisa de admin).
- **Agents** → cópia para `~/.claude/agents/`.
- **Statusline** → merge no `~/.claude/settings.json`, apontando para o script deste repo.

Instruções, skills e statusline apontam direto para o repo, então um `git pull` já
atualiza. Agents são copiados: rode o install de novo depois do pull.

### Codex (`-Codex`)

Backup em `~/.codex/backups/work_general-<timestamp>/`:

- **Instruções** → o Codex não tem `@import`, então o conteúdo dos módulos é **concatenado** no
  bloco marcado do `~/.codex/AGENTS.md`. Depois de um `git pull`, rode `install.ps1 -Codex` de
  novo.
- **Skills** → mesmas junctions, em `~/.codex/skills/`. A mesma pasta serve aos dois:
  `agents/openai.yaml` é metadado do Codex (invocação `$handoff`, implícita ou não) e o Claude
  ignora.
- **Agents** → ignorados (o Codex usa outro formato, TOML).
- **Statusline** → o Codex não aceita script, só itens prontos. O `[tui] status_line` do
  `config.toml` é preenchido com a lista de `statusline/codex-status-line.json`; o resto do
  arquivo não é tocado.

### Usar só em um projeto

No `CLAUDE.md` do projeto, importe só os módulos que fazem sentido:

```markdown
@D:/Joel/repos/Joel/WorkGeneral/instructions/coding-discipline.md
```

Se o módulo já estiver importado no `~/.claude/CLAUDE.md` global, não precisa repetir no projeto.

## Perfis do VS Code

Extensões são por **perfil**: um workspace só consegue *recomendar* extensões
(`extensions.recommendations`), e habilitar/desabilitar por workspace é só pela UI, sem arquivo
versionável. Por isso cada stack tem um perfil, e o workspace é associado a ele.

| Perfil | Extensões (além de Claude Code, VS Keybindings, Azure Tools pack e Bicep, em todos; Copilot já vem no VS Code) |
| --- | --- |
| `default` | — |
| `dotnet` | .NET Install Tool, C#, C# Dev Kit |
| `angular` | ESLint, Prettier, HTML CSS Support, Path Intellisense, Angular Language Service |
| `react` | ESLint, Prettier, HTML CSS Support, Path Intellisense, ES7+ React snippets |

TypeScript, JavaScript, HTML e CSS já vêm no VS Code.

Perfil **não herda** do Default: cada um tem settings, atalhos e snippets próprios (vazios ao
criar), a não ser que use os do Default (`useDefaultFlags`). O `-ShareDefault` liga isso para
settings, keybindings, snippets, tasks, prompts e MCP — só as extensões ficam por perfil. Os
settings base (`workbench.sideBar.location: right`, tema `Visual Studio Dark`,
`claudeCode.preferredLocation: sidebar`) vão no `settings.json` do Default; as outras chaves não
são tocadas.

```powershell
./scripts/vscode-profile.ps1 -Name default,dotnet,angular,react             # cria o que falta e sincroniza
./scripts/vscode-profile.ps1 -Name angular -Open D:\path\Projeto.code-workspace   # + associa o workspace
./scripts/vscode-profile.ps1 -ShareDefault                                  # VS Code fechado
```

Roda no Windows e no Linux (PowerShell 7 `pwsh` e o comando `code` no PATH; no Linux usa
`~/.config/Code/User`). O `-ShareDefault` exige o VS Code fechado (ele regrava o `storage.json` ao sair) e faz backup
antes. Perfil novo abre uma janela vazia na criação: o CLI só instala em perfil que já existe,
e só cria abrindo uma janela; depois rode o `-ShareDefault`. Layout das views (ex.: arrastar o
Claude Code para a barra da direita) é estado de UI do perfil e não é compartilhado. Para lista
de extensões ou settings base, edite `$Always`, `$BaseSettings`, `$Shared` e `$Profiles` no
script.

## Adicionando coisas

- **Instrução** → novo `instructions/<tema>.md` começando com `## <Título>`. Só regras que valem
  para qualquer projeto.
- **Skill** → `skills/<nome>/SKILL.md` (frontmatter `name` + `description`).
- **Agent** → `agents/<nome>.md`.

O que for específico de projeto ou stack fica no repo do projeto.
