# AZOrphanedIdentities
Powershell script to retrieve orphaned managed identities in Azure using the [Azure Powershell module](https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell?view=azps-14.1.0).<br/>
Tenant owners/admins are unable to delete orphaned identities and will need to reach out to Microsoft for deletion.

This script will grab all system-assigned managed identities and check if they exist using their Azure resource ID. Output will be in a CSV file containing the:
- Application ID
- Object ID
- Managed Identity Name
- Azure Resource ID
- Status (Exists)

## Prerequisites
- Azure PowerShell module (`Az`)
- Permission to read managed identities in the tenant

## Running the script
> **Note:** Use `-DryRun` to validate output directory permissions
1) Connect to your Azure tenant: ```Connect-AzAccount```
2) Run the script

**Standard execution**
```
.\OrphanedIdentities.ps1
```
**Specify an output directory**
```
.\OrphanedIdentities.ps1 -OutputDirectory C:\Reports
```
**Dry run (validate output directory permissions)**
```
.\OrphanedIdentities.ps1 -OutputDirectory C:\Reports -DryRun
```

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `OutputDirectory` | String | No | Current directory | Directory where output files will be written |
| `DryRun` | Switch | No | False | Runs the script without querying Azure resources. Used to verify write access to the output directory. |