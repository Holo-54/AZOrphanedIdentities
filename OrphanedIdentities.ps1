# Define output directory for CSV (defaults to current folder)
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputDirectory = $PWD.Path,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Pre-check for required Azure PowerShell (Az) module - fail early if missing
$requiredModules = @('Az')
$missing = $requiredModules | Where-Object { -not (Get-Module -ListAvailable -Name $_) }
if ($missing) {
    Write-Error "Required module(s) not found: $($missing -join ', '). Install with: Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force"
    exit 1
}

# Prepare output file path and handle dry-run
$timestamp = Get-Date -Format 'MMddyyyy_HH-mm'
$fileName = "OrphanedIdentities_$($timestamp).csv"
$fullPath = Join-Path -Path $OutputDirectory -ChildPath $fileName
if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}
if ($DryRun) {
    Write-Output "Dry run: creating empty CSV at $fullPath"
    @() | Export-Csv -Path $fullPath -NoTypeInformation
    exit 0
}

# Grab all sytem-assigned managed identities
$allManagedIdentities = Get-AzADServicePrincipal -Filter "servicePrincipalType eq 'ManagedIdentity' and alternativeNames/any(x:x eq 'isExplicit=False')" # Looking for system assigned (isExplicit=False) managed identities
$orphanedIdentities = New-Object -TypeName System.Collections.ArrayList # Empty array for compiling list
foreach($identity in $allManagedIdentities) {
    $index = [Array]::FindIndex($identity.AlternativeName, [Predicate[string]]{ param($item) $item -like "*/subscriptions/*" }) # Some identities have the resource ID in a different position. Grabbing the position here
    $ResourceID = $identity.AlternativeName[$index] # Grabbing Azure Resource ID field
    if (!($ResourceID -match "blueprintAssignments|policyAssignments|dataScanners|securityOperators")) { # These resources in the match parameter cannot be found with Get-AzResource
        try {
            $resource = Get-AzResource -ResourceId "$($ResourceID)" -ErrorAction Stop # Check if resource exists. Error typically = orphaned
            if ($resource) {
                Write-Output "Linked Azure resource found for $($identity.DisplayName)"
                $exists = $true
            }
        } catch {
            Write-Output "Azure resource not found for $($identity.DisplayName)"
            $exists = $false
        }
    } else {continue} # Continue if resource is Blueprint, Policy Assignment, Data Scanner, or Security Operator
    $currentIdentity = [PSCustomObject]@{ # Throw everything into a custom object to append to the running list
        ApplicationId = $identity.AppId
        ObjectId = $identity.Id 
        ManagedIdentityName = $identity.DisplayName
        AzureResourceID = $ResourceID
        Exists = $exists
    }
    $orphanedIdentities.Add($currentIdentity) | Out-Null
}
$orphanedIdentities | Export-Csv -Path $fullPath -NoTypeInformation
