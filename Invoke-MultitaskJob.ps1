[cmdletbinding()]
param(
[Parameter(Mandatory=$true)]
$code,
[Parameter()]
$ArgumentList=$computerName,
[Parameter(Mandatory=$true)]
$Computers,
[Parameter()]
$TasksInJobWave=6
)

function Job-Check {
    param($jobs)
    $jobcheck_finished = $false
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
    }
    write-Verbose "All Jobs in wave finished"
    return ($jobs| Receive-Job)|Where-Object {$_ -ne $null}
}

$resultset = @()
$jobs = @()

foreach($Computername in $computers){    
    Write-Verbose "starting job for $Computername"
    $jobs += Start-Job -ScriptBlock $code -ArgumentList $ArgumentList -Name $Computername 

    if($jobs.count -ge $TasksInJobWave){
        $resultset += Job-Check -jobs $jobs
        Get-Job | Remove-Job -Force
    }

}

Write-Verbose "All Jobs started"

Write-Verbose "All Jobs finished"
$resultset += ($jobs| Receive-Job)|Where-Object {$_ -ne $null}
Get-Job | Remove-Job -Force
return $resultset

