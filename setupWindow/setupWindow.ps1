# ============================================================
# SETTINGS
# ============================================================
# セットアップ情報
Set-Variable -name APPLIST_PATH -value '.\applist.yaml' -option Constant

Set-Variable -name KEY_DISPLAYNAME -value 'desktopName' -option Constant
Set-Variable -name KEY_APPS -value 'applications' -option Constant
Set-Variable -name KEY_APP_PATH -value 'FilePath' -option Constant
Set-Variable -name KEY_APP_ARGS -value 'ArgumentList' -option Constant
Set-Variable -name KEY_APP_WORKDIR -value 'WorkingDirectory' -option Constant
Set-Variable -name KEY_APP_OPTIONS -value 'Options' -option Constant


# ============================================================
# FUNCTIONS
# ============================================================
# コマンド文字列の実行
function Exec-Command ($iCommandStr) {
    [System.Management.Automation.ScriptBlock]$scriptBlock = [ScriptBlock]::Create($iCommandStr)
    Invoke-Command -ScriptBlock $scriptBlock
}

# 仮想デスクトップ初期化
function Init-Desktop {
    Remove-AllDesktops
}

# 仮想デスクトップ追加, 名前変更
function Add-Desktop ($iIndex, $iDispname) {
    $commandStr = 'New-Desktop | Set-DesktopName -Name $iDispname'

    # 最初のデスクトップは生成せずに名前変更のみ
    if ($iIndex -eq 0) {
        $commandStr = 'Set-DesktopName -Name $iDispname'
    }
    Exec-Command $commandStr
}

function Create-ProcessCommand ($iApp) {
    $processCommandElements = New-Object System.Collections.ArrayList
    $processCommandElements.AddRange(('Start-Process', '-FilePath', '$app.$KEY_APP_PATH'))

    if ($app.$KEY_APP_ARGS -ne $null) {
        $processCommandElements.AddRange(('-ArgumentList', '$app.$KEY_APP_ARGS'))
    }
    if ($app.$KEY_APP_WORKDIR -ne $null) {
        $processCommandElements.AddRange(('-WorkingDirectory', '$app.$KEY_APP_WORKDIR'))
    }
    if ($app.$KEY_APP_OPTIONS -ne $null) {
        $processCommandElements.Add('$app.$KEY_APP_OPTIONS')
    }
    # UseNewEnvironmentと同じく使えない
    # $processCommandElements.Add('-Wait')

    $result = $processCommandElements -join ' '
    return $result
}

# アプリケーション起動
function Start-App ($iIndex, $iApps) {
    Begin {
        # 起動するデスクトップに移動
        Switch-Desktop $iIndex
    }

    Process {
        foreach ($app in $iApps) {
            Exec-Command $(Create-ProcessCommand $app)
        }
    }

    End {}
}


# ============================================================
# MAIN
# ============================================================
function Main {
    Init-Desktop
    $applist = (Get-Content -Encoding 'UTF8' $APPLIST_PATH) -join "`n" | ConvertFrom-YAML

    for ($i = 0; $i -lt $applist.count; $i++) {
        Add-Desktop $i $applist[$i].$KEY_DISPLAYNAME
        Start-App $i $applist[$i].$KEY_APPS
    }

    # 初期ディスプレイに戻って終了
    Switch-Desktop 0
}

Main

# Start-Process -FilePath 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe' -ArgumentList '--new-window', 'https://edu.mamezou.com/n-fresh-isbd/course/view.php?id=33', 'https://google.com'
