# Версия скрипта
$scriptVersion = "1.0.0"

# Установка кодировки для поддержки кириллицы
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Определение пути реестра для настроек Windows Defender
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$serviceName = "WinDefend"
$iconPath = Join-Path $PSScriptRoot "icons/icon.ico"
$iconPathEnabled = Join-Path $PSScriptRoot "icons/icon_enabled.ico"
$iconPathDisabled = Join-Path $PSScriptRoot "icons/icon_disabled.ico"
$logFile = Join-Path $PSScriptRoot "ToggleWindowsDefender.log"
$scriptUrl = "https://raw.githubusercontent.com/Nagrands/ToggleWindowsDefender/main/ToggleWindowsDefender.ps1"
$localScriptPath = $MyInvocation.MyCommand.Definition

# Функция для логирования сообщений
function Log-Message {
    param (
        [string]$message,
        [bool]$isSeparator = $false
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if ($isSeparator) {
        "----------------------------------------" | Out-File -Append -FilePath $logFile -Encoding UTF8
    } else {
        "$timestamp - $message" | Out-File -Append -FilePath $logFile -Encoding UTF8
    }
}

# Функция для отправки уведомлений
function Show-Notification {
    param (
        [string]$title,
        [string]$message,
        [string]$iconPath = $iconPath
    )
    New-BurntToastNotification -Text "$title", $message -AppLogo $iconPath
}

# Проверка наличия интернета
function Test-InternetConnection {
    try {
        $connection = Test-Connection -ComputerName google.com -Count 1 -Quiet
        return $connection
    } catch {
        return $false
    }
}

# Функция для обновления скрипта из GitHub
function Update-Script {
    if (Test-InternetConnection) {
        try {
            $remoteScript = Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing
            $localScript = Get-Content -Path $localScriptPath -Raw
            if ($remoteScript.Content -ne $localScript) {
                $remoteScript.Content | Out-File -FilePath $localScriptPath -Encoding UTF8
                $message = "Скрипт обновлен до последней версии (v$scriptVersion)."
                Write-Host $message -ForegroundColor Green
                Log-Message $message
                Show-Notification -title "Script Defender" -message $message
                exit
            } else {
                $message = "Версия скрипта (v$scriptVersion)."
                Write-Host $message -ForegroundColor Green
                Log-Message $message
            }
        } catch {
            if ($_.Exception.Response.StatusCode -eq 404) {
                $message = "Скрипт не найден в репозитории. Продолжаю выполнение локальной версии."
                Write-Host $message -ForegroundColor Yellow
                Log-Message $message
            } else {
                $message = "Ошибка при обновлении скрипта: $_"
                Write-Host $message -ForegroundColor Red
                Log-Message $message
                Show-Notification -title "Script Defender" -message $message
                exit
            }
        }
    } else {
        $message = "Отсутствует подключение к интернету. Обновление скрипта невозможно."
        Write-Host $message -ForegroundColor Red
        Log-Message $message
        exit
    }
}

# Создание ярлыка на рабочем столе
function Create-Shortcut {
    $desktop = [System.Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktop "ToggleWindowsDefender.lnk"
    if (-Not (Test-Path $shortcutPath)) {
        $targetPath = $PSCommandPath

        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "pwsh.exe"
        $shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$targetPath`""
        $shortcut.IconLocation = $iconPath
        $shortcut.Save()

        # Установка прав администратора для ярлыка
        $shortcutFile = New-Object -ComObject WScript.Shell
        $shortcut = $shortcutFile.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "pwsh.exe"
        $shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$targetPath`""
        $shortcut.IconLocation = $iconPath
        $shortcut.Save()
        
        $shell = New-Object -ComObject Shell.Application
        $shortcut = $shell.Namespace((Get-Item $shortcutPath).DirectoryName).ParseName((Get-Item $shortcutPath).Name)
        $shortcut.InvokeVerb("runas")

        $message = "Ярлык для скрипта создан на рабочем столе."
        Write-Host $message -ForegroundColor Green
        Log-Message $message
        Show-Notification -title "Script Defender" -message $message
    } else {
        $message = "Ярлык уже существует на рабочем столе."
        Write-Host $message -ForegroundColor Yellow
    }
}

# Проверка существования пути к иконке
if (-Not (Test-Path $iconPath)) {
    $message = "Иконка не найдена по пути: $iconPath"
    Write-Host $message -ForegroundColor Red
    Log-Message $message
    exit
}

# Установка и импорт модуля BurntToast для уведомлений
if (-Not (Get-Module -ListAvailable -Name BurntToast)) {
    if (Test-InternetConnection) {
        try {
            Install-Module -Name BurntToast -Force -Scope CurrentUser
        } catch {
            $message = "Не удалось установить модуль BurntToast: $_"
            Write-Host $message -ForegroundColor Red
            Log-Message $message
            Show-Notification -title "Script Defender" -message $message
            exit
        }
    } else {
        $message = "Отсутствует подключение к интернету. Установка модуля BurntToast невозможна."
        Write-Host $message -ForegroundColor Red
        Log-Message $message
        exit
    }
}
Import-Module BurntToast

# Проверка, что скрипт запущен с правами администратора
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $message = "Запустите этот скрипт от имени администратора."
    Write-Host $message -ForegroundColor Red
    Log-Message $message
    Show-Notification -title "Script Defender" -message $message
    exit
}

# Отключение защиты от несанкционированного доступа через реестр
function Disable-TamperProtection {
    try {
        Start-Process powershell -WindowStyle Hidden -ArgumentList "-Command `"Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Features' -Name 'TamperProtection' -Value 0`"" -Verb RunAs -Wait
        Log-Message "TamperProtection успешно отключен."
    } catch {
        $message = "Не удалось отключить TamperProtection: $_"
        Write-Host $message -ForegroundColor Red
        Log-Message $message
        Show-Notification -title "Script Defender" -message $message
        exit
    }
}

# Включение защиты от несанкционированного доступа через реестр
function Enable-TamperProtection {
    try {
        Start-Process powershell -WindowStyle Hidden -ArgumentList "-Command `"Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Features' -Name 'TamperProtection' -Value 5`"" -Verb RunAs -Wait
        Log-Message "TamperProtection успешно включен."
    } catch {
        $message = "Не удалось включить TamperProtection: $_"
        Write-Host $message -ForegroundColor Red
        Log-Message $message
        Show-Notification -title "Script Defender" -message $message
    }
}

# Проверка текущего состояния Windows Defender
function Is-DefenderDisabled {
    try {
        $defenderState = Get-MpPreference
        return $defenderState.DisableRealtimeMonitoring -eq $true
    } catch {
        $message = "Ошибка при проверке состояния Windows Defender: $_"
        Write-Host $message -ForegroundColor Red
        Log-Message $message
        Show-Notification -title "Script Defender" -message $message
        exit
    }
}

# Переключение состояния Windows Defender
function Set-DefenderState {
    param (
        [bool]$disable
    )
    $action = if ($disable) { "Отключение" } else { "Включение" }
    try {
        if ($disable) {
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
            Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
        } else {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
            Set-Service -Name $serviceName -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $serviceName -ErrorAction SilentlyContinue
        }

        Set-ItemProperty -Path $regPath -Name "DisableAntiSpyware" -Value ([int]$disable)
        Set-ItemProperty -Path $regPath -Name "DisableRealtimeMonitoring" -Value ([int]$disable)
        Set-ItemProperty -Path $regPath -Name "DisableBehaviorMonitoring" -Value ([int]$disable)
        Set-ItemProperty -Path $regPath -Name "DisableOnAccessProtection" -Value ([int]$disable)
        Set-ItemProperty -Path $regPath -Name "DisableScanOnRealtimeEnable" -Value ([int]$disable)

        if ($disable) {
            Set-ItemProperty -Path "$regPath\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path "$regPath\Real-Time Protection" -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue
        }

        Log-Message "$action Windows Defender успешно завершено."
    } catch {
        $message = "Не удалось выполнить $action Windows Defender: $_"
        Write-Host $message -ForegroundColor Red
        Log-Message $message
        Show-Notification -title "Script Defender" -message $message -iconPath $iconPathDisabled
    }
}

# Основная логика
Write-Host "Проверка Windows Defender..."
Log-Message "ToggleWindowsDefeder.ps1 (v$scriptVersion)."
Log-Message "Проверка состояния Windows Defender ..."

Update-Script

Disable-TamperProtection

$currentDefenderState = Is-DefenderDisabled

if ($currentDefenderState) {
    Set-DefenderState -disable:$false
    $toastMessage = "Windows Defender включен."
    $iconPathForNotification = $iconPathEnabled
} else {
    Set-DefenderState -disable:$true
    $toastMessage = "Windows Defender отключен."
    $iconPathForNotification = $iconPathDisabled
}

Enable-TamperProtection

$message = "Переключение состояния Windows Defender завершено."
Write-Host $message
Log-Message $message

# Добавление строки-разделителя
Log-Message "" $true

# Отправка уведомления
Show-Notification -title "Script Defender" -message $toastMessage -iconPath $iconPathForNotification

# Создание ярлыка на рабочем столе
Create-Shortcut
