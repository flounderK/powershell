<#
    .SYNOPSIS
        Deploy and install using a filesystem deployment, followed by a wmi call to the computer that the file was deployed to

    .DESCRIPTION
        Deploy and install using a filesystem deployment, followed by a wmi call to the computer that the file was deployed to
        The script takes in yml files and a computer name
        It is a slight bastardization of the PSDeploy module

    .PARAMETER Deployment_Path
        Path of Deployment yml file to process
    
    .PARAMETER ComputerName
        Computer name(s) to deploy to
#>
<#
incase it gets lost again, here is an example of what a basic install string and localinstallpath should look like [for an msi install file]
  InstallString:
    - 'C:\Windows\System32\msiexec.exe /i [] /qn /passive ALLUSERS=1 UILEVEL=2' 
  LocalInstallPath:
    - 'C:\install\'
#>
[cmdletbinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    $Deployment_Path,
    [Parameter(Mandatory=$true, position=1)]
    $ComputerName


) 
Import-Module PSDeploy

$Deployment = Get-PSDeployment -Path $Deployment_Path 

foreach($install in $Deployment){
    if(($install.raw.LocalInstallPath -eq "") -or ($install.raw.LocalInstallPath -eq $null)){
        Write-Verbose "No local install path for Deployment, skipping install step"
        continue
    }

    $targetstring = "\\[]\" + ($install.raw.LocalInstallPath -replace ":","$")
    #Check to make sure computer name is valid
    #!!!!!!!Do not use script until this is checked and fixed. psdeploy will deploy to the current directory and delete all files with deployment if computername is not valid
    #update: it looks like issue might be caused by referencing something in the current directory with .\
    $targetstring = $targetstring -replace "\[\]",$ComputerName
    $install.targets += $targetstring
    Invoke-PSDeployment -Deployment $install -Confirm
    $install_string = $install.raw.InstallString
    if(($install_string -eq "") -or ($install_string -eq $null)){
        Write-Verbose "No install string for Deployment, skipping install step"
        continue
    }

    $filename = Get-ChildItem $install.Raw.source | select -ExpandProperty name
    $filepath = $install.raw.LocalInstallPath + "$filename"
    $install_string = $install_string -replace "\[\]",$filepath

    Write-Verbose "$install"
    #$deployment_name = $install.raw.
    Write-Verbose "Installing..."
    <#install#>
    ([WMICLASS]"\\$ComputerName\ROOT\CIMV2:Win32_Process").Create($install_string)
    Start-Sleep -Seconds 40
}

