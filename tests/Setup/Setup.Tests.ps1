Describe "Silent install" {
    It "Setup installs files and shortcuts" {
        $path = "C:\Program Files (x86)\Playnite"
        $data = Get-TestProperties
        $setupProc = Start-Process $data.package "/ProgressOnly 1 /D=$path" -PassThru
        $setupProc.WaitForExit()

        $path | Should Exist
        Join-Path $path "PlayniteUI.exe" | Should Exist
        (Get-ChildItem $path).Count | Should BeGreaterThan 1
    }

    It "Playnite is started after installation" {
        Get-Process -Name "PlayniteUI" -EA 0 | Should Not BeNullOrEmpty
        WaitFor { Get-UIWindow -ProcessName "PlayniteUI" } 10000
    }

    It "Shortucts start playnite" {
        if ($proc = Get-Process -Name "PlayniteUI.exe" -EA 0)
        {
            $proc | Stop-Process -Force
            Wait-Process -Id $proc.Id
        }

        $dektop = [System.Environment]::ExpandEnvironmentVariables("%systemdrive%\users\%username%\Desktop")
        $path = Join-Path $dektop "Playnite.lnk"
        $path | Should Exist
        Start-Process $path

        Get-Process -Name "PlayniteUI" -EA 0 | Should Not BeNullOrEmpty
        Stop-Process -Name "PlayniteUI"
    }
}

Describe "Uninstall" {
    It "Uninstall removes all files" {
        $window = { Get-UIDesktop | Get-UIControl -ControlType "Dialog" -Name "Playnite*Uninstall" }
        $testData = Get-TestProperties

        $dektop = [System.Environment]::ExpandEnvironmentVariables("%systemdrive%\users\%username%\Desktop")
        $startMenu = [System.Environment]::ExpandEnvironmentVariables("c:\Users\crow\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Playnite\")        
        Start-Process (Join-Path $testData.InstallPath "uninstall.exe")
        WaitFor { & $window } 5000
        & $window | Get-UIButton -Name "Yes" | Invoke-UIClick

        # Windows completely reloads so we need to get new one later
        WaitFor { & $window | Get-UIControl -AutoId "1006" -Name "Completed"  } 30000
        & $window | Get-UIButton -AutoId "1" | Invoke-UIClick

        $testData.InstallPath | Should Not Exist        
        Join-Path $dektop "Playnite.lnk" | Should Not Exist
        $startMenu | Should Not Exist
    }
}