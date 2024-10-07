# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# ------------------------------
# GLOBAL CONST SETTING
# ------------------------------
# Load Setting
Set-Variable -name CONFIG -value (ConvertFrom-Json (Get-Content -Path "config.json" -Raw)) -option Constant;

# Gmailの送信資格情報
Set-Variable -name CREDENTIAL_ID -value (CONFIG.CREDENTIAL_ID) -option Constant;
Set-Variable -name CREDENTIAL_PASSWORD -value (CONFIG.CREDENTIAL_PASSWORD) -option Constant;

# 送受信アドレス
Set-Variable -name ADDRESS_MAIL_FROM -value $CREDENTIAL_ID -option Constant;
Set-Variable -name ADDRESS_MAIL_TO -value (CONFIG.ADDRESS_MAIL_TO) -option Constant;

# メールタイトル
Set-Variable -name MAIL_SUBJECT -value ([String]'[NOTIFY] turn on computer') -option Constant;

# ログレベル列挙
enum LogLevel {
    INFO
    DEBUG
    SUCCESS
    ERROR
}

# ------------------------------
# Functions
# ------------------------------
function logging([String]$iMsg, [LogLevel]$iLogLevel) {
    [ConsoleColor]$textColor = ([ConsoleColor]::White);
    [String]$dispLevel = '[]';

    switch ($iLogLevel) {
        ([LogLevel]::INFO) {
            $textColor = ([ConsoleColor]::White);
            $dispLevel = '[INFO]';
        }
        ([LogLevel]::DEBUG) {
            $textColor = ([ConsoleColor]::Blue);
            $dispLevel = '[DEBUG]';
        }
        ([LogLevel]::SUCCESS) {
            $textColor = ([ConsoleColor]::Green);
            $dispLevel = '[SUCCESS]';
        }
        ([LogLevel]::ERROR) {
            $textColor = ([ConsoleColor]::Red);
            $dispLevel = '[ERROR]';
        }
        default {}
    }

    [String]$outMsg = '{0} {1}' -f $dispLevel, $iMsg;
    Write-Host $outMsg -ForegroundColor $textColor;
}

function Build-Credential() {
    [securestring]$secpasswd = ConvertTo-SecureString $CREDENTIAL_PASSWORD -AsPlainText -Force;
    [System.Management.Automation.PSCredential]$retCredential = New-Object System.Management.Automation.PSCredential($CREDENTIAL_ID, $secpasswd);

    return $retCredential;
}

function Build-Message-Body() {
    [HashTable]$info = @{
        COMPUTERNAME = $env:COMPUTERNAME
        USERNAME     = (Gwmi -Class Win32_ComputerSystem).username
    };
    [String]$retText = $info | Format-Table -AutoSize | Out-String;

    return $retText;
}

function Build-Message-Params([System.Management.Automation.PSCredential]$iCredential, [String]$iMessage) {
    [System.Text.Encoding]$encoding = ([System.Text.Encoding]::UTF8);
    [HashTable]$retMailInfoTable = @{
        From       = $ADDRESS_MAIL_FROM
        To         = $ADDRESS_MAIL_TO
        Subject    = $MAIL_SUBJECT
        Body       = $iMessage
        Encoding   = $encoding
        SmtpServer = 'smtp.gmail.com'
        Port       = 587
        UseSsl     = $true
        Credential = $iCredential
    };

    return $retMailInfoTable;
}

# ------------------------------
# main
# ------------------------------
function main() {
    try {
        [System.Management.Automation.PSCredential]$credential = Build-Credential;
        [String]$message = Build-Message-Body;
        [HashTable]$mailParams = Build-Message-Params $credential $message;
    }
    catch {
        logging 'メールデータ構築時にエラーが発生しました' ([LogLevel]::ERROR);
        throw $_.Exception;
    }

    try {
        # Splattingでパラメータ指定
        Send-MailMessage @mailParams;
        logging 'メール送信を送信しました' ([LogLevel]::SUCCESS);
    }
    catch {
        logging 'メールデータ送信時にエラーが発生しました' ([LogLevel]::ERROR);
        throw $_.Exception;
    }
}

# ------------------------------
# ACTION
# ------------------------------
try {
    logging '処理開始' ([LogLevel]::INFO);
    main;
}
catch {
    logging $_.Exception ([LogLevel]::ERROR);
}
finally {
    logging '処理終了' ([LogLevel]::INFO);
}
exit 0;
