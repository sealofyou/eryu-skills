param(
    [ValidateSet('core', 'content', 'slides', 'design', 'tools', 'media', 'all')]
    [string]$Profile = 'core',
    [string]$TargetRoot = (Join-Path $HOME '.codex\skills'),
    [string]$CacheRoot = (Join-Path $HOME '.cache\eryu-skills\repos')
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Manifest = Join-Path $RepoRoot 'skills.sources.csv'
New-Item -ItemType Directory -Force -Path $TargetRoot, $CacheRoot | Out-Null
$TargetRootFull = [IO.Path]::GetFullPath($TargetRoot).TrimEnd('\') + '\'

function Test-SelectedProfile([string]$RowProfile) {
    return $Profile -eq 'all' -or $RowProfile -eq 'core' -or $RowProfile -eq $Profile
}

function Test-SelectedPlatform([string]$RowPlatform) {
    $platform = if ([string]::IsNullOrWhiteSpace($RowPlatform)) { 'all' } else { $RowPlatform.ToLowerInvariant() }
    switch ($platform) {
        'all' { return $true }
        'windows' { return $env:OS -eq 'Windows_NT' }
        'macos' { return $env:OS -ne 'Windows_NT' }
        'linux' { return $false }
        default { throw "Unknown source platform: $RowPlatform" }
    }
}

function Copy-SkillTree([string]$Source, [string]$Target) {
    $targetFull = [IO.Path]::GetFullPath($Target)
    if (-not $targetFull.StartsWith($TargetRootFull, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to replace target outside ${TargetRoot}: $Target"
    }
    if (-not (Test-Path (Join-Path $Source 'SKILL.md'))) {
        throw "Skill source has no SKILL.md: $Source"
    }
    if (Test-Path $Target) {
        Remove-Item -LiteralPath $Target -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $Target | Out-Null
    Get-ChildItem -LiteralPath $Source -Force |
        Where-Object { $_.Name -ne '.git' } |
        Copy-Item -Destination $Target -Recurse -Force
}

$Rows = Import-Csv -LiteralPath $Manifest
$Prepared = @{}

foreach ($row in $Rows) {
    if (-not (Test-SelectedProfile $row.profile) -or -not (Test-SelectedPlatform $row.platform)) {
        continue
    }

    if ($row.kind -eq 'local') {
        $source = Join-Path $RepoRoot $row.subpath
    } elseif ($row.kind -eq 'git') {
        $cache = Join-Path $CacheRoot $row.cache_key
        if (-not $Prepared.ContainsKey($row.cache_key)) {
            if (Test-Path (Join-Path $cache '.git')) {
                if (git -C $cache status --porcelain) {
                    throw "Managed cache has local changes: $cache"
                }
                git -C $cache fetch origin $row.ref
                git -C $cache checkout $row.ref
                git -C $cache pull --ff-only origin $row.ref
            } else {
                git clone --depth 1 --branch $row.ref $row.repo $cache
            }
            $Prepared[$row.cache_key] = $cache
        }
        $source = if ($row.subpath -eq '.') { $cache } else { Join-Path $cache $row.subpath }
    } else {
        throw "Unknown source kind: $($row.kind)"
    }

    $target = Join-Path $TargetRoot $row.name
    Copy-SkillTree $source $target
    Write-Host "Installed $($row.name)"
}

Write-Host "Done. Restart Codex or the agent session to reload skills."
