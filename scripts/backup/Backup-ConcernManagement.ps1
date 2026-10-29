[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$BackupRoot,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ClientOptionsFile,

    [ValidatePattern('^[A-Za-z0-9_]+$')]
    [string]$DatabaseName = 'concern_management',

    [string]$DumpExecutable = 'C:\xampp\mysql\bin\mysqldump.exe',

    [string]$ConcernUploadsDirectory,

    [ValidateRange(1, 3650)]
    [int]$RetentionDays = 14
)

$ErrorActionPreference = 'Stop'
$backupPrefix = 'concern-management_'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

if ([string]::IsNullOrWhiteSpace($ConcernUploadsDirectory)) {
    if (-not [string]::IsNullOrWhiteSpace($env:CONCERN_UPLOAD_DIR)) {
        $ConcernUploadsDirectory = $env:CONCERN_UPLOAD_DIR
    } else {
        $ConcernUploadsDirectory = Join-Path $projectRoot 'data\uploads\concerns'
    }
}

if (-not [System.IO.Path]::IsPathRooted($ConcernUploadsDirectory)) {
    $ConcernUploadsDirectory = Join-Path $projectRoot $ConcernUploadsDirectory
}

if (-not [System.IO.Path]::IsPathRooted($BackupRoot)) {
    throw 'BackupRoot must be an absolute path, such as E:\ConcernManagementBackups.'
}

if (-not [System.IO.Path]::IsPathRooted($ClientOptionsFile)) {
    throw 'ClientOptionsFile must be an absolute path.'
}

if (-not [System.IO.Path]::IsPathRooted($DumpExecutable)) {
    throw 'DumpExecutable must be an absolute path.'
}

if (-not (Test-Path -LiteralPath $DumpExecutable -PathType Leaf)) {
    throw "MariaDB dump utility not found at '$DumpExecutable'. Pass the correct path using -DumpExecutable."
}

if (-not (Test-Path -LiteralPath $ClientOptionsFile -PathType Leaf)) {
    throw "MariaDB client options file not found at '$ClientOptionsFile'. Create a protected [client] options file as described in docs/backup-restore.md."
}

if (-not (Test-Path -LiteralPath $ConcernUploadsDirectory -PathType Container)) {
    throw "Concern uploads directory not found at '$ConcernUploadsDirectory'. Pass the configured folder using -ConcernUploadsDirectory."
}

$BackupRoot = [System.IO.Path]::GetFullPath($BackupRoot)
$ConcernUploadsDirectory = [System.IO.Path]::GetFullPath($ConcernUploadsDirectory)
$projectRootWithSeparator = $projectRoot.TrimEnd('\') + '\'
if (
    $BackupRoot.Equals($projectRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
    $BackupRoot.StartsWith($projectRootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)
) {
    throw 'BackupRoot must be outside the application folder. Use a separate drive or network backup location.'
}

$concernUploadsWithSeparator = $ConcernUploadsDirectory.TrimEnd('\') + '\'
if (
    $BackupRoot.Equals($ConcernUploadsDirectory, [System.StringComparison]::OrdinalIgnoreCase) -or
    $BackupRoot.StartsWith($concernUploadsWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)
) {
    throw 'BackupRoot cannot be the concern uploads folder or a folder inside it. Choose a separate backup location to prevent recursive copies.'
}

New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupDirectory = Join-Path $BackupRoot "$backupPrefix$timestamp"
$uploadBackupDirectory = Join-Path $backupDirectory 'uploads\concerns'
$dumpPath = Join-Path $backupDirectory "$DatabaseName.sql"

if (Test-Path -LiteralPath $backupDirectory) {
    throw "A backup folder already exists for this timestamp: '$backupDirectory'. Run the script again in a moment."
}

New-Item -ItemType Directory -Path $uploadBackupDirectory -Force | Out-Null

try {
    Write-Host "Dumping MariaDB database '$DatabaseName'..."
    $dumpArguments = @(
        "--defaults-extra-file=$ClientOptionsFile",
        '--single-transaction',
        '--quick',
        '--routines',
        '--events',
        '--hex-blob',
        "--result-file=$dumpPath",
        $DatabaseName
    )

    & $DumpExecutable @dumpArguments
    if ($LASTEXITCODE -ne 0) {
        throw "mysqldump exited with code $LASTEXITCODE. Check the MariaDB options file and database permissions."
    }
    if (-not (Test-Path -LiteralPath $dumpPath -PathType Leaf) -or (Get-Item -LiteralPath $dumpPath).Length -eq 0) {
        throw 'The SQL dump was not created or is empty.'
    }

    Write-Host 'Copying concern uploads...'
    Get-ChildItem -LiteralPath $ConcernUploadsDirectory -Force |
        Copy-Item -Destination $uploadBackupDirectory -Recurse -Force

    $manifest = @(
        "Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')",
        "Database: $DatabaseName",
        "Concern uploads source: $ConcernUploadsDirectory",
        "SQL dump: $(Split-Path -Leaf $dumpPath)",
        "Retention days: $RetentionDays"
    )
    Set-Content -LiteralPath (Join-Path $backupDirectory 'backup-info.txt') -Value $manifest -Encoding UTF8

    Write-Host "Backup completed: $backupDirectory"

    $retentionCutoff = (Get-Date).AddDays(-$RetentionDays)
    try {
        Get-ChildItem -LiteralPath $BackupRoot -Directory -Filter "$backupPrefix*" |
            Where-Object {
                if ($_.Name -match '^concern-management_(\d{8}_\d{6})$') {
                    $createdAt = [datetime]::ParseExact(
                        $Matches[1],
                        'yyyyMMdd_HHmmss',
                        [System.Globalization.CultureInfo]::InvariantCulture
                    )
                    return $createdAt -lt $retentionCutoff
                }
                return $false
            } |
            Remove-Item -Recurse -Force -ErrorAction Stop

        Write-Host "Removed backups older than $RetentionDays days, if any."
    } catch {
        Write-Warning "Backup succeeded, but old backup cleanup failed: $($_.Exception.Message)"
    }
} catch {
    if (Test-Path -LiteralPath $backupDirectory) {
        Remove-Item -LiteralPath $backupDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
    throw
}
