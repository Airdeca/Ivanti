#requires -version 5

<#

.SYNOPSIS

  This script retrieves the FileGuids of all User Settings from the Ivanti Workspace Control database



.DESCRIPTION

  This scripts runs a SQL query against the RES ONE Workspace datastore to retrieve all User Settings and their associated FileGUID and exports the complete list to a CSV file.
  The sqlserver module has to be installed in PowerShell for this script to run.



.PARAMETER DBServer

    This is the (DNS) name of the database instance.
    Default is "localhost"



.PARAMETER DBName

     This is the name of the Workspace database. The parameter is mandatory and there is no default value.



.PARAMETER DBAuth

    This parameter lets you determine what Authentication method is used to connect to the database.It supports 2 values: "SQL" and "Windows".
    When using "Windows", the logged on user's credentials are used to connect to the database and DBUser and DBPassword can be omitted.
    When using "SQL", DBUser and DBPassword are mandatory.
    Default is "Windows"



.PARAMETER DBPort

    This is the port the database instance listens on. This can be omitted if the database server listens to its default port (1433 for MSSQL).
    Default is blank



.PARAMETER DBUser

     This is the name of the SQL Login used to connect to the database. Only use this parameter when DBAuth equals "SQL", itg only accepts SQL logins and no Windows accounts.
     Avoid writing usernames and passwords in plain text in scripts, use PSCredential instead.
     The default is blank



.PARAMETER DBPassword

     This is the password of the SQL Login used to connect to the database. Only use this parameter when DBAuth equals "SQL"
     The default is blank



.PARAMETER FilePath

     This is the path to the output file where the list of FileGUIDs and User Settings Names will be written to. This can be a local path or a UNC path, provided that the executing account has write access to the UNC path
     The default is "C:\Temp\UserSettings.csv", the path needs to exist already, the file will be created by the script. Any exisitng file with the same name will be overwritten without warning.



.NOTES

  Version:        1.0

  Author:         Rob de Korte

  Creation Date:  04-01-2019

  Purpose/Change: Initial script development



  This information can also be viewed by running ""help .\UP-Overview.ps1"


  --



.INPUTS

  <None>



.OUTPUTS

  Writes to a csv file specified in the variables

  

.EXAMPLE



  .\UP-Overview.ps1 -DBName RESONEWorkspace

  This command queries the User Settings from the RESONEWorkspace database on the Localhost using the logged on user's credentials and writes them to C:\Temp\UserSettings.csv

#>



#----------------------------------------------------------[Declarations]----------------------------------------------------------



#Input Parameters

Param(

[parameter(Mandatory,Position=0)]
[String]$DBServer="Localhost",

[String]$DBPort="",

[parameter(Mandatory,Position=1)]
[String]$DBName= "",

[parameter(Mandatory,Position=2)]
[ValidateSet("SQL","Windows")] 
[String]$DBAuth="Windows",

[String]$DBUser,

[SecureString]$DBPassword,

[String]$FilePath= "C:\Temp\UserSettings.csv"

)


#-----------------------------------------------------------[Functions]------------------------------------------------------------


# Write any function here


#-----------------------------------------------------------[Execution]------------------------------------------------------------


# First, the sqlserver module needs to be imported
Import-Module SqlServer

# Adjust the query to the athentication method that is used
if ($DBAuth -eq "SQL")
{
    $SQLQuery=Invoke-Sqlcmd -Query "
SELECT strDescription AS UserSetting,ObjectGUID AS FileGUID,'Global User Setting' AS Parent FROM tblObjects
	WHERE lngObjectType = 48
		AND ParentGUID = '00000000-0000-0000-0000-000000000000'
			ORDER BY UserSetting 

SELECT L.strDescription AS UserSetting,L.ObjectGUID AS FileGUID,R.strDescription AS Parent FROM tblObjects L
	INNER JOIN tblObjects R
		ON L.ParentGUID = r.ObjectGUID
			AND L.lngObjectType = 48
				ORDER BY Parent 
" -ServerInstance $DBServer -Database $DBName -Username $DBUser -Password $DBPassword
}
else
{
    $SQLQuery=Invoke-Sqlcmd -Query "
SELECT strDescription AS UserSetting,ObjectGUID AS FileGUID,'Global User Setting' AS Parent FROM tblObjects
	WHERE lngObjectType = 48
		AND ParentGUID = '00000000-0000-0000-0000-000000000000'
			ORDER BY UserSetting 

SELECT L.strDescription AS UserSetting,L.ObjectGUID AS FileGUID,R.strDescription AS Parent FROM tblObjects L
	INNER JOIN tblObjects R
		ON L.ParentGUID = r.ObjectGUID
			AND L.lngObjectType = 48
				ORDER BY Parent 
" -ServerInstance $DBServer -Database $DBName
}

#and export it to csv
$SQLQuery | ConvertTo-Csv -NoTypeInformation | Out-File $FilePath 
