function Get-SubnetOSInstallDate{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, position=0)]
        $1,
        [Parameter(Mandatory=$true, position=1)]
        $2,
        [Parameter(Mandatory=$true, position=2)]
        $3

    )
    $ErrorActionPreference = 'SilentlyContinue'
    Write-Verbose -Message "Getting hostnames for subnet..."
    $addresses = for($i = 1; $i -lt 255; $i++){
        Write-Verbose -Message "Starting async-resolve for: $1`.$2`.$3`.$i" 
        [system.net.dns]::GetHostEntryAsync("$1`.$2`.$3`.$i")
    }
    Write-Verbose -Message "Waiting on Async-resolves..."
    $addresses = ($addresses|?{$_.status -ne "Faulted"}).result | ?{$_ -ne $null}
    
    Write-Verbose -Message "Querying hosts..."
    $objectlist = @() 
    foreach($comp in $addresses){
        $hostname = $comp.hostname
        $install_Date = ""
        Write-Verbose -Message "Querying: $hostname"
        #wmi Query
        $query = gwmi -Class win32_OperatingSystem -ComputerName $comp.hostname -ErrorAction SilentlyContinue
        try{
            $install_Date = $query.ConvertToDateTime($query.InstallDate).toString("MM-dd-yyyy")
        }
        catch [System.Management.Automation.RuntimeException] {
            if($Error[0].Exception.Message -eq "You cannot call a method on a null-valued expression."){
                Write-Verbose -Message "DNS resolves to host but host is not available. Removing from output"
                Continue
            }
        }
        $ComputerName = $comp.hostname -replace "\.[a-zA-Z]+\.[a-zA-Z]+$",""
        $properties = @{ComputerName="$ComputerName";InstallDate="$install_Date";}
        $objectlist += New-Object -TypeName psobject -Property $properties 
    }
    return $objectlist
}
