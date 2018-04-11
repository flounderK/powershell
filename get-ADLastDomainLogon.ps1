<#
    .SYNOPSIS
        Querys all of the domain controllers in your current domain to see when the last domain login for a particular user was

    .DESCRIPTION
        Querys all of the domain controllers in your current domain to see when the last domain login for a particular user was. Most domains have Domain Controllers that sync up, but sometimes 
        synching up can take way too long. 

    .PARAMETER Identity
        The AD username that you are querying on the domain controllers

    .PARAMETER timeout
        A timeout for the queries

    .PARAMETER DisableTimeOut
        Ignore the timeout setting, let the script take its time. (Note, The script will only finish once all jobs have a Completed or Failed state)
#>
<#
    TODO: Add in optional configuration file parsing to ignore domain controllers consistently
#>

[cmdletbinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [Alias("ID")]
    [string]$Identity,
    [Parameter(Mandatory=$false)]
    $timeout=30,
    [Parameter(Mandatory=$false)]
    [switch]$DisableTimeOut=$false
    )
    process{
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
            [Parameter(mandatory = $true, Position=0)]
            $time
            )
            $result = ([datetime]$time).AddYears(1600).ToLocalTime()
            return $result
        }


        $ErrorActionPreference = "SilentlyContinue"
        $domain = get-addomain 
        $domainsid = $domain.domainsid
        $DCs = get-adgroup -Identity "$domainsid-516" | get-adgroupmember -recursive | select -ExpandProperty name
        if($ShowList -eq $true){return $DCs}
        if((UserExists $identity) -eq $false){return "User Does Not exist"}
        $jobs=@()
        foreach($DC in $DCs){
            $Code = {

                param($Identity,$DC)

                $Query = Get-ADUser -Identity $Identity -Properties LastLogon -Server $DC -ErrorAction SilentlyContinue
                return $Query
            }
            Write-Verbose "Starting query to $DC"
            $jobs+= Start-Job -ScriptBlock $Code -ArgumentList $Identity, $DC -Name $DC
        }

        Write-Verbose "All Jobs started"
        <#something something wait, receive jobs #>
        $jobcheck_finished = $false
        $total_time_slept = 0

        while($jobcheck_finished -ne $true){
            $completed_jobs = 0
            foreach($job in $jobs){
                if($job.state -match '(Running|NotStarted)'){
                    Write-Verbose "Running job found, $($job.Name)"
                    break
                }
                if($job.state -match '(Completed|Failed)'){
                    #Write-Verbose "completed job found $($job.Name)"
                    $completed_jobs += 1
                }
                if($completed_jobs -eq $jobs.Length){
                    $jobcheck_finished = $true    
                }
            }
            #timeout check
            if(-not($DisableTimeOut)){
                Start-Sleep -Milliseconds 500
                $total_time_slept += 0.5
                if($total_time_slept -ge $timeout){
                    Write-Verbose "Timeout reached"
                    $jobcheck_finished = $true
                }

            }
        }


        Write-Verbose "All Jobs finished"
        $resultset = ($jobs| Receive-Job)|Where-Object {$_ -ne $null}
        if($resultset.Length -eq 0){
            return "No responses recieved from any domain controllers. The time"
        }
        Get-Job | Remove-Job -Force
        $most_recent_logon = (($resultset.lastlogon | Sort-Object -Descending)| `
                             ForEach-Object{(ToReadableTime -time $_).datetime})[0]
        return $most_recent_logon
    }
