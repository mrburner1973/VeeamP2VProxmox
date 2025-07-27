# Example# Example 1: Update CPU cores only
Write-Host "Example 1: Update to 16 CPU cores only" -ForegroundColor Yellow
Write-Host "Command: .\Update-VeeamSystemConfig.ps1 -FilePath '$vbmFile' -NewCoreCount 16" -ForegroundColor Gray
Write-Host ""

# Example 2: Update RAM only
Write-Host "Example 2: Update to 32GB RAM only" -ForegroundColor Yellow
Write-Host "Command: .\Update-VeeamSystemConfig.ps1 -FilePath '$vbmFile' -NewRamSizeMB 32768" -ForegroundColor Gray
Write-Host ""

# Example 3: Update both CPU and RAM
Write-Host "Example 3: Update to 8 cores and 16GB RAM" -ForegroundColor Yellow
Write-Host "Command: .\Update-VeeamSystemConfig.ps1 -FilePath '$vbmFile' -NewCoreCount 8 -NewRamSizeMB 16384" -ForegroundColor Gray
Write-Host ""

# Example 4: Just CPU change to test basic functionality
Write-Host "Example 4: Simple CPU update" -ForegroundColor Yellow
Write-Host "Command: .\Update-VeeamSystemConfig.ps1 -FilePath '$vbmFile' -NewCoreCount 4" -ForegroundColor GrayUpdate-VeeamSystemConfig.ps1
# This script demonstrates different ways to use the CPU and RAM updater

Write-Host "=== Veeam VBM System Configuration Updater - Usage Examples ===" -ForegroundColor Cyan
Write-Host ""

# Set the path to your VBM file
$vbmFile = "./Kerserv -.vbm.old1"  # Adjust this path as needed

# Example 1: Update CPU cores only
Write-Host "Example 1: Update to 16 CPU cores only" -ForegroundColor Yellow
Write-Host "Command: .\Update-VeeamCPUCores.ps1 -FilePath '$vbmFile' -NewCoreCount 16" -ForegroundColor Gray
Write-Host ""

# Example 2: Update RAM only
Write-Host "Example 2: Update to 32GB RAM only" -ForegroundColor Yellow
Write-Host "Command: .\Update-VeeamCPUCores.ps1 -FilePath '$vbmFile' -NewRamSizeMB 32768" -ForegroundColor Gray
Write-Host ""

# Example 3: Update both CPU and RAM
Write-Host "Example 3: Update to 8 cores and 16GB RAM" -ForegroundColor Yellow
Write-Host "Command: .\Update-VeeamCPUCores.ps1 -FilePath '$vbmFile' -NewCoreCount 8 -NewRamSizeMB 16384" -ForegroundColor Gray
Write-Host ""

# Example 4: Update to 4 cores
Write-Host "Example 4: Update to 4 cores" -ForegroundColor Yellow
Write-Host "Command: .\Update-VeeamCPUCores.ps1 -FilePath '$vbmFile' -NewCoreCount 4" -ForegroundColor Gray
Write-Host ""

Write-Host "=== Interactive Mode ===" -ForegroundColor Cyan
Write-Host ""

# Interactive mode
$runNow = Read-Host "Do you want to run the script now? (y/N)"

if ($runNow -eq 'y' -or $runNow -eq 'Y') {
    # Check if the main script exists
    if (-not (Test-Path "./Update-VeeamSystemConfig.ps1")) {
        Write-Error "Update-VeeamSystemConfig.ps1 not found in current directory"
        exit 1
    }
    
    # Check if the VBM file exists
    if (-not (Test-Path $vbmFile)) {
        Write-Error "VBM file not found: $vbmFile"
        Write-Host "Please update the `$vbmFile variable in this script with the correct path" -ForegroundColor Yellow
        exit 1
    }
    
    # Get user input
    $newCores = Read-Host "Enter the new number of CPU cores (press Enter to skip)"
    $newRamMB = Read-Host "Enter the new RAM size in MB (press Enter to skip)"
    
    # Validate input
    $coreParam = ""
    $ramParam = ""
    
    if ($newCores -and $newCores -ne "") {
        if ($newCores -notmatch '^\d+$' -or [int]$newCores -lt 1 -or [int]$newCores -gt 128) {
            Write-Error "Invalid core count. Please enter a number between 1 and 128."
            exit 1
        }
        $coreParam = "-NewCoreCount $newCores"
    }
    
    if ($newRamMB -and $newRamMB -ne "") {
        if ($newRamMB -notmatch '^\d+$' -or [int]$newRamMB -lt 128 -or [int]$newRamMB -gt 1048576) {
            Write-Error "Invalid RAM size. Please enter a number between 128 and 1,048,576 MB."
            exit 1
        }
        $ramParam = "-NewRamSizeMB $newRamMB"
    }
    
    if (-not $coreParam -and -not $ramParam) {
        Write-Error "At least one parameter must be specified (CPU cores or RAM size)."
        exit 1
    }
    
    $commandParams = "$coreParam $ramParam".Trim()
    
    Write-Host ""
    Write-Host "Executing: .\Update-VeeamSystemConfig.ps1 -FilePath '$vbmFile' $commandParams" -ForegroundColor Green
    Write-Host ""
    
    # Execute the main script
    $scriptBlock = "& `"./Update-VeeamSystemConfig.ps1`" -FilePath `"$vbmFile`" $commandParams"
    Invoke-Expression $scriptBlock
} else {
    Write-Host "Script execution cancelled." -ForegroundColor Yellow
    Write-Host "You can run the script manually using one of the examples above." -ForegroundColor Gray
}
