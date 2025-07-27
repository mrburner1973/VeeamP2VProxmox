param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    
    [Parameter(Mandatory=$false)]
    [int]$NewCoreCount,
    
    [Parameter(Mandatory=$false)]
    [int]$NewRamSizeMB
)

<#
.SYNOPSIS
    Updates the CPU core count and/or RAM size in a Veeam VBM file.

.DESCRIPTION
    This script modifies the CPUInfo and/or RAMInfo sections in a Veeam backup metadata file (.vbm) 
    to change the number of CPU cores and/or RAM size. The original frequency values are preserved.

.PARAMETER FilePath
    Path to the VBM file to modify.

.PARAMETER NewCoreCount
    The new number of CPU cores to set (optional).

.PARAMETER NewRamSizeMB
    The new RAM size in MB to set (optional).

.EXAMPLE
    .\Update-VeeamCPUCores.ps1 -FilePath "C:\Path\To\File.vbm" -NewCoreCount 16
    
.EXAMPLE
    .\Update-VeeamCPUCores.ps1 -FilePath "C:\Path\To\File.vbm" -NewRamSizeMB 32768
    
.EXAMPLE
    .\Update-VeeamCPUCores.ps1 -FilePath "C:\Path\To\File.vbm" -NewCoreCount 8 -NewRamSizeMB 16384
#>

# Validate parameters
if (-not (Test-Path $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}

if (-not $NewCoreCount -and -not $NewRamSizeMB) {
    Write-Error "At least one parameter must be specified: -NewCoreCount or -NewRamSizeMB"
    exit 1
}

if ($NewCoreCount -and ($NewCoreCount -lt 1 -or $NewCoreCount -gt 128)) {
    Write-Error "Core count must be between 1 and 128"
    exit 1
}

if ($NewRamSizeMB -and ($NewRamSizeMB -lt 128 -or $NewRamSizeMB -gt 1048576)) {
    Write-Error "RAM size must be between 128 MB and 1,048,576 MB (1TB)"
    exit 1
}

Write-Host "Starting system configuration update process..." -ForegroundColor Green
Write-Host "File: $FilePath" -ForegroundColor Cyan
if ($NewCoreCount) { Write-Host "New Core Count: $NewCoreCount" -ForegroundColor Cyan }
if ($NewRamSizeMB) { Write-Host "New RAM Size: $NewRamSizeMB MB ($([math]::Round($NewRamSizeMB/1024, 2)) GB)" -ForegroundColor Cyan }

try {
    # Create backup
    $backupPath = $FilePath + ".backup_" + (Get-Date -Format "yyyyMMdd_HHmmss")
    Copy-Item $FilePath $backupPath
    Write-Host "Backup created: $backupPath" -ForegroundColor Yellow

    # Read file content
    Write-Host "Reading file content..." -ForegroundColor Gray
    $content = Get-Content $FilePath -Raw -Encoding UTF8

    # Process CPU changes if requested
    if ($NewCoreCount) {
        Write-Host "Processing CPU core changes..." -ForegroundColor Gray
        
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
        $cpuPattern = 'CPUInfo CoresCount=&quot;(\d+)&quot;&gt;&lt;(?:Core FrequencyMHz=&quot;(\d+)&quot; /&gt;&lt;)*/?CPUInfo'
        
        # Replace the CPUInfo section
        Write-Host "Updating CPUInfo sections..." -ForegroundColor Gray
        $content = $content -replace $cpuPattern, $newCPUInfo
    }

    # Process RAM changes if requested
    if ($NewRamSizeMB) {
        Write-Host "Processing RAM size changes..." -ForegroundColor Gray
        
        # Check if RAMInfo section exists
        if ($content -notmatch 'RAMInfo TotalSizeMB=&quot;(\d+)&quot;') {
            Write-Error "RAMInfo section not found in the file"
            exit 1
        }

        $currentRamSizeMB = [int]$matches[1]
        $currentRamSizeGB = [math]::Round($currentRamSizeMB/1024, 2)
        $newRamSizeGB = [math]::Round($NewRamSizeMB/1024, 2)
        Write-Host "Current RAM Size: $currentRamSizeMB MB ($currentRamSizeGB GB)" -ForegroundColor Yellow

        # Create regex pattern to match RAMInfo section
        $ramPattern = 'RAMInfo TotalSizeMB=&quot;(\d+)&quot;'
        
        # Build the new RAMInfo section
        $newRAMInfo = "RAMInfo TotalSizeMB=&quot;$NewRamSizeMB&quot;"
        
        # Replace the RAMInfo section
        Write-Host "Updating RAMInfo sections..." -ForegroundColor Gray
        $content = $content -replace $ramPattern, $newRAMInfo
    }

    # Verify the replacement was successful
    if ($content -eq (Get-Content $FilePath -Raw -Encoding UTF8)) {
        Write-Warning "No changes were made. Please check the file format."
        exit 1
    }

    # Write updated content back to file
    Write-Host "Writing updated content to file..." -ForegroundColor Gray
    Set-Content $FilePath $content -Encoding UTF8 -NoNewline

    # Verify the changes
    $verifyContent = Get-Content $FilePath -Raw -Encoding UTF8
    
    # Verify CPU changes if requested
    if ($NewCoreCount) {
        if ($verifyContent -match 'CPUInfo CoresCount=&quot;(\d+)&quot;') {
            $verifiedCoreCount = [int]$matches[1]
            if ($verifiedCoreCount -eq $NewCoreCount) {
                Write-Host "SUCCESS: CPU core count updated successfully!" -ForegroundColor Green
                Write-Host "Verified Core Count: $verifiedCoreCount" -ForegroundColor Green
            } else {
                Write-Error "CPU verification failed. Expected: $NewCoreCount, Found: $verifiedCoreCount"
                exit 1
            }
        } else {
            Write-Error "CPU verification failed. CPUInfo section not found after update."
            exit 1
        }
    }
    
    # Verify RAM changes if requested
    if ($NewRamSizeMB) {
        if ($verifyContent -match 'RAMInfo TotalSizeMB=&quot;(\d+)&quot;') {
            $verifiedRamSizeMB = [int]$matches[1]
            if ($verifiedRamSizeMB -eq $NewRamSizeMB) {
                $verifiedRamSizeGB = [math]::Round($verifiedRamSizeMB/1024, 2)
                Write-Host "SUCCESS: RAM size updated successfully!" -ForegroundColor Green
                Write-Host "Verified RAM Size: $verifiedRamSizeMB MB ($verifiedRamSizeGB GB)" -ForegroundColor Green
            } else {
                Write-Error "RAM verification failed. Expected: $NewRamSizeMB MB, Found: $verifiedRamSizeMB MB"
                exit 1
            }
        } else {
            Write-Error "RAM verification failed. RAMInfo section not found after update."
            exit 1
        }
    }

    # Count sections for verification
    if ($NewCoreCount) {
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
    }
    
    if ($NewRamSizeMB) {
        # Count the number of RAM sections
        $ramSectionMatches = ([regex]'RAMInfo TotalSizeMB=&quot;(\d+)&quot;').Matches($verifyContent)
        $ramSectionCount = $ramSectionMatches.Count
        
        Write-Host "RAM sections found: $ramSectionCount" -ForegroundColor Cyan
        Write-Host "All RAM sections updated to: $NewRamSizeMB MB ($([math]::Round($NewRamSizeMB/1024, 2)) GB)" -ForegroundColor Green
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
