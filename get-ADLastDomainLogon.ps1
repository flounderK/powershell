﻿<#
    .SYNOPSIS
        Querys all of the domain controllers in your current domain to see when the last domain login for a particular user was

    .DESCRIPTION
        Querys all of the domain controllers in your current domain to see when the last domain login for a particular user was. Most domains have Domain Controllers that sync up, but sometimes 
        synching up can take way too long. 

    .PARAMETER Identity
        The AD username that you are querying on the domain controllers

#>
<#
    TODO: Add in optional configuration file parsing to ignore domain controllers consistently
#>
[cmdletbinding()]
param(
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
$Identity
)
begin{
    Import-Module ActiveDirectory
    Function UserExists{              
        [cmdletbinding()]
        param (
        [Parameter(Mandatory=$true)]
        [string]$uname
        ) 
        [bool]$result=$false
        if(dsquery user -samid $uname){ $result=$true}
        else{$result=$false}
        return $result
    }
    function ToReadableTime{        
        param(
        [Parameter(mandatory = $true,ValueFromPipeline=$true)]
        $time
        )
        process{
            $result = ([datetime]$time).AddYears(1600).ToLocalTime()
            return $result
        }
    }


    
    $domainsid = (get-addomain).domainsid
    $DCs = get-adgroup -Identity "$domainsid-516" | get-adgroupmember -recursive | select -ExpandProperty name
}

process{
    if((UserExists $identity) -eq $false){return "User $Identity Does Not exist"}
    $Jobs = @()
    $gatherers = @()
    foreach($DC in $DCs){
                $Code = {
            
                    param($Identity,$DC)
                    try{
                        $Query = (Get-ADUser -Identity $Identity -Properties LastLogon -Server $DC -ErrorAction SilentlyContinue).lastlogon

                    }catch [Microsoft.ActiveDirectory.Management.ADServerDownException]{
                        $Query = ([datetime]"1-1-1990").tofiletime()
                    }
                    return $Query
                }
                Write-Verbose "Starting query to $DC"
                $job = Start-Job -ScriptBlock $Code -ArgumentList $Identity, $DC -Name $DC
                $Jobs += $job        
    }
    write-verbose "Jobs Started"
    $jobs_finished = $false

    $finished_job_limit = $jobs.count

    while(-not $jobs_finished){
        $finished_job_count = 0

        start-sleep -milliseconds 500
        foreach($obj in $Jobs){
            if($obj.state -eq [System.Management.Automation.JobState]::Completed){
                $finished_job_count = $finished_job_count + 1
            }
        }
        if ($finished_job_count -eq $finished_job_limit){
            $jobs_finished = $true
        }
        $verbose_display_Job = $finished_job_limit - $finished_job_count
        Write-Verbose "Waiting on $verbose_display_Job jobs"
    }
    $Result_set = @()
    foreach($obj in $Jobs){
        $server = $obj.Name
        $result_data = ($obj | Receive-Job) |Where-Object {$_ -ne $null}
        $Result_set += New-Object PSObject -Property @{Server=$server;LastLogon=$result_data;Identity=$Identity}
    
    }
    $Jobs|Remove-Job -Force
    #$Result_set
    $most_recent = ($Result_set | Sort-Object -Descending -Property LastLogon)[0]
    $most_recent.LastLogon = ($most_recent.LastLogon | ToReadableTime).datetime
    # (($result_set.LastLogon | Sort-Object -Descending)| ForEach-Object{(ToReadableTime -time $_).datetime})[0]
    return $most_recent
}