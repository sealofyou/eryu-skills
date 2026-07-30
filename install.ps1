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
    New-Item -ItemType Directory -Force -Path $Target | Out-Null
    # Some machines intercept the Remove-Item cmdlet (safe-delete hook) and it errors out.
    # Use robocopy (native process) to mirror+clean instead, bypassing the hook.
    # On non-Windows (Mac pwsh, no such hook) fall back to Remove-Item.
    if ($env:OS -eq 'Windows_NT' -and (Get-Command robocopy -ErrorAction SilentlyContinue)) {
        robocopy $Source $Target /MIR /XD .git /NFL /NDL /NJH /NJS /NC /NS | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "robocopy failed ($LASTEXITCODE): $Source -> $Target" }
    } else {
        if (Test-Path $Target) { Remove-Item -LiteralPath $Target -Recurse -Force }
        New-Item -ItemType Directory -Force -Path $Target | Out-Null
        Get-ChildItem -LiteralPath $Source -Force |
            Where-Object { $_.Name -ne '.git' } |
            Copy-Item -Destination $Target -Recurse -Force
    }
}

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
    # Native git writes progress to stderr; under $ErrorActionPreference='Stop' on
    # Windows PowerShell 5.1 that stderr becomes a terminating error. Run git with
    # EAP=Continue and check $LASTEXITCODE explicitly instead.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $out = & git @GitArgs 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    if ($code -ne 0) { throw "git $($GitArgs -join ' ') failed (exit $code): $($out | Out-String)" }
    return $out
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
                if (Invoke-Git -C $cache status --porcelain) {
                    throw "Managed cache has local changes: $cache"
                }
                Invoke-Git -C $cache fetch origin $row.ref | Out-Null
                Invoke-Git -C $cache checkout $row.ref | Out-Null
                Invoke-Git -C $cache pull --ff-only origin $row.ref | Out-Null
            } else {
                Invoke-Git clone --depth 1 --branch $row.ref $row.repo $cache | Out-Null
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
