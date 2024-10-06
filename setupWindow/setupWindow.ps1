# ============================================================
# SETTINGS
# ============================================================
# �Z�b�g�A�b�v���
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
# �R�}���h������̎��s
function Exec-Command ($iCommandStr) {
    [System.Management.Automation.ScriptBlock]$scriptBlock = [ScriptBlock]::Create($iCommandStr)
    Invoke-Command -ScriptBlock $scriptBlock
}

# ���z�f�X�N�g�b�v������
function Init-Desktop {
    Remove-AllDesktops
}

# ���z�f�X�N�g�b�v�ǉ�, ���O�ύX
function Add-Desktop ($iIndex, $iDispname) {
    $commandStr = 'New-Desktop | Set-DesktopName -Name $iDispname'

    # �ŏ��̃f�X�N�g�b�v�͐��������ɖ��O�ύX�̂�
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
    # UseNewEnvironment�Ɠ������g���Ȃ�
    # $processCommandElements.Add('-Wait')

    $result = $processCommandElements -join ' '
    return $result
}

# �A�v���P�[�V�����N��
function Start-App ($iIndex, $iApps) {
    Begin {
        # �N������f�X�N�g�b�v�Ɉړ�
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

    # �����f�B�X�v���C�ɖ߂��ďI��
    Switch-Desktop 0
}

Main

# Start-Process -FilePath 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe' -ArgumentList '--new-window', 'https://edu.mamezou.com/n-fresh-isbd/course/view.php?id=33', 'https://google.com'
