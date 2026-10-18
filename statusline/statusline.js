#!/usr/bin/env node
/*
 * Claude Code status line + hook — single file, two roles.
 *
 * As STATUSLINE → renders the panel (stdin has model/context/cost fields).
 * As HOOK       → records permission_mode; refreshes account cache from API once/hour.
 *
 * Layout:
 *   ╭─ Left ────────────────┬─ Right ──────────────────────────────────╮
 *   │ Model                 │ Context                                  │
 *   │ ◆ Sonnet 4.6 (high)   │ ████░░ 6%                                │
 *   │                       │ Session 5h                               │
 *   │ Directory             │ █░░░░░ 13% · 4h                          │
 *   │ /full/path            │ Weekly 7d                                │
 *   │                       │ ████░░ 67% · 5d                          │
 *   │ Account               │                                          │
 *   │ joel@mail.com  (Pro)  │                                          │
 *   ├───────────────────────┴──────────────────────────────────────────┤
 *   │ ○ Normal   ● Auto-accept   ○ Plan   ·  Shift+Tab to cycle        │
 *   ╰──────────────────────────────────────────────────────────────────╯
 *
 * Files needed:  ~/.claude/statusline.js  +  settings.json entries (see bottom).
 * Requirement:   Node.js (built-in modules only).
 */
"use strict";

const { execSync } = require("child_process");
const os   = require("os");
const fs   = require("fs");
const path = require("path");

const CLAUDE_DIR  = path.join(os.homedir(), ".claude");
const CACHE_FILE  = path.join(CLAUDE_DIR, ".statusline-account.json");
const MODE_FILE   = path.join(CLAUDE_DIR, ".statusline-mode");

// ── Read stdin ───────────────────────────────────────────────────────────────
let raw = "";
try { raw = fs.readFileSync(0, "utf8"); } catch (_) {}
let d = {};
try { d = JSON.parse(raw); } catch (_) {}

// ── Hook mode ────────────────────────────────────────────────────────────────
if (d.hook_event_name || (d.permission_mode && !d.model)) {
  if (d.permission_mode) {
    try { fs.writeFileSync(MODE_FILE, String(d.permission_mode)); } catch (_) {}
  }
  refreshAccountCache();
  process.exit(0);
}

// Refresh account cache from API — runs synchronously but only once per hour.
function refreshAccountCache() {
  try {
    const stat = fs.statSync(CACHE_FILE);
    if (Date.now() - stat.mtimeMs < 3_600_000) return; // still fresh
  } catch (_) {}

  let token = "", localPlan = "";
  try {
    const creds = JSON.parse(fs.readFileSync(path.join(CLAUDE_DIR, ".credentials.json"), "utf8"));
    const oauth = creds.claudeAiOauth || {};
    token     = oauth.accessToken || oauth.idToken || "";
    localPlan = oauth.subscriptionType || "";
  } catch (_) { return; }

  if (!token) return;

  // api.anthropic.com/api/oauth/profile works with the OAT bearer token.
  try {
    const out  = execSync(
      `curl -s -m 5 -H "Authorization: Bearer ${token}" -H "anthropic-version: 2023-06-01" "https://api.anthropic.com/api/oauth/profile"`,
      { encoding: "utf8", timeout: 6000 }
    );
    const data  = JSON.parse(out);
    const acct  = data.account || {};
    const email = acct.email || "";
    const plan  = acct.has_claude_max ? "Max"
                : acct.has_claude_pro ? "Pro"
                : localPlan;
    fs.writeFileSync(CACHE_FILE, JSON.stringify({ email, plan, ts: Date.now() }));
    return;
  } catch (_) {}

  // API failed — cache plan-only so we don't retry for an hour.
  if (localPlan) {
    try { fs.writeFileSync(CACHE_FILE, JSON.stringify({ email: "", plan: localPlan, ts: Date.now() })); } catch (_) {}
  }
}

// ── ANSI palette ─────────────────────────────────────────────────────────────
const e   = (c) => `\x1b[${c}m`;
const R   = e(0), BOLD = e(1), DIM = e(2);
const RED = e("38;5;203"), ORG = e("38;5;215"), YLW = e("38;5;220");
const GRN = e("38;5;114"), TEAL = e("38;5;79");
const MAG = e("38;5;177"), CYN  = e("38;5;87"), GRY = e("38;5;245");
const WHT = e("38;5;252"), BORD = e("38;5;215");

// ── Helpers ───────────────────────────────────────────────────────────────────
const num    = (v, def = 0) => (typeof v === "number" && isFinite(v) ? v : def);
const heat   = (p) => (p >= 85 ? RED : p >= 60 ? YLW : GRN);
const visW   = (s) => s.replace(/\x1b\[[0-9;]*m/g, "").length;
const fmtPct = (p) => (Number.isInteger(p) ? `${p}` : p.toFixed(1));
const B      = (s) => `${BORD}${s}${R}`;
const LBL    = (t) => `${BORD}${t}${R}`;

function boxWidth() {
  const c = parseInt(process.env.COLUMNS, 10);
  const w = c > 20 ? c : (process.stdout.columns > 20 ? process.stdout.columns : 100);
  return Math.max(54, w - 10);
}

function bar(pct, width = 8) {
  const p = Math.max(0, Math.min(100, pct));
  const filled = Math.round((p / 100) * width);
  return `${heat(p)}${"█".repeat(filled)}${DIM}${"░".repeat(width - filled)}${R}`;
}

function fmtDur(ms) {
  const s = Math.floor(num(ms) / 1000);
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60), h = Math.floor(m / 60);
  if (h > 0) return `${h}h${m % 60}m`;
  return `${m}m`;
}

function until(epoch) {
  if (!epoch) return "";
  const s = epoch - Math.floor(Date.now() / 1000);
  if (s <= 0) return "now";
  const m = Math.floor(s / 60), h = Math.floor(m / 60), days = Math.floor(h / 24);
  if (days >= 1) return `${days}d`;
  if (h >= 1) return `${h}h`;
  return `${m}m`;
}

function shortDir(p) {
  if (!p) return "";
  p = p.replace(/\\/g, "/");
  const home = os.homedir().replace(/\\/g, "/");
  if (p.toLowerCase() === home.toLowerCase()) return "~";
  if (p.toLowerCase().startsWith(home.toLowerCase() + "/"))
    return "~/" + p.slice(home.length + 1).split("/").slice(-2).join("/");
  return p.split("/").filter(Boolean).slice(-2).join("/");
}

function gitInfo(cwd) {
  const run = (a) => {
    try { return execSync(`git ${a}`, { cwd, stdio: ["ignore", "pipe", "ignore"], encoding: "utf8" }).trim(); }
    catch (_) { return ""; }
  };
  if (!run("rev-parse --git-dir")) return "";
  const branch = run("symbolic-ref --short HEAD") || run("rev-parse --short HEAD");
  if (!branch) return "";
  const staged = run("diff --cached --numstat").split("\n").filter(Boolean).length;
  const dirty  = run("diff --numstat").split("\n").filter(Boolean).length;
  let s = `${MAG}${branch}${R}`;
  if (staged) s += ` ${GRN}+${staged}${R}`;
  if (dirty)  s += ` ${YLW}~${dirty}${R}`;
  return s;
}

function spread(left, right, width) {
  const pad = width - visW(left) - visW(right);
  return left + " ".repeat(pad >= 3 ? pad : 3) + right;
}

function padCell(line, w) {
  return " " + line + " ".repeat(Math.max(0, w - 1 - visW(line)));
}

function modeRow() {
  let mode = "";
  try { mode = fs.readFileSync(MODE_FILE, "utf8").trim(); } catch (_) {}
  const active = mode === "auto" ? "acceptEdits" : mode;
  const cycle  = [["default", "Normal"], ["acceptEdits", "Auto-accept"], ["plan", "Plan"]];
  const extra  = { dontAsk: ["Don't-ask", YLW], bypassPermissions: ["Bypass", RED] };
  const chips  = cycle.map(([key, label]) =>
    key === active ? `${ORG}${BOLD}● ${label}${R}` : `${DIM}○ ${label}${R}`
  );
  if (extra[mode]) chips.push(`${extra[mode][1]}${BOLD}● ${extra[mode][0]}${R}`);
  const hint = mode
    ? `${DIM}as of last msg · Shift+Tab cycles${R}`
    : `${DIM}send a message to detect${R}`;
  return `${chips.join("   ")}   ${DIM}·${R}  ${hint}`;
}

// ── Extract session fields ────────────────────────────────────────────────────
const W      = boxWidth();
const model  = (d.model && d.model.display_name) || "Claude";
const effort = d.effort && d.effort.level;
const cwd    = (d.workspace && d.workspace.current_dir) || d.cwd || ".";
const ctxPct = num((d.context_window || {}).used_percentage);
const cost   = d.cost || {};
const rl     = d.rate_limits || {};

const limitLines = (label, win) => {
  if (win && typeof win.used_percentage === "number") {
    const p = win.used_percentage, r = until(win.resets_at);
    return [
      LBL(label),
      `${bar(p)} ${heat(p)}${fmtPct(p)}%${R}${r ? `  ${GRY}resets ${r}${R}` : ""}`,
    ];
  }
  return [LBL(label), `${DIM}pending${R}`];
};

// ── Account (email + plan from cache) ────────────────────────────────────────
let accountLines = [];
try {
  const acc   = JSON.parse(fs.readFileSync(CACHE_FILE, "utf8"));
  const email = acc.email || "";
  const plan  = acc.plan  || "";
  if (email || plan) {
    let val = "";
    if (email) val += `${WHT}${email}${R}`;
    if (plan)  val += (email ? "  " : "") + `${DIM}(${R}${TEAL}${plan.charAt(0).toUpperCase() + plan.slice(1)}${R}${DIM})${R}`;
    accountLines = [LBL("Account"), val];
  }
} catch (_) {}

// ── Column content ────────────────────────────────────────────────────────────
const modelLine = `${BOLD}${CYN}◆ ${model}${R}` +
  (effort ? `  ${DIM}(${R}${TEAL}${effort}${R}${DIM})${R}` : "");

const DIV = "\x00DIV\x00"; // marker: render a horizontal divider across the left column only
const leftLines = [
  ...accountLines,
  ...(accountLines.length ? [DIV] : []),
  LBL("Model"),
  modelLine,
  DIV,
  LBL("Working directory"),
  `${GRY}${cwd.replace(/\\/g, "/")}${R}`,
];

const rightLines = [
  LBL("Context"),
  `${bar(ctxPct)} ${heat(ctxPct)}${fmtPct(ctxPct)}%${R}` +
    (ctxPct >= 70 ? `  ${YLW}/handoff?${R}` : ""),
  DIV,
  ...limitLines("Session 5h", rl.five_hour),
  DIV,
  ...limitLines("Weekly 7d", rl.seven_day),
];

// ── Column widths ─────────────────────────────────────────────────────────────
const innerTotal = W - 3;
const leftW  = Math.max(...leftLines.filter((l) => l !== DIV).map(visW), Math.floor(innerTotal * 0.40)) + 2;
const rightW = innerTotal - leftW;

// ── Render ────────────────────────────────────────────────────────────────────
const hRule = (l, mid, r) => B(l + "─".repeat(leftW) + mid + "─".repeat(rightW) + r);

const height = Math.max(leftLines.length, rightLines.length);
const lPad   = [...leftLines,  ...Array(height - leftLines.length).fill("")];
const rPad   = [...rightLines, ...Array(height - rightLines.length).fill("")];

const contentRows = lPad.map((l, i) => {
  const r = rPad[i];
  const lDiv = l === DIV, rDiv = r === DIV;
  const outL      = B(lDiv ? "├" : "│");
  const leftPart  = lDiv ? B("─".repeat(leftW)) : padCell(l, leftW);
  const mid       = B(lDiv && rDiv ? "┼" : lDiv ? "┤" : rDiv ? "├" : "│");
  const rightPart = rDiv ? B("─".repeat(rightW)) : padCell(r, rightW);
  const outR      = B(rDiv ? "┤" : "│");
  return outL + leftPart + mid + rightPart + outR;
});

const spanW    = leftW + 1 + rightW;
const modeLines = [
  hRule("├", "┴", "┤"),
  B("│") + padCell(modeRow(), spanW) + B("│"),
  B("╰" + "─".repeat(spanW) + "╯"),
];

const fl    = [`${DIM}${WHT}${shortDir(cwd)}${R}`];
const git   = gitInfo(cwd);
if (git) fl.push(git);
const footL = "  " + fl.join(`  ${DIM}·${R}  `);
const footR = `${DIM}Edits${R} ${GRN}+${num(cost.total_lines_added)}${R} ${RED}-${num(cost.total_lines_removed)}${R}  `;

process.stdout.write([
  hRule("╭", "┬", "╮"),
  ...contentRows,
  ...modeLines,
  spread(footL, footR, W),
].join("\n") + "\n");

/*
 * ── settings.json entries to merge ──────────────────────────────────────────
 *
 *   "statusLine": { "type": "command", "command": "node ~/.claude/statusline.js", "padding": 2 },
 *   "hooks": {
 *     "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "node ~/.claude/statusline.js" }] }],
 *     "PreToolUse":       [{ "hooks": [{ "type": "command", "command": "node ~/.claude/statusline.js" }] }],
 *     "PostToolUse":      [{ "hooks": [{ "type": "command", "command": "node ~/.claude/statusline.js" }] }],
 *     "Stop":             [{ "hooks": [{ "type": "command", "command": "node ~/.claude/statusline.js" }] }]
 *   }
 */
