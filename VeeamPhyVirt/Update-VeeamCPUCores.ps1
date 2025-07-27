param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    
    [Parameter(Mandatory=$true)]
    [int]$NewCoreCount
)

<#
.SYNOPSIS
    Updates the CPU core count in a Veeam VBM file.

.DESCRIPTION
    This script modifies the CPUInfo section in a Veeam backup metadata file (.vbm) 
    to change the number of CPU cores and adjusts the corresponding Core entries.
    The original frequency values are preserved.

.PARAMETER FilePath
    Path to the VBM file to modify.

.PARAMETER NewCoreCount
    The new number of CPU cores to set.

.EXAMPLE
    .\Update-VeeamCPUCores.ps1 -FilePath "C:\Path\To\File.vbm" -NewCoreCount 16
    
.EXAMPLE
    .\Update-VeeamCPUCores.ps1 -FilePath "C:\Path\To\File.vbm" -NewCoreCount 8
#>

# Validate parameters
if (-not (Test-Path $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}

if ($NewCoreCount -lt 1 -or $NewCoreCount -gt 128) {
    Write-Error "Core count must be between 1 and 128"
    exit 1
}

Write-Host "Starting CPU core update process..." -ForegroundColor Green
Write-Host "File: $FilePath" -ForegroundColor Cyan
Write-Host "New Core Count: $NewCoreCount" -ForegroundColor Cyan

try {
    # Create backup
    $backupPath = $FilePath + ".backup_" + (Get-Date -Format "yyyyMMdd_HHmmss")
    Copy-Item $FilePath $backupPath
    Write-Host "Backup created: $backupPath" -ForegroundColor Yellow

    # Read file content
    Write-Host "Reading file content..." -ForegroundColor Gray
    $content = Get-Content $FilePath -Raw -Encoding UTF8

    # Check if CPUInfo section exists
    if ($content -notmatch 'CPUInfo CoresCount=&quot;(\d+)&quot;') {
        Write-Error "CPUInfo section not found in the file"
        exit 1
    }

    $currentCoreCount = [int]$matches[1]
    Write-Host "Current Core Count: $currentCoreCount" -ForegroundColor Yellow

    # Extract the original frequency from the first core entry
    $originalFrequency = 2800  # Default fallback
    if ($content -match '&lt;Core FrequencyMHz=&quot;(\d+)&quot; /&gt;') {
        $originalFrequency = [int]$matches[1]
        Write-Host "Original Core Frequency: $originalFrequency MHz" -ForegroundColor Yellow
    }

    # Generate new core entries using the original frequency
    $coreEntries = @()
    for ($i = 1; $i -le $NewCoreCount; $i++) {
        $coreEntries += "&lt;Core FrequencyMHz=&quot;$originalFrequency&quot; /&gt;"
    }
    $newCoreString = $coreEntries -join ""

    # Build the new CPUInfo section
    $newCPUInfo = "CPUInfo CoresCount=&quot;$NewCoreCount&quot;&gt;$newCoreString&lt;/CPUInfo"

    # Create regex pattern to match the entire CPUInfo section
    $pattern = 'CPUInfo CoresCount=&quot;(\d+)&quot;&gt;&lt;(?:Core FrequencyMHz=&quot;(\d+)&quot; /&gt;&lt;)*/?CPUInfo'
    
    # Replace the CPUInfo section
    Write-Host "Updating CPUInfo section..." -ForegroundColor Gray
    $updatedContent = $content -replace $pattern, $newCPUInfo

    # Verify the replacement was successful
    if ($updatedContent -eq $content) {
        Write-Warning "No changes were made. Please check the file format."
        exit 1
    }

    # Write updated content back to file
    Write-Host "Writing updated content to file..." -ForegroundColor Gray
    Set-Content $FilePath $updatedContent -Encoding UTF8 -NoNewline

    # Verify the change
    $verifyContent = Get-Content $FilePath -Raw -Encoding UTF8
    if ($verifyContent -match 'CPUInfo CoresCount=&quot;(\d+)&quot;') {
        $verifiedCoreCount = [int]$matches[1]
        if ($verifiedCoreCount -eq $NewCoreCount) {
            Write-Host "SUCCESS: CPU core count updated successfully!" -ForegroundColor Green
            Write-Host "Verified Core Count: $verifiedCoreCount" -ForegroundColor Green
        } else {
            Write-Error "Verification failed. Expected: $NewCoreCount, Found: $verifiedCoreCount"
            exit 1
        }
    } else {
        Write-Error "Verification failed. CPUInfo section not found after update."
        exit 1
    }

    # Count the actual core entries to verify
    $coreMatches = ([regex]'&lt;Core FrequencyMHz=&quot;(\d+)&quot; /&gt;').Matches($verifyContent)
    $totalCoreEntries = $coreMatches.Count
    
    # Count the number of CPU sections
    $cpuSectionMatches = ([regex]'CPUInfo CoresCount=&quot;(\d+)&quot;').Matches($verifyContent)
    $cpuSectionCount = $cpuSectionMatches.Count
    
    Write-Host "CPU sections found: $cpuSectionCount" -ForegroundColor Cyan
    Write-Host "Total core entries found: $totalCoreEntries" -ForegroundColor Cyan
    
    $expectedTotalCores = $cpuSectionCount * $NewCoreCount
    if ($totalCoreEntries -eq $expectedTotalCores) {
        Write-Host "SUCCESS: All core entries across all CPU sections match the specified count!" -ForegroundColor Green
        Write-Host "($cpuSectionCount sections × $NewCoreCount cores = $expectedTotalCores total cores)" -ForegroundColor Green
    } else {
        Write-Host "INFO: Core entries verification - Expected: $expectedTotalCores ($cpuSectionCount sections × $NewCoreCount), Found: $totalCoreEntries" -ForegroundColor Yellow
        Write-Host "This may be normal if the file contains mixed CPU configurations." -ForegroundColor Yellow
    }

} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    
    # Restore backup if it exists
    if (Test-Path $backupPath) {
        Write-Host "Restoring backup..." -ForegroundColor Yellow
        Copy-Item $backupPath $FilePath -Force
        Write-Host "Backup restored." -ForegroundColor Yellow
    }
    exit 1
}

Write-Host "`nUpdate completed successfully!" -ForegroundColor Green
Write-Host "Backup saved as: $backupPath" -ForegroundColor Cyan
