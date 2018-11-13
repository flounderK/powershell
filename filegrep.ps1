function filegrep-proc{
[CmdletBinding(DefaultParameterSetName='Items', SupportsTransactions=$true)]
param(
    [Parameter(Mandatory=$true, Position=-1)]
    [string]
    ${Pattern},

    [Parameter(ParameterSetName='Items', Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string[]]
    ${Path},

    [Parameter(ParameterSetName='LiteralItems', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('PSPath')]
    [string[]]
    ${LiteralPath},

    [Parameter(Position=1)]
    [string]
    ${Filter},

    [string[]]
    ${Include},

    [string[]]
    ${Exclude},

    [Alias('s')]
    [switch]
    ${Recurse},

    [uint32]
    ${Depth},

    [switch]
    ${Force},

    [switch]
    ${Name})


dynamicparam
{
    try {
        $targetCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Management\Get-ChildItem', [System.Management.Automation.CommandTypes]::Cmdlet, ${MyInvocation.BoundParameters})
        $dynamicParams = @($targetCmd.Parameters.GetEnumerator() | Microsoft.PowerShell.Core\Where-Object { $_.Value.IsDynamic })
        if ($dynamicParams.Length -gt 0)
        {
            $paramDictionary = [Management.Automation.RuntimeDefinedParameterDictionary]::new()
            foreach ($param in $dynamicParams)
            {
                $param = $param.Value

                if(-not $MyInvocation.MyCommand.Parameters.ContainsKey($param.Name))
                {
                    $dynParam = [Management.Automation.RuntimeDefinedParameter]::new($param.Name, $param.ParameterType, $param.Attributes)
                    $paramDictionary.Add($param.Name, $dynParam)
                }
            }
            return $paramDictionary
        }
    } catch {
        throw
    }
}

begin
{
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }
        $PSBoundParameters.Remove("Pattern") | out-null
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Management\Get-ChildItem', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters | Select-String -Pattern $Pattern -AllMatches| group path | select -expandproperty group}
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Microsoft.PowerShell.Management\Get-ChildItem
.ForwardHelpCategory Cmdlet

#>
}

function filegrep{
<#
	An attempt to coax "grep -r" functionality out of powershell


#>
[CmdletBinding(DefaultParameterSetName='Items', SupportsTransactions=$true)]
param(
	[Parameter(Mandatory=$true, Position=-1)]
    [string]
    ${Pattern}, 

	
    [Parameter(ParameterSetName='Items', Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string[]]
    ${Path},

    [Parameter(ParameterSetName='LiteralItems', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('PSPath')]
    [string[]]
    ${LiteralPath},

    [Parameter(Position=1)]
    [string]
    ${Filter},

    [string[]]
    ${Include},

    [string[]]
    ${Exclude},

    [Alias('s')]
    [switch]
    ${Recurse},

    [uint32]
    ${Depth},

    [switch]
    ${Force},

    [switch]
    ${Name},
    
    [switch]
    $Filenames=$false,
    
    [switch]
    $Fullobjects=$false)



begin
{
	$PSBoundParameters.Remove("Filenames") | out-null
    $PSBoundParameters.Remove("Fullobjects") | out-null
}

process
{
    $results = filegrep-proc @PSBoundParameters
	if (-not $Fullobjects){
		$results = $results | foreach {$_ | select filename, LineNumber, Path}
	}
	if ($Filenames) {
		$results = $results | select -expandproperty Filename | Sort -unique
	}
	return $results
}

<#

.ForwardHelpTargetName Microsoft.PowerShell.Management\Get-ChildItem
.ForwardHelpCategory Cmdlet

#>

}
