# Check if computer needs to do things. Stop Script if certificate is not found. This is for the x64 architecture. Must be updated to support 32-bit or ARM devices

$SystemImpact = [System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI db).bytes) -match 'Microsoft Corporation UEFI CA 2011'

if ( $SystemImpact -eq "True")
{
    "UEFI CA 2011 was found, continuing to apply fix"
}
else{
    Write-Host "Great news! This PC does not have the UEFI CA 2011 certificate"
    break
}

# Set execution Policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
Write-host "Execution policy is set to BYPASS"

# Check OS Architecture
$os_type = (Get-WmiObject -Class Win32_ComputerSystem).SystemType -match ‘(x64)’
if ($os_type -eq "True") {
    Write-Host "I ARE 64bit"
    write-host $os_type }
    else {
        "This PC is not 64Bit..Stopping Script"
        break
}

# Create directory and CD to directory
$UEFIDLdirectory = "C:\UEFIBootHole"
mkdir -Path $UEFIDLdirectory | Out-Null
cd $UEFIDLdirectory | Out-Null

# Download UEFI CA binary file
if ($os_type -eq "True") {
    Invoke-WebRequest -Uri "https://uefi.org/sites/default/files/resources/dbxupdate_x64.bin" -OutFile "dbxupdate_x64.bin" 
}
Start-Sleep -s 10

# Install NuGet and DBX Content
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Script -Name SplitDbxContent -Force

# Initiate file split
SplitDbxContent.ps1 "dbxupdate_x64.bin"

# Initiate Set-secureboot
Set-SecureBootUefi -Name dbx -ContentFilePath .\content.bin -SignedFilePath .\signature.p7 -Time 2010-03-06T19:17:21Z -AppendWrite

# Change execution policy back and perform cleanup of files
cd "C:\"
rmdir -Path $UEFIDLdirectory -Recurse

# Remove NuGet Package Provider
(Get-PackageProvider|where-object{$_.name -eq "nuget"}).ProviderPath|Remove-Item -force

Set-ExecutionPolicy -ExecutionPolicy Restricted -Force
Write-host "Execution policy is set to RESTRICTED"

Write-Host "CRL has been updated"
