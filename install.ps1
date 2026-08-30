# remove-codecv-watermark - one-line installer (Windows / PowerShell)
#
#   irm https://raw.githubusercontent.com/liangkingjin/codecv-watermark-skill/main/install.ps1 | iex
#
param(
    [switch]$All,
    [string[]]$Dir,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$Repo = 'liangkingjin/codecv-watermark-skill'
$Branch = 'main'
$SkillName = 'remove-codecv-watermark'

$Candidates = @(
    @{ Name = 'WorkBuddy';      Dir = (Join-Path $HOME '.workbuddy/skills') },
    @{ Name = 'Claude Code';    Dir = (Join-Path $HOME '.claude/skills') },
    @{ Name = 'CodeBuddy Code'; Dir = (Join-Path $HOME '.codebuddy/skills') },
    @{ Name = 'Cursor';         Dir = (Join-Path $HOME '.cursor/skills') },
    @{ Name = 'OpenCode';       Dir = (Join-Path $HOME '.config/opencode/skills') },
    @{ Name = 'Codex CLI';      Dir = (Join-Path $HOME '.codex/skills') },
    @{ Name = 'Gemini CLI';     Dir = (Join-Path $HOME '.gemini/skills') },
    @{ Name = 'Windsurf';       Dir = (Join-Path $HOME '.codeium/windsurf/skills') },
    @{ Name = 'Trae';           Dir = (Join-Path $HOME '.trae/skills') },
    @{ Name = 'GitHub Copilot'; Dir = (Join-Path $HOME '.copilot/skills') },
    @{ Name = 'Augment';        Dir = (Join-Path $HOME '.augment/skills') },
    @{ Name = 'Antigravity';    Dir = (Join-Path $HOME '.gemini/antigravity/skills') },
    @{ Name = 'Cline';          Dir = (Join-Path $HOME '.cline/skills') },
    @{ Name = 'Roo Code';       Dir = (Join-Path $HOME '.roo/skills') },
    @{ Name = 'Kilo Code';      Dir = (Join-Path $HOME '.kilocode/skills') },
    @{ Name = 'Continue';       Dir = (Join-Path $HOME '.continue/skills') },
    @{ Name = 'Qoder';          Dir = (Join-Path $HOME '.qoder/skills') },
    @{ Name = 'Qwen Code';      Dir = (Join-Path $HOME '.qwen/skills') },
    @{ Name = 'Universal (.agents)'; Dir = (Join-Path $HOME '.agents/skills') }
)

$Tmp = Join-Path $env:TEMP ("codecv-skill-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Tmp -Force | Out-Null

try {
    Write-Host "==> Fetching $Repo@$Branch ..."
    $Zip = Join-Path $Tmp 'repo.zip'
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri "https://codeload.github.com/$Repo/zip/refs/heads/$Branch" -OutFile $Zip
    Expand-Archive -Path $Zip -DestinationPath $Tmp -Force

    $Root = Join-Path $Tmp "codecv-watermark-skill-$Branch"
    $Src = Join-Path $Root "skill/$SkillName"
    if (-not (Test-Path (Join-Path $Src 'SKILL.md'))) {
        throw "skill files not found in the downloaded repository"
    }

    $Targets = @()
    if ($All) {
        $Targets = $Candidates
    } else {
        $Targets = $Candidates | Where-Object { Test-Path $_.Dir }
        if ($Targets.Count -eq 0) { $Targets = @($Candidates[0]) }
    }
    if ($Dir) { foreach ($d in $Dir) { $Targets += @{ Name = 'custom'; Dir = $d } } }

    $InstalledCount = 0
    foreach ($t in $Targets) {
        $dest = Join-Path $t.Dir $SkillName
        if ((Test-Path $dest) -and -not $Force) {
            Write-Host "==> Skipped (already exists): $dest  (use -Force to overwrite)"
            continue
        }
        New-Item -ItemType Directory -Path $t.Dir -Force | Out-Null
        if (Test-Path $dest) { Remove-Item -Recurse -Force $dest -ErrorAction SilentlyContinue }
        Copy-Item -Recurse -Path $Src -Destination $dest
        Write-Host "==> Installed [$($t.Name)]: $dest"
        $InstalledCount++
    }

    Write-Host ""
    Write-Host "Done. Installed into $InstalledCount tool(s)."
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Install the Python dependency:"
    Write-Host "     pip install -r `"$($Targets[0].Dir)\$SkillName\scripts\requirements.txt`""
    Write-Host "  2. In your AI coding tool, say:"
    Write-Host "     `"帮我去掉这份 CodeCV 简历的水印 @简历.pdf`""
} finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
