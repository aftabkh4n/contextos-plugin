# Windows counterpart of ensure-binary.sh, for machines without Git Bash.
# Written for Windows PowerShell 5.1, which every Windows 10 and 11 machine has.
#
# Same rules as the bash script:
# - Each version installs into its own folder (bin\<version>) and plugin.json
#   points at that folder. A folder is never replaced, so nothing here can
#   touch a binary another Claude Code window is running. Never kill processes.
# - Every failure exits 0: a failed install must not block Claude Code.
# - .version is written with a plain LF and no BOM, so the bash script reads
#   the same value and the two scripts never reinstall each other's work.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Note([string]$Message) {
    [Console]::Error.WriteLine("ContextOS: $Message")
}

function Read-VersionFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    try { return ([IO.File]::ReadAllText($Path)).Trim() } catch { return '' }
}

# Delete every version folder except the current one and the newest older
# one (another window may still run it), plus the pre-0.2.3 flat layout.
# Errors are ignored: a folder still in use stays until a later session.
function Invoke-Cleanup([string]$BinRoot, [string]$Version, [string]$PluginData) {
    try {
        $current = [version]$Version
        $older = @(Get-ChildItem -LiteralPath $BinRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^\d+(\.\d+)+$' } |
            Where-Object { [version]$_.Name -lt $current } |
            Sort-Object { [version]$_.Name } -Descending)
        $keepPrevious = ''
        if ($older.Count -gt 0) { $keepPrevious = $older[0].Name }

        foreach ($entry in @(Get-ChildItem -LiteralPath $BinRoot -Force -ErrorAction SilentlyContinue)) {
            $name = $entry.Name
            if ($name -eq $Version -or $name -eq $keepPrevious -or $name.StartsWith("$Version.staging.")) {
                continue
            }
            Remove-Item -LiteralPath $entry.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
        foreach ($old in @('bin.staging', 'bin.old')) {
            Remove-Item -LiteralPath (Join-Path $PluginData $old) -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch {
        # Cleanup is best effort.
    }
}

$tmpDir = $null
$stagingDir = $null

try {
    # Git Bash, macOS and Linux use ensure-binary.sh. If this script ever runs
    # anywhere else (for example powershell.exe reached from WSL), do nothing.
    if ($env:OS -ne 'Windows_NT') { exit 0 }

    $pluginRoot = $env:CLAUDE_PLUGIN_ROOT
    $pluginData = $env:CLAUDE_PLUGIN_DATA
    if ([string]::IsNullOrEmpty($pluginRoot) -or [string]::IsNullOrEmpty($pluginData)) {
        Write-Note 'CLAUDE_PLUGIN_ROOT or CLAUDE_PLUGIN_DATA is not set, skipping install'
        exit 0
    }

    # plugin.json is the single source for the binary version.
    $manifest = Join-Path $pluginRoot '.claude-plugin\plugin.json'
    $version = ''
    try { $version = [string](Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json).version } catch { }
    if ($version -notmatch '^\d+(\.\d+)+$') {
        Write-Note 'could not read version from plugin.json'
        exit 0
    }

    $binRoot = Join-Path $pluginData 'bin'
    $target = Join-Path $binRoot $version

    if ((Read-VersionFile (Join-Path $target '.version')) -eq $version) {
        Invoke-Cleanup $binRoot $version $pluginData
        exit 0
    }

    $rid = 'win-x64'
    $archive = "contextos-$rid.zip"
    $url = "https://github.com/aftabkh4n/contextos/releases/download/v$version/$archive"

    # Windows PowerShell 5.1 can default to TLS 1.0, which GitHub refuses.
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch { }

    # Per-process staging folder, so two windows starting at once don't
    # extract into the same place.
    $stagingDir = "$target.staging.$PID"
    $tmpDir = Join-Path ([IO.Path]::GetTempPath()) ("contextos-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
    New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

    Write-Note "downloading binary $version for $rid..."
    $zip = Join-Path $tmpDir $archive
    try {
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    } catch {
        Write-Note "download of $url failed. Will retry at the next session start."
        exit 0
    }

    # Drop the top-level RID folder. Binary and Models\ must sit side by side
    # (OnnxMiniLmProvider looks for .\Models next to the exe).
    try {
        Expand-Archive -LiteralPath $zip -DestinationPath $tmpDir -Force
        Copy-Item -Path (Join-Path (Join-Path $tmpDir $rid) '*') -Destination $stagingDir -Recurse -Force
    } catch {
        Write-Note "extracting $archive failed. Will retry at the next session start."
        exit 0
    }

    $exe = Join-Path $stagingDir 'contextos.exe'
    $ran = $false
    try {
        & $exe --version *> $null
        $ran = ($LASTEXITCODE -eq 0)
    } catch { }
    if (-not $ran) {
        Write-Note "downloaded binary $version did not run (--version failed). Will retry at the next session start."
        exit 0
    }

    # .version goes in before the rename, so the target only ever appears complete.
    [IO.File]::WriteAllText((Join-Path $stagingDir '.version'), "$version`n", (New-Object Text.UTF8Encoding($false)))

    # Another window may have finished the same install while we downloaded.
    if ((Read-VersionFile (Join-Path $target '.version')) -ne $version) {
        try {
            # A target without .version is a leftover from an interrupted install.
            if (Test-Path -LiteralPath $target) {
                Remove-Item -LiteralPath $target -Recurse -Force
            }
            Move-Item -LiteralPath $stagingDir -Destination $target
            $stagingDir = $null
        } catch {
            Write-Note "could not move the new binary into $target. Will retry at the next session start."
            exit 0
        }
    }

    Write-Note "binary $version installed at $target"
    # SessionStart stdout is added to Claude's context.
    Write-Output "ContextOS was just updated to v$version. If the contextos MCP server shows as failed this session, tell the user to run /mcp and choose Reconnect."
    Invoke-Cleanup $binRoot $version $pluginData
} catch {
    Write-Note "install failed: $($_.Exception.Message). Will retry at the next session start."
} finally {
    if ($tmpDir) { Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
    if ($stagingDir) { Remove-Item -LiteralPath $stagingDir -Recurse -Force -ErrorAction SilentlyContinue }
}

exit 0
