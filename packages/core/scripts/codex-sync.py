#!/usr/bin/env python3
"""codex-sync.py — derive an OpenAI Codex compatibility layer from the canonical
Claude Code source of truth in a consumer repo.

VERIFIED against a live Codex CLI 0.140 install (not just docs): Codex has a full
plugin + marketplace system whose layout is near-identical to Claude Code's. So the
port is at the PLUGIN level, and skills do not move — `plugins/<n>/skills/<s>/SKILL.md`
is the same path in both tools.

Claude Code files stay canonical and untouched. This generator emits derived,
committable, ADDITIVE artifacts:

    .claude-plugin/marketplace.json   ->  .agents/plugins/marketplace.json
    plugins/<n>/.claude-plugin/...    ->  plugins/<n>/.codex-plugin/plugin.json
    plugins/<n>/skills/<s>/SKILL.md   ->  (unchanged — same path in Codex)
    plugins/<n>/hooks/hooks.json      ->  (unchanged — companion folder, auto-discovered)
    CLAUDE.md (+ @imports)            ->  AGENTS.md (compact; refs, not inlined — byte budget)
    (notes)                           ->  .codex/CODEX-NOTES.md

Manifest contract is the live validator's (~/.codex/skills/.system/plugin-creator):
allowed keys {id,name,version,description,skills,apps,mcpServers,interface,author,
homepage,repository,license,keywords}; `hooks` is REJECTED from plugin.json.
interface requires displayName/shortDescription/longDescription/developerName/category
and a defaultPrompt. version must be strict semver.

Usage:
    codex-sync.py <repo>            # write the Codex layer
    codex-sync.py <repo> --check    # exit 1 if regen would change anything

Verify a generated plugin (no auth needed):
    python ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py <repo>/plugins/<n>
Install the marketplace into Codex:
    codex plugin marketplace add <repo>/.agents/plugins/marketplace.json
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

AGENTS_MAX_BYTES = 32 * 1024
AUTHOR = "Enchanter Labs"

# Claude marketplace category -> Codex display bucket (validator accepts any string;
# these match the buckets Codex's bundled plugins use).
CATEGORY_MAP = {
    "prompt-engineering": "Engineering",
    "optimization": "Engineering",
    "testing": "Engineering",
    "security": "Engineering",
    "portability": "Engineering",
    "meta": "Productivity",
    "plugin": "Productivity",
}


# --------------------------------------------------------------------------- #
def split_frontmatter(text: str) -> tuple[dict, str]:
    if not text.startswith("---"):
        return {}, text
    end = text.find("\n---", 3)
    if end == -1:
        return {}, text
    fm_block = text[3:end].strip("\n")
    body = text[end + 4:].lstrip("\n")
    fields: dict[str, str] = {}
    lines = fm_block.split("\n")
    i = 0
    key_re = re.compile(r"^([A-Za-z0-9_-]+):\s*(.*)$")
    while i < len(lines):
        m = key_re.match(lines[i])
        if not m:
            i += 1
            continue
        key, val = m.group(1), m.group(2).strip()
        if val in (">", "|", ">-", "|-"):
            i += 1
            collected = []
            while i < len(lines) and (lines[i].startswith(("  ", "\t")) or not lines[i].strip()):
                collected.append(lines[i].strip())
                i += 1
            fields[key] = " ".join(c for c in collected if c).strip()
            continue
        fields[key] = val
        i += 1
    return fields, body


def read_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def clip(s: str, n: int) -> str:
    s = " ".join(s.split())
    return s if len(s) <= n else s[: n - 1].rstrip() + "…"


def semver(v: str) -> str:
    return v if re.fullmatch(r"\d+\.\d+\.\d+(?:[-+].*)?", v or "") else "0.1.0"


# --------------------------------------------------------------------------- #
# Marketplace metadata: read the Claude marketplace once for per-plugin desc/category.
# --------------------------------------------------------------------------- #
def claude_marketplace(repo: Path) -> tuple[dict, dict]:
    mp = read_json(repo / ".claude-plugin" / "marketplace.json")
    by_name = {p.get("name"): p for p in mp.get("plugins", []) if isinstance(p, dict)}
    return mp, by_name


def plugin_dirs(repo: Path) -> list[Path]:
    return sorted(p.parent.parent for p in repo.glob("plugins/*/.claude-plugin/plugin.json"))


def _scripts_dir(repo: Path) -> Path:
    return repo / "shared" / "scripts"


def mcp_plugins(repo: Path) -> set[str]:
    """Plugins whose skills/agents shell out to shared/scripts (CLAUDE_PLUGIN_ROOT)."""
    if not _scripts_dir(repo).is_dir():
        return set()
    out = set()
    for pdir in plugin_dirs(repo):
        for md in list(pdir.glob("skills/*/SKILL.md")) + list(pdir.glob("agents/*.md")):
            txt = md.read_text(encoding="utf-8", errors="ignore")
            if "CLAUDE_PLUGIN_ROOT" in txt or "shared/scripts" in txt:
                out.add(pdir.name)
                break
    return out


# --------------------------------------------------------------------------- #
def gen_plugin_manifests(repo: Path) -> dict[str, str]:
    _, mp_by_name = claude_marketplace(repo)
    mcp = mcp_plugins(repo)
    files: dict[str, str] = {}
    for pdir in plugin_dirs(repo):
        name = pdir.name
        cj = read_json(pdir / ".claude-plugin" / "plugin.json")
        mp_entry = mp_by_name.get(name, {})
        desc = cj.get("description") or mp_entry.get("description") or f"{name} plugin"
        display = cj.get("display_name") or name.replace("-", " ").title()
        cat = CATEGORY_MAP.get((mp_entry.get("category") or "").lower(), "Productivity")
        ca = cj.get("author")
        author = {"name": AUTHOR}
        if isinstance(ca, dict) and ca.get("url"):
            author["url"] = ca["url"]

        manifest: dict = {
            "name": name,
            "version": semver(cj.get("version", "")),
            "description": clip(desc, 600),
            "author": author,
            "license": cj.get("license", "MIT"),
            "keywords": cj.get("keywords", []),
            "interface": {
                "displayName": display,
                "shortDescription": clip(desc, 80),
                "longDescription": clip(desc, 400),
                "developerName": AUTHOR,
                "category": cat,
                "capabilities": ["Read", "Write"],
                "defaultPrompt": [clip(f"Use {display} on my project", 128)],
            },
        }
        if (pdir / "skills").is_dir():
            manifest["skills"] = "./skills/"
        if name in mcp:
            manifest["mcpServers"] = "./.mcp.json"
        files[f"plugins/{name}/.codex-plugin/plugin.json"] = json.dumps(manifest, indent=2) + "\n"
    return files


def gen_mcp(repo: Path) -> dict[str, str]:
    """Bundle the MCP server + shared/scripts into each script-using plugin + .mcp.json."""
    mcp = mcp_plugins(repo)
    if not mcp:
        return {}
    server_src = (Path(__file__).resolve().parent / "codex-mcp-server.py").read_text(encoding="utf-8")
    scripts = sorted(_scripts_dir(repo).glob("*.py"))
    files: dict[str, str] = {}
    for name in sorted(mcp):
        files[f"plugins/{name}/mcp/server.py"] = server_src
        for s in scripts:
            files[f"plugins/{name}/mcp/lib/{s.name}"] = s.read_text(encoding="utf-8", errors="ignore")
        mcp_json = {"mcpServers": {f"{repo.name}-{name}-scripts": {
            "cwd": ".", "command": "python", "args": ["./mcp/server.py"]}}}
        files[f"plugins/{name}/.mcp.json"] = json.dumps(mcp_json, indent=2) + "\n"
    return files


def gen_marketplace(repo: Path) -> dict[str, str]:
    mp, mp_by_name = claude_marketplace(repo)
    display = (mp.get("metadata", {}).get("description") or repo.name.title())
    entries = []
    for pdir in plugin_dirs(repo):
        name = pdir.name
        cat = CATEGORY_MAP.get((mp_by_name.get(name, {}).get("category") or "").lower(), "Productivity")
        entries.append({
            "name": name,
            "source": {"source": "local", "path": f"./plugins/{name}"},
            "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
            "category": cat,
        })
    if not entries:
        return {}
    market = {
        "name": repo.name,
        "interface": {"displayName": repo.name.title()},
        "plugins": entries,
    }
    return {".agents/plugins/marketplace.json": json.dumps(market, indent=2) + "\n"}


# --------------------------------------------------------------------------- #
# AGENTS.md — compact: reference modules (no @import, byte budget).
# --------------------------------------------------------------------------- #
IMPORT_RE = re.compile(r"^(\s*-\s*)?@(\S+?)(?:\s+[—-]\s+(.*))?\s*$")


def gen_agents_md(repo: Path) -> dict[str, str]:
    claude = repo / "CLAUDE.md"
    if not claude.exists():
        return {}
    out = [
        "<!-- GENERATED by codex-sync.py — DO NOT EDIT. Canonical: CLAUDE.md -->",
        "<!-- No @import + project_doc_max_bytes (~32-64 KiB): modules are REFERENCED,",
        "     not inlined. Read the listed paths on demand. -->",
        "",
    ]
    for line in claude.read_text(encoding="utf-8").splitlines():
        m = IMPORT_RE.match(line)
        if not m:
            out.append(line)
            continue
        rel, desc = m.group(2), (m.group(3) or "").strip()
        title = rel.rsplit("/", 1)[-1]
        out.append(f"- **{title}** — `{rel}`" + (f" — {desc}" if desc else ""))
    content = "\n".join(out).rstrip() + "\n"
    size = len(content.encode("utf-8"))
    if size > AGENTS_MAX_BYTES:
        content += f"\n<!-- WARNING: {size} bytes > {AGENTS_MAX_BYTES} budget; trim CLAUDE.md. -->\n"
    return {"AGENTS.md": content}


# --------------------------------------------------------------------------- #
def gen_notes(repo: Path) -> dict[str, str]:
    hooks = sorted(repo.glob("plugins/*/hooks/hooks.json"))
    scripts = sorted(p.name for p in (repo / "shared" / "scripts").glob("*.py")) \
        if (repo / "shared" / "scripts").is_dir() else []
    out = [
        "# Codex layer notes",
        "",
        "GENERATED by codex-sync.py. The Claude Code plugins are mirrored as native",
        "Codex plugins (`.agents/plugins/marketplace.json` + `plugins/*/.codex-plugin/`).",
        "Skills are unchanged — `plugins/*/skills/*/SKILL.md` is the same path in Codex.",
        "",
        "## Install",
        "",
        "```",
        f"codex plugin marketplace add <repo>/.agents/plugins/marketplace.json",
        f"codex plugin list",
        "```",
        "",
        "## Hooks",
        "",
    ]
    if hooks:
        out.append("`hooks` is rejected from plugin.json by Codex's validator. These Claude")
        out.append("hooks remain as companion folders (auto-discovered; same 10-event schema):")
        out += [f"- `{h.relative_to(repo).as_posix()}`" for h in hooks]
        out.append("Note: commands using `${CLAUDE_PLUGIN_ROOT}` won't expand under Codex — rewrite to MCP/absolute.")
    else:
        out.append("None.")
    out += ["", "## Scripts → MCP (CLAUDE_PLUGIN_ROOT has no Codex equivalent)", ""]
    if scripts:
        out.append("Expose these via a per-plugin `.mcp.json` companion + `mcpServers` manifest key:")
        out += [f"- `shared/scripts/{s}`" for s in scripts]
    else:
        out.append("None.")
    out.append("")
    return {".codex/CODEX-NOTES.md": "\n".join(out)}


# --------------------------------------------------------------------------- #
def build(repo: Path) -> dict[str, str]:
    artifacts: dict[str, str] = {}
    artifacts.update(gen_marketplace(repo))
    artifacts.update(gen_plugin_manifests(repo))
    artifacts.update(gen_mcp(repo))
    artifacts.update(gen_agents_md(repo))
    artifacts.update(gen_notes(repo))
    return artifacts


def main() -> int:
    ap = argparse.ArgumentParser(description="Derive a Codex plugin layer from Claude Code source.")
    ap.add_argument("repo")
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    repo = Path(args.repo).resolve()
    if not (repo / "CLAUDE.md").exists():
        print(f"ERR: {repo}/CLAUDE.md not found", file=sys.stderr)
        return 2

    artifacts = build(repo)
    changed = []
    for rel, content in sorted(artifacts.items()):
        dest = repo / rel
        existing = dest.read_text(encoding="utf-8") if dest.exists() else None
        if existing != content:
            changed.append(rel)
            if not args.check:
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_text(content, encoding="utf-8")

    if args.check:
        if changed:
            print("DRIFT — run codex-sync.py. Changed:")
            for c in changed:
                print(f"  {c}")
            return 1
        print(f"{repo.name}: Codex layer in sync ({len(artifacts)} artifacts)")
        return 0

    print(f"{repo.name}: wrote {len(changed)}/{len(artifacts)} artifacts")
    for c in changed:
        print(f"  + {c}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
