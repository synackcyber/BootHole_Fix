# This script is for the x64 architecture. The code must be updated to support 32-bit or ARM devices.
# 
#

# Set the TLS version used by the PowerShell client to TLS 1.2.
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

# Check if computer contains invalid CA. Stop Script if certificate is not found.
$SystemImpact = [System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI db).bytes) -match 'Microsoft Corporation UEFI CA 2011'

if ( $SystemImpact -eq "True")
{
    "UEFI CA 2011 was found, continuing to apply fix"
}
else{
    Write-Host "Great news! This PC does not have the UEFI CA 2011 certificate"
    break
}

# Set Execution Policy to Bypass.
Set-ExecutionPolicy Bypass -scope CurrentUser -Force
Write-host "Execution policy is set to BYPASS"

# Check OS Architecture to ensure x64. 
$os_type = (Get-WmiObject -Class Win32_ComputerSystem).SystemType -match ‘(x64)’
if ($os_type -eq "True") {
    Write-Host "Computer is 64bit"
    write-host $os_type }
    else {
        "This PC is not 64Bit..Stopping Script"
        break
}

# Create Temporary directory for downloaded files.
$UEFIDLdirectory = "C:\UEFIBootHole"
mkdir -Path $UEFIDLdirectory | Out-Null
cd $UEFIDLdirectory | Out-Null

# Download UEFI CA binary file from uefi.org.
if ($os_type -eq "True") {

    Invoke-WebRequest -Uri "https://uefi.org/sites/default/files/resources/dbxupdate_x64.bin" -OutFile "dbxupdate_x64.bin" 
}

# Give it some time to Download...
Start-Sleep -s 10
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

# Install NuGet Package and download SplitDbxContect script from NuGet Repo.
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
#Install-Script -Name SplitDbxContent -Force
Start-Sleep -Seconds 30

# Manually DL SplitDBX

Invoke-WebRequest -UseBasicParsing -Uri https://psg-prod-eastus.azureedge.net/packages/splitdbxcontent.1.0.0.nupkg  -OutFile splitdbxcontent.1.0.0.zip
Expand-Archive splitdbxcontent.1.0.0.zip
Copy-Item 'C:\UEFIBootHole\splitdbxcontent.1.0.0\SplitDbxContent.ps1' -Destination 'C:\UEFIBootHole'


# Initiate file split. This will create the required \content.bin and \signature.p7 files in the Temporary dir created above.
./SplitDbxContent.ps1 "dbxupdate_x64.bin"
Start-Sleep -Seconds 15

# Initiate Set-SecureBoot cmdlet to inject new files.
Set-SecureBootUefi -Name dbx -ContentFilePath .\content.bin -SignedFilePath .\signature.p7 -Time 2010-03-06T19:17:21Z -AppendWrite

# Change execution policy to Restricted, Remove NuGet Package, and delete temp directory used to execute cmdlets.
cd "C:\"
rmdir -Path $UEFIDLdirectory -Recurse
