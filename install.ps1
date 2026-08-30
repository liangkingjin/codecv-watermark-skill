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
    (Join-Path $HOME '.workbuddy/skills'),
    (Join-Path $HOME '.claude/skills'),
    (Join-Path $HOME '.codebuddy/skills'),
    (Join-Path $HOME '.cursor/skills')
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
        $Targets = $Candidates | Where-Object { Test-Path $_ }
        if ($Targets.Count -eq 0) { $Targets = @($Candidates[0]) }
    }
    if ($Dir) { $Targets += $Dir }

    foreach ($d in $Targets) {
        $dest = Join-Path $d $SkillName
        if ((Test-Path $dest) -and -not $Force) {
            Write-Host "==> Skipped (already exists): $dest  (use -Force to overwrite)"
            continue
        }
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
        Copy-Item -Recurse -Path $Src -Destination $dest
        Write-Host "==> Installed: $dest"
    }

    Write-Host ""
    Write-Host "Done."
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Install the Python dependency:"
    Write-Host "     pip install -r `"$($Targets[0])\$SkillName\scripts\requirements.txt`""
    Write-Host "  2. In your AI coding tool, say:"
    Write-Host "     `"帮我去掉这份 CodeCV 简历的水印 @简历.pdf`""
} finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
