# AZOrphanedIdentities
Powershell script to retrieve orphaned managed identities in Azure using the [Azure Powershell module](https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell?view=azps-14.1.0).
Tenant owners/admins are unable to delete orphaned identities and will need to reach out to Microsoft for deletion.

This script will grab all system-assigned managed identities and check if they exist using their Azure resource ID. Output will be in a CSV file containing the:
- Application ID
- Object ID
- Managed Identity Name
- Azure Resource ID
- Status (Exists)

## Running the script
1) Change the output path and file name variables to your desired output directory/file name
    - Output Directory: ```$outputFilePath```
      - **Line 2**
      - Format as directory path
          - Ex: ```C:\Temp```
    - Output File Name: ```$outputFileName```
      - **Line 3**
      - Ex: ```OrphanedIdentities```
      - Leave off the extension name! The ```.csv``` is already applied in the export on **line 32**
2) Connect to your Azure tenant: ```Connect-AzAccount```
3) Run the script
