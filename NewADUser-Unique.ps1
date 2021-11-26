<#
26-11-2021 Rob de Korte

Generates a unique user account to be entered in Active Directory. The in- and output is optimised for use in an Ivanti Automation module.
This script takes a User Name and checks whether it exists in AD. If it does, it adds a Sequence Number ($SN) to the name and tries again.
It keeps incrementing the SN until there is no match in AD and we have a unique name.
Some considerations:
        Although there is no limit to the SN, the two digit format assumes that it won't go past 99. However, it is easy to add another 0 to the format.
        The scripts assumes that User Accounts are not deleted from AD, to avoid reusing old user names.
        There's no error handling (yet) in case the query to AD fails.

#>

$NewUserName = "$[UserLogonName]" #if it runs in Automation

# Make sure the proper Module is loaded.
Import-Module ActiveDirectory

# Check if the basic UserName exists before we start adding counters
$Result=Get-ADUser -Filter 'sAMAccountName -like $NewUserName'
if (($Result | measure-object).Count -eq 0)
{
    $Global:UserLogonName = $NewUserName # Write the unchanged UserLogonName back to the Automation Parameter
}
else
{
    # Add & increment a Counter by 1 and try again
    $i=1
    do
        {
        $SN = $i.ToString("00")    # Make sure the Sequence Number has at least 2 digits (leading zeros)
        $UserName = "$NewUserName$SN"    # Concatenate the UserName and the SN
        $Result = Get-ADUser -Filter "sAMAccountName -like ""$UserName"""    # Check if the altered User Name exists
        # $UserName
        $i++    # Increment the SN for a potential next attempt
        }
        # Until there is no match and we have a unique UserName
        until (($Result | measure-object).Count -eq 0)

    # Write the new UserLogonName back to the Automation Parameter
    $Global:UserLogonName = $UserName
}


