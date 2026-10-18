# work_general

Instruções, skills, agents e configurações do Claude Code **e do Codex** que valem para
**todos** os meus projetos — comportamento do agente, boas práticas e como trabalhar comigo.
Nada específico de linguagem ou stack: isso fica no `CLAUDE.md`/`AGENTS.md` de cada projeto.

Cada peça é independente: instalo tudo ou só o que interessa.

## Estrutura

| Pasta | Conteúdo |
| --- | --- |
| `instructions/` | Módulos de instruções, importados via `@` no `CLAUDE.md` |
| `skills/` | Skills globais (`handoff`, `roadmap`, `web-fetch-spa`) |
| `agents/` | Subagents globais (vazio por enquanto) |
| `statusline/` | Status line do Claude (`statusline.js`, só Node built-in) e preset do Codex (`codex-status-line.json`) |
| `scripts/install.ps1` | Instalador seletivo |

### Módulos de instruções

| Módulo | O que cobre |
| --- | --- |
| `communication` | Voz enxuta inspirada no caveman (sem cerimônia, resposta primeiro, explica sem palestra), idioma, franqueza |
| `coding-discipline` | Karpathy geral + extras: pensar antes, ler antes de escrever, simplicidade, mudanças cirúrgicas, causa raiz, metas verificáveis |
| `files-and-output` | Diretório temp `D:\Joel\AIs\temp`, pastas de handoff/roadmap, configs e secrets |
| `tooling` | Excluir `bin/obj/node_modules` em buscas no shell, SPA via Playwright, ambiente Windows |
| `sessions` | Handoff só quando pedido, roadmap, memória |

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

## Adicionando coisas

- **Instrução** → novo `instructions/<tema>.md` começando com `## <Título>`. Só regras que valem
  para qualquer projeto.
- **Skill** → `skills/<nome>/SKILL.md` (frontmatter `name` + `description`).
- **Agent** → `agents/<nome>.md`.

O que for específico de projeto ou stack fica no repo do projeto.
