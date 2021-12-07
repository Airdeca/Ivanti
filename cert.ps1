<#
Rob de Korte 21-08-2020
a script to create and export a self-signed certificate that can be trusted by modern browsers.
#>

# Set the Variables
$URL = "$[URL]"
$FriendlyName = "$[FriendlyName]"
$FilePath = "$[FilePath]"

# Create the new certificate, retrieve its Thumbprint and give it a FriendlyName
$NewCert = New-SelfSignedCertificate -DnsName $URL -CertStoreLocation Cert:\LocalMachine\my
$Thumb = $NewCert.Thumbprint
(Get-ChildItem "Cert:\LocalMachine\My\$Thumb").FriendlyName = "$FriendlyName"

# Export it
Get-ChildItem "Cert:\LocalMachine\My\$Thumb" | Export-Certificate -Type CERT -FilePath $filepath
