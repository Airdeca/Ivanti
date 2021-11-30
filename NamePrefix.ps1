<#
30-11-2021 Rob de Korte
This script strips the prefix (tussenvoegsel) off a SurName and generates a UserName out of the 'short' SurName
Doesn't work very well yet with double SurNames. (Freule van Voorst tot Voorst messes things up royally)
#>

# Input Variables
$GivenName = "Freule"
$SurName = "van Voorst tot Voorst"

# Chop it up
$SurArray = $SurName.Split(" ")
$SurShort = $SurArray[-1]    # Assume that the last word in the name is the actual SurName (not always true)
$Prefix = $SurName.Replace($SurShort,"")   # the prefix must be anything but the last word, then  (again, not always true)
$DisplayName = "$GivenName $Prefix$SurShort"
$UserLogonName = ("$SurShort$($GivenName.Substring(0,1))").ToLower()

Write-Host "Display Name is: $DisplayName"
Write-Host "User Name is: $UserLogonName"