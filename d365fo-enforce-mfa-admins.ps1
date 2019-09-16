Param
(
  [Parameter (Mandatory= $true)]
  [String] $upn = "d365fo-adm-mfatest@mypubliccloud.onmicrosoft.com"
)

# Import automation credential
$cred = Get-AutomationPSCredential -Name "cred"

# Connect to O365
Connect-MsolService -Credential $cred
Write-Verbose -Message "Connected to Azure AD!"

# Set vars
$auth = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$auth.RelyingParty = "*"
$auth.State = "Enforced"
$auth.RememberDevicesNotIssuedBefore = (Get-Date)
$defaultdomain = (get-msoldomain | Where-Object { $_.IsDefault -eq $True}).Name

######################################
# Start script execution
######################################

# Try to modify user directly
try {
    Write-Verbose "Trying to enable MFA on UPN: $upn"
    Set-MsolUser -UserPrincipalName $upn -StrongAuthenticationRequirements $auth -ErrorAction Stop
}

# If upn couldn't be found
catch {
    # Clear error history
    $error.clear()

    # Transform UPN to external guest format 
    $extupn = (($upn.Replace("@","_")) + "#EXT#@" + $defaultdomain)

    # Log progress
    Write-Verbose "UPN '$upn' could not be found. Trying to use external guest format: '$extupn'"

    # Try if UPN can be found using external guest format
    try {
        Set-MsolUser -UserPrincipalName $extupn -StrongAuthenticationRequirements $auth -ErrorAction Stop
    }

    # If external UPN also couldn't  be found, user seems to be non-existing in this AAD directory
    catch {
        # Log exit message
        write-error -Message "Input UPN '$upn' could not be found in directory $defaultdomain! Script is now going to end..."
        exit
    }
}

if (!$error) {
    # Log exit message
    write-output "Modified user with UPN '$upn' successfully!"
}
else {
    # Log exit message
    write-error "Script ended with unexpected errors. Check logs."
    exit
}

write-output "Script ended."
