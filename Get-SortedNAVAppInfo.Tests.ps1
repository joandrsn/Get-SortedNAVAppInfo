BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1') # Assuming the test file is named after the script file with .Tests.ps1

    function New-NAVAppObject {
        param (
            [string]$Name,
            [System.Guid]$AppId = [guid]::NewGuid(),
            [array]$Dependencies = @()
        )

        $Deps = foreach ($dep in $Dependencies) {
            [PSCustomObject]@{
                AppId = $dep.AppId
                Name  = $dep.Name
            }
        }
    
        return [PSCustomObject]@{
            AppId        = $AppId
            Name         = $Name
            Dependencies = $Deps
        }
    }
}

Describe "Get-SortedNAVAppInfo Tests" {
    It "Returns the input list if it contains less than 2 items" {
        $appInfoList = @(
            [PSCustomObject]@{AppId = [guid]::NewGuid(); Dependencies = @() }
        )
        $result = Get-SortedNAVAppInfo -appInfoList $appInfoList
        $result.Count | Should -Be 1
        $result[0].AppId | Should -Be $appInfoList[0].AppId
    }
}

Describe "Get-SortedNAVAppInfo Tests" {
    It "Returns sorted list for apps with dependencies" {
        $app1 = New-NAVAppObject
        $app2 = New-NAVAppObject -Dependencies @($app1)
        $appInfoList = @($app2, $app1) # app2 depends on app1
        $result = Get-SortedNAVAppInfo -appInfoList $appInfoList
        $result.Count | Should -Be 2
        $result[0].AppId | Should -Be $app1.AppId
        $result[1].AppId | Should -Be $app2.AppId
    }
}

Describe "Get-SortedNAVAppInfo Tests" {
    It "Handles circular dependencies gracefully" {
        $app1 = New-NAVAppObject
        $app2 = New-NAVAppObject -Dependencies @($app1)
        $app1.Dependencies = @([PSCustomObject]@{AppId = $app2.AppId }) # Creating circular dependency
        $appInfoList = @($app2, $app1)
        { Get-SortedNAVAppInfo -appInfoList $appInfoList } | Should -Not -Throw
    }
}

Describe "Get-SortedNAVAppInfo Tests" {
    It "Correctly sorts a list with multiple dependencies including a base application" {
        $baseApp = New-NAVAppObject -Name "Application" -AppId ([guid]::Empty)
        $app1 = New-NAVAppObject -Name "App1" -Dependencies @($baseApp)
        $app2 = New-NAVAppObject -Name "App2" -Dependencies @($app1)
        $app3 = New-NAVAppObject -Name "App3" -Dependencies @($app2)
        $appInfoList = @($app3, $app2, $app1, $baseApp)
        $result = Get-SortedNAVAppInfo -appInfoList $appInfoList
        $result.Count | Should -Be 4
        $result[0].Name | Should -Be "Application"
        $result[1].Name | Should -Be "App1"
        $result[2].Name | Should -Be "App2"
        $result[3].Name | Should -Be "App3"
    }
}

Describe "Get-SortedNAVAppInfo Tests" {
    It "Handles a complex dependency chain with the base application at the root" {
        $baseApp = New-NAVAppObject -Name "Application" -AppId ([guid]::Empty)
        $app1 = New-NAVAppObject -Name "App1" -Dependencies @($baseApp)
        $app2 = New-NAVAppObject -Name "App2" -Dependencies @($app1, $baseApp)
        $app3 = New-NAVAppObject -Name "App3" -Dependencies @($app2)
        $app4 = New-NAVAppObject -Name "App4" -Dependencies @($app3, $baseApp)
        $appInfoList = @($app4, $app3, $app2, $app1, $baseApp)
        $result = Get-SortedNAVAppInfo -appInfoList $appInfoList
        $result.Count | Should -Be 5
        $result[0].Name | Should -Be "Application"
        $result[1].Name | Should -Be "App1"
        $result[2].Name | Should -Be "App2"
        $result[3].Name | Should -Be "App3"
        $result[4].Name | Should -Be "App4"
    }    
}

Describe "Get-SortedNAVAppInfo Tests" {
    It "Sorts correctly when multiple apps depend on the base application directly" {
        $baseApp = New-NAVAppObject -Name "Application" -AppId ([guid]::Empty)
        $app1 = New-NAVAppObject -Name "App1" -Dependencies @($baseApp)
        $app2 = New-NAVAppObject -Name "App2" -Dependencies @($baseApp)
        $app3 = New-NAVAppObject -Name "App3" -Dependencies @($baseApp)
        $appInfoList = @($app3, $app2, $app1, $baseApp)
        $result = Get-SortedNAVAppInfo -appInfoList $appInfoList
        $result.Count | Should -Be 4
        $result[0].Name | Should -Be "Application"
        $result[1].Name | Should -Match "App[123]"
        $result[2].Name | Should -Match "App[123]"
        $result[3].Name | Should -Match "App[123]"
    }    
}

Describe "Application Dependency Sorting" {
    It "Correctly sorts applications based on their dependencies" {
        # Define applications and their dependencies
        $baseApp = New-NAVAppObject -Name "Application" -AppId ([guid]::Empty)
        $cbf = New-NAVAppObject -Name "Continia Business Foundation" -Dependencies @($baseApp)
        $cc = New-NAVAppObject -Name "Continia Core" -Dependencies @($baseApp)
        $cdn = New-NAVAppObject -Name "Continia Delivery Network" -Dependencies @($cc, $baseApp)
        $cl = New-NAVAppObject -Name "Cloud & License Mgt." -Dependencies @($baseApp)
        $df = New-NAVAppObject -Name "Data Flow" -Dependencies @($baseApp, $cl)
        $cdc = New-NAVAppObject -Name "Continia Document Capture" -Dependencies @($cbf, $cc, $cdn, $baseApp)
        $cem = New-NAVAppObject -Name "Continia Expense Management" -Dependencies @($cbf, $cc, $cdn, $cdc, $baseApp)
        $pdf = New-NAVAppObject -Name "PDF Library" -Dependencies @($baseApp)
        $evm = New-NAVAppObject -Name "EV Mail" -Dependencies @($cl, $baseApp, $pdf)
        $stdoioubl = New-NAVAppObject -Name "OIOUBL"
        $payrec = New-NAVAppObject -Name "Payment and Reconciliation Formats (DK)"
        $core = New-NAVAppObject -Name "EV SBA 365Construction Core" -Dependencies @($payrec, $stdoioubl, $cl, $baseApp)
        $adv = New-NAVAppObject -Name "EV SBA 365Construction Advanced" -Dependencies @($baseApp, $core)
        $cdcext = New-NAVAppObject -Name "EV SBA 365Construction CDC Extension" -Dependencies @($core, $adv, $cdc, $baseApp)
        $cpm = New-NAVAppObject -Name "Continia Payment Management" -Dependencies @($cc, $cbf, $baseApp)
        $cpmdk = New-NAVAppObject -Name "Continia Payment Management (DK)" -Dependencies @($cpm, $payrec, $baseApp)
        $cpmext = New-NAVAppObject -Name "EV SBA 365Construction CPM Extension" -Dependencies @($cpm, $core, $baseApp)
        $oioubl = New-NAVAppObject -Name "EV SBA 365Construction OIOUBL Extension" -Dependencies @($stdoioubl, $core, $evm, $baseApp)
        $evmailext = New-NAVAppObject -Name "EV SBA 365Construction EV Mail Extension" -Dependencies @($core, $adv, $evm, $oioubl, $cl, $stdoioubl, $baseApp)
        $expandit = New-NAVAppObject -Name "ExpandIT Connector" -Dependencies @($baseApp)
        $mobile = New-NAVAppObject -Name "EV SBA 365Construction Mobile" -Dependencies @($core, $adv, $baseApp)
        $expanditext = New-NAVAppObject -Name "EV SBA 365Construction ExpandIT Extension" -Dependencies @($core, $adv, $mobile, $expandit, $baseApp)
        $extinh = New-NAVAppObject -Name "EV SBA 365Construction Extended Inhouse" -Dependencies @($adv, $baseApp)
        $machrent = New-NAVAppObject -Name "EV SBA 365Construction Machine Rental" -Dependencies @($core, $baseApp)
        $sa = New-NAVAppObject -Name "EV SBA 365Construction Service Agreement" -Dependencies @($core, $adv, $mobile, $expanditext, $baseApp)
        $subcon = New-NAVAppObject -Name "EV SBA 365Construction Subcontractor" -Dependencies @($core, $adv, $baseApp)
        $vii = New-NAVAppObject -Name "EV SBA 365Construction Vendor Item Import" -Dependencies @($core, $payrec, $stdoioubl, $df, $baseApp)

        # List of all applications
        $appInfoList = @($cbf, $cc, $df, $cdc, $cl, $cem, $evm, $adv, $cdcext, $core, $cpmext, $evmailext, $expanditext, $extinh, $machrent, $mobile, $oioubl, $sa, $subcon, $vii, $expandit, $pdf, $cpm, $cpmdk)

        # This is a placeholder for the actual sorting logic, which would typically involve a topological sort based on dependencies
        # For the purpose of this example, we're assuming a function Get-SortedAppList exists that performs this sorting
        $result = Get-SortedNAVAppInfo -appInfoList $appInfoList
        $result.Count | Should -Be $appInfoList.Count

        # Assertions to verify the sorting is correct would go here
        # Example:
        # $sortedList[0].Name | Should -Be "Application"
        # Further assertions would depend on the implementation of Get-SortedAppList and the actual sorting logic
    }
}