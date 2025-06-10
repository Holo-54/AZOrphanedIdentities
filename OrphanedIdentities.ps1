# Define output file name/path of CSV below
$outputFilePath = "CHANGE\ME" # Path to output folder - Ex: "C:\Temp"
$outputFileName = "CHANGE_ME" # Output file name - Ex: "OrphanedIdentities"

# Grab all sytem-assigned managed identities
$allManagedIdentities = Get-AzADServicePrincipal -Filter "servicePrincipalType eq 'ManagedIdentity' and alternativeNames/any(x:x eq 'isExplicit=False')" # Looking for system assigned (isExplicit=False) managed identities
$orphanedIdentities = New-Object -TypeName System.Collections.ArrayList # Empty array for compiling list
foreach($identity in $allManagedIdentities) {
    $index = [Array]::FindIndex($identity.AlternativeName, [Predicate[string]]{ param($item) $item -like "*/subscriptions/*" }) # Some identities have the resource ID in a different position. Grabbing the position here
    $ResourceID = $identity.AlternativeName[$index] # Grabbing Azure Resource ID field
    if (!($ResourceID -match "blueprintAssignments|policyAssignments|dataScanners|securityOperators")) { # These resources cannot be found with Get-AzResource
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
$orphanedIdentities | Export-Csv -Path "$($outputFilePath)\$($outputFileName).csv" -NoTypeInformation