# Example usage script for Update-VeeamCPUCores.ps1
# This script demonstrates different ways to use the CPU core updater

Write-Host "=== Veeam VBM CPU Core Updater - Usage Examples ===" -ForegroundColor Cyan
Write-Host ""

# Set the path to your VBM file
$vbmFile = "./Kerserv -.vbm.old1"  # Adjust this path as needed

# Example 1: Update to 16 cores
Write-Host "Example 1: Update to 16 cores" -ForegroundColor Yellow
Write-Host "Command: .\Update-VeeamCPUCores.ps1 -FilePath '$vbmFile' -NewCoreCount 16" -ForegroundColor Gray
Write-Host ""

# Example 2: Update to 8 cores
Write-Host "Example 2: Update to 8 cores" -ForegroundColor Yellow
Write-Host "Command: .\Update-VeeamCPUCores.ps1 -FilePath '$vbmFile' -NewCoreCount 8" -ForegroundColor Gray
Write-Host ""

# Example 3: Update to 24 cores
Write-Host "Example 3: Update to 24 cores" -ForegroundColor Yellow
Write-Host "Command: .\Update-VeeamCPUCores.ps1 -FilePath '$vbmFile' -NewCoreCount 24" -ForegroundColor Gray
Write-Host ""

Write-Host "=== Interactive Mode ===" -ForegroundColor Cyan
Write-Host ""

# Interactive mode
$runNow = Read-Host "Do you want to run the script now? (y/N)"

if ($runNow -eq 'y' -or $runNow -eq 'Y') {
    # Check if the main script exists
    if (-not (Test-Path "./Update-VeeamCPUCores.ps1")) {
        Write-Error "Update-VeeamCPUCores.ps1 not found in current directory"
        exit 1
    }
    
    # Check if the VBM file exists
    if (-not (Test-Path $vbmFile)) {
        Write-Error "VBM file not found: $vbmFile"
        Write-Host "Please update the `$vbmFile variable in this script with the correct path" -ForegroundColor Yellow
        exit 1
    }
    
    # Get user input
    $newCores = Read-Host "Enter the new number of CPU cores (1-128)"
    
    # Validate input
    if (-not $newCores -or $newCores -notmatch '^\d+$' -or [int]$newCores -lt 1 -or [int]$newCores -gt 128) {
        Write-Error "Invalid core count. Please enter a number between 1 and 128."
        exit 1
    }
    
    Write-Host ""
    Write-Host "Executing: .\Update-VeeamCPUCores.ps1 -FilePath '$vbmFile' -NewCoreCount $newCores" -ForegroundColor Green
    Write-Host ""
    
    # Execute the main script
    & "./Update-VeeamCPUCores.ps1" -FilePath $vbmFile -NewCoreCount ([int]$newCores)
} else {
    Write-Host "Script execution cancelled." -ForegroundColor Yellow
    Write-Host "You can run the script manually using one of the examples above." -ForegroundColor Gray
}
