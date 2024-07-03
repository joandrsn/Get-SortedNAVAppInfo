# Implementation of Topological Sort algorithm based on the Depth-first search
# https://en.wikipedia.org/wiki/Topological_sorting

function Get-SortedNAVAppInfo {
    Param(
        [Parameter(Mandatory = $true)]
        [array]$appInfoList
    )
    if ($appInfoList.Count -lt 2) {
        return $appInfoList
    }
    $visited = New-Object System.Collections.Generic.HashSet[guid]
    $circular = New-Object System.Collections.Generic.HashSet[guid]
    $result = foreach ($appInfo in $appInfoList) {
        if (-not $visited.Contains($appInfo.AppId)) {
            Convert-SingleNode -appInfo $appInfo -visited $visited -appsToPublish $appInfoList -circular $circular
        }
    }
    return $result
}

function Convert-SingleNode {
    Param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$appInfo,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[guid]]$visited,
        [Parameter(Mandatory = $true)]
        [array]$appsToPublish,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[guid]]$circular
    )
    if ($visited.Contains($appInfo.AppId)) {
        return
    }
    if ($circular.Contains($appInfo.AppId)) {
        throw "Circular dependency detected for app: $($appInfo.Name)"
    }

    $null = $circular.Add($appInfo.AppId)
    foreach ($dependency in $appInfo.Dependencies) {
        if (-not $visited.Contains($dependency.AppId)) {
            $dependencyAppInfo = $appsToPublish | Where-Object { $_.AppId -eq $dependency.AppId }
            if ($dependencyAppInfo) {
                Convert-SingleNode -appInfo $dependencyAppInfo -visited $visited -appsToPublish $appsToPublish -circular $circular
            }
        }
    }
    $null = $circular.Remove($appInfo.AppId)
    $null = $visited.Add($appInfo.AppId)
    $appInfo
}