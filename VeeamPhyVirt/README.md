# Veeam VBM System Configuration Updater

This PowerShell script allows you to modify the CPU core count and/or RAM size in Veeam backup metadata (.vbm) files. It automatically updates both the configuration values and corresponding entries throughout the file.

## Files

- **Update-VeeamSystemConfig.ps1** - Main script for updating CPU cores and/or RAM
- **Example-Usage.ps1** - Interactive example script
- **README.md** - This documentation file

## Features

- ✅ Updates CPU core count in VBM files
- ✅ Updates RAM size in VBM files  
- ✅ Automatically adjusts the number of core entries
- ✅ Preserves original core frequency values
- ✅ Creates automatic backups before modification
- ✅ Validates changes after completion
- ✅ Error handling with backup restoration
- ✅ Supports core counts from 1 to 128
- ✅ Supports RAM sizes from 128 MB to 1 TB

## Requirements

- PowerShell 5.1 or later
- Read/write access to the VBM file
- Valid Veeam VBM file with CPUInfo section

## Usage

### Basic Usage

```powershell
# Update CPU cores only (preserves original frequency)
.\Update-VeeamSystemConfig.ps1 -FilePath "path\to\file.vbm" -NewCoreCount 16

# Update RAM only
.\Update-VeeamSystemConfig.ps1 -FilePath "path\to\file.vbm" -NewRamSizeMB 32768

# Update both CPU and RAM
.\Update-VeeamSystemConfig.ps1 -FilePath "path\to\file.vbm" -NewCoreCount 8 -NewRamSizeMB 16384
```

### Interactive Mode

Run the example script for guided usage:

```powershell
.\Example-Usage.ps1
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| FilePath | String | Yes | Path to the VBM file to modify |
| NewCoreCount | Integer | No* | New number of CPU cores (1-128) |
| NewRamSizeMB | Integer | No* | New RAM size in MB (128-1,048,576) |

*At least one of NewCoreCount or NewRamSizeMB must be specified.

## File Structure

The script looks for and modifies this XML structure in the VBM file:

**Before (32 cores, 64GB RAM):**
```xml
<RAMInfo TotalSizeMB="65536" />
<CPUInfo CoresCount="32">
  <Core FrequencyMHz="2800" />
  <Core FrequencyMHz="2800" />
  ... (32 total core entries)
</CPUInfo>
```

**After (16 cores, 32GB RAM, frequency preserved):**
```xml
<RAMInfo TotalSizeMB="32768" />
<CPUInfo CoresCount="16">
  <Core FrequencyMHz="2800" />
  <Core FrequencyMHz="2800" />
  ... (16 total core entries)
</CPUInfo>
```

Note: The actual format in the VBM file uses HTML entities (`&lt;`, `&gt;`, `&quot;`) instead of regular XML brackets.

## Safety Features

1. **Automatic Backup**: Creates a timestamped backup before making changes
2. **Validation**: Verifies the changes were applied correctly
3. **Error Recovery**: Restores backup if an error occurs
4. **Input Validation**: Checks parameters and file existence

## Example Output

```
Starting CPU core update process...
File: C:\Path\To\Kerserv -.vbm.old1
New Core Count: 16
Backup created: C:\Path\To\Kerserv -.vbm.old1.backup_20250727_143022
Current Core Count: 32
Original Core Frequency: 2800 MHz
Updating CPUInfo section...
Writing updated content to file...
SUCCESS: CPU core count updated successfully!
Verified Core Count: 16
Core entries found: 16
SUCCESS: All core entries match the specified count!

Update completed successfully!
Backup saved as: C:\Path\To\Kerserv -.vbm.old1.backup_20250727_143022
```

## Common Use Cases

1. **Reducing cores for smaller VMs**: Lower the core count when restoring to a system with fewer CPUs
2. **Increasing cores for performance**: Add more cores when restoring to a more powerful system
3. **Hardware compatibility**: Adjust core count to match target hardware specifications
4. **Standardization**: Ensure consistent CPU core counts across restored VMs

## Troubleshooting

### Error: "CPUInfo section not found"
- The VBM file may not contain the expected CPU information structure
- Verify this is a valid Veeam backup metadata file

### Error: "No changes were made"
- The file format may differ from expected
- Check that the file contains the correct XML structure with HTML entities

### Error: "Verification failed"
- The script couldn't verify the changes were applied
- Check the backup file and manually inspect the changes

## License

This script is provided as-is for educational and administrative purposes. Test thoroughly before using in production environments.

## Author

Created for Veeam VBM file management - July 2025
