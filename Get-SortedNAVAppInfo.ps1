function Get-SortedNAVAppInfo {
    Param(
        [Parameter(Mandatory = $true)]
        [array]$appInfoList
    )
    if ($appInfoList.Count -lt 2) {
        return $appInfoList
    }
    $visited = New-Object System.Collections.Generic.HashSet[guid]
    $result = foreach ($appInfo in $appInfoList) {
        if (-not $visited.Contains($appInfo.AppId)) {
            Convert-SingleNode -appInfo $appInfo -visited $visited -appsToPublish $appInfoList
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
        [array]$appsToPublish
    )
    $null = $visited.Add($appInfo.AppId)
    foreach ($dependency in $appInfo.Dependencies) {
        Write-Debug $dependency.Name
        if (-not $visited.Contains($dependency.AppId)) {
            $dependencyAppInfo = $appsToPublish | Where-Object { $_.AppId -eq $dependency.AppId }
            if ($dependencyAppInfo) {
                Convert-SingleNode -appInfo $dependencyAppInfo -visited $visited -appsToPublish $appsToPublish
            }
        }
    }
    $appInfo
    $dependants = $appsToPublish | Where-Object { $_.Dependencies.AppId -eq $appInfo.AppId -and (-not $visited.Contains($_.AppId)) }
    foreach ($dependant in $dependants) {
        Convert-SingleNode -appInfo $dependant -visited $visited -appsToPublish $appsToPublish
    }
}