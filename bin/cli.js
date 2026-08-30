#!/usr/bin/env node
/**
 * remove-codecv-watermark - installer CLI
 *
 * Install the CodeCV resume watermark remover skill into AI coding tools.
 *
 * Usage:
 *   npx github:liangkingjin/codecv-watermark-skill
 *   npx github:liangkingjin/codecv-watermark-skill --all
 *   npx github:liangkingjin/codecv-watermark-skill --dir /custom/skills --force
 */
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

const SKILL_NAME = 'remove-codecv-watermark';
const home = os.homedir();

// Skill directories of supported AI coding tools.
// Sources: each tool's official docs / agentskills.io ecosystem analysis.
const CANDIDATES = [
  { name: 'WorkBuddy',     dir: path.join(home, '.workbuddy', 'skills') },
  { name: 'Claude Code',   dir: path.join(home, '.claude', 'skills') },
  { name: 'CodeBuddy Code',dir: path.join(home, '.codebuddy', 'skills') },
  { name: 'Cursor',        dir: path.join(home, '.cursor', 'skills') },
  { name: 'OpenCode',      dir: path.join(home, '.config', 'opencode', 'skills') },
  { name: 'Codex CLI',     dir: path.join(home, '.codex', 'skills') },
  { name: 'Gemini CLI',    dir: path.join(home, '.gemini', 'skills') },
  { name: 'Windsurf',      dir: path.join(home, '.codeium', 'windsurf', 'skills') },
  { name: 'Trae',          dir: path.join(home, '.trae', 'skills') },
  { name: 'GitHub Copilot',dir: path.join(home, '.copilot', 'skills') },
  { name: 'Augment',       dir: path.join(home, '.augment', 'skills') },
  { name: 'Antigravity',   dir: path.join(home, '.gemini', 'antigravity', 'skills') },
  { name: 'Cline',         dir: path.join(home, '.cline', 'skills') },
  { name: 'Roo Code',      dir: path.join(home, '.roo', 'skills') },
  { name: 'Kilo Code',     dir: path.join(home, '.kilocode', 'skills') },
  { name: 'Continue',      dir: path.join(home, '.continue', 'skills') },
  { name: 'Qoder',         dir: path.join(home, '.qoder', 'skills') },
  { name: 'Qwen Code',     dir: path.join(home, '.qwen', 'skills') },
  // Universal agents (agentskills.io spec): one dir shared by many tools
  { name: 'Universal (.agents)', dir: path.join(home, '.agents', 'skills') },
];

function usage() {
  console.log(`Usage: npx github:liangkingjin/codecv-watermark-skill [options]

Options:
  --all           Install into every supported tool's skill directory
  --dir <path>    Install into a custom skill directory (repeatable)
  --force         Overwrite an existing installation
  -h, --help      Show this help

Default: install into skill directories that already exist on this machine;
if none exist, fall back to ~/.workbuddy/skills.`);
}

function parseArgs(argv) {
  const opts = { all: false, force: false, dirs: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--all') opts.all = true;
    else if (a === '--force') opts.force = true;
    else if (a === '--dir') {
      const v = argv[++i];
      if (!v) { console.error('--dir requires a path'); process.exit(1); }
      opts.dirs.push(v);
    } else if (a === '-h' || a === '--help') { usage(); process.exit(0); }
    else { console.error(`Unknown option: ${a}`); usage(); process.exit(1); }
  }
  return opts;
}

function findSkillSource() {
  // When run via npx (package installed in node_modules), files sit next to package.json.
  // When run from a git clone, they sit in <repo>/skill/.
  const fromPkg = path.join(__dirname, '..', 'skill', SKILL_NAME);
  if (fs.existsSync(path.join(fromPkg, 'SKILL.md'))) return fromPkg;
  const fromRepo = path.join(process.cwd(), 'skill', SKILL_NAME);
  if (fs.existsSync(path.join(fromRepo, 'SKILL.md'))) return fromRepo;
  return null;
}

function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const s = path.join(src, entry.name);
    const d = path.join(dest, entry.name);
    if (entry.isDirectory()) copyDir(s, d);
    else fs.copyFileSync(s, d);
  }
}

function main() {
  const opts = parseArgs(process.argv.slice(2));
  const src = findSkillSource();
  if (!src) {
    console.error('Error: skill files not found (expected skill/' + SKILL_NAME + '/SKILL.md).');
    process.exit(1);
  }

  let targets = [];
  if (opts.all) {
    targets = CANDIDATES.slice();
  } else {
    targets = CANDIDATES.filter((c) => fs.existsSync(c.dir));
    if (targets.length === 0) targets = [CANDIDATES[0]];
  }
  targets = targets.concat(opts.dirs.map((d) => ({ name: 'custom', dir: d })));

  const installed = [];
  for (const t of targets) {
    const dest = path.join(t.dir, SKILL_NAME);
    if (fs.existsSync(dest) && !opts.force) {
      console.log(`==> Skipped (already exists): ${dest}  (use --force to overwrite)`);
      continue;
    }
    try {
      fs.rmSync(dest, { recursive: true, force: true });
    } catch (_e) {
      // If removal fails (e.g. locked or sandboxed fs), fall through and
      // overwrite files in place via copyFileSync below.
    }
    copyDir(src, dest);
    console.log(`==> Installed [${t.name}]: ${dest}`);
    installed.push(dest);
  }

  const first = installed[0] || path.join(CANDIDATES[0].dir, SKILL_NAME);
  console.log(`
Done. Installed into ${installed.length} tool(s).

Next steps:
  1. Install the Python dependency:
     pip install -r "${path.join(first, 'scripts', 'requirements.txt')}"
  2. In your AI coding tool, say:
     "帮我去掉这份 CodeCV 简历的水印 @简历.pdf"

The skill triggers automatically on requests like "CodeCV 水印" / "简历去水印".`);
}

main();
