#just a script to do something similar to grep
[cmdletbinding()]
param(
[Parameter(Mandatory=$true,Position=-1)]
$pattern,
[Parameter(ValueFromPipeline=$true)]
$blob,
[Parameter(Mandatory=$false)]
$f,
[Parameter(Mandatory=$false)]
[switch]
$P=$false,
[Parameter(Mandatory=$false)]
[switch]
$o=$false,
[Parameter(Mandatory=$false)]
[switch]
$c=$false
)
begin{
    $result = @()
}
process{
    if($P -eq $true){
        $result += $blob | Where-Object {$_ -match "$pattern"}
    }
    else{
        $result += $blob | Where-Object {$_ -like "*$pattern*"}
    }
}
end{
    if($o -eq $true){
        $result = $Matches
    }
    elseif($c -eq $true){
        $result = $result.count
    }
    return $result
}
