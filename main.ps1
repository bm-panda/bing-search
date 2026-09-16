param($paramPath)

if (-not $paramPath) {
    Add-Type -AssemblyName System.Windows.Forms
    $n = New-Object System.Windows.Forms.NotifyIcon
    $n.Icon = [System.Drawing.SystemIcons]::Information
    $n.BalloonTipTitle = "使用提示"
    $n.BalloonTipText = "请复制文本后双击 Ctrl+C 快速搜索必应"
    $n.Visible = $true
    $n.ShowBalloonTip(3000)
    Start-Sleep -Seconds 4
    $n.Visible = $false
    $n.Dispose()
    exit 0
}

try {
    $params = Get-Content $paramPath -Encoding UTF8 | ConvertFrom-Json
} catch {
    Write-Output (@{ error = "无法解析参数文件: $_" } | ConvertTo-Json -Compress)
    exit 1
}

$keyword = $params.data.target_text
if ([string]::IsNullOrWhiteSpace($keyword)) {
    Add-Type -AssemblyName System.Windows.Forms
    $n = New-Object System.Windows.Forms.NotifyIcon
    $n.Icon = [System.Drawing.SystemIcons]::Information
    $n.BalloonTipTitle = "使用提示"
    $n.BalloonTipText = "请复制文本后双击 Ctrl+C 快速搜索必应"
    $n.Visible = $true
    $n.ShowBalloonTip(3000)
    Start-Sleep -Seconds 4
    $n.Visible = $false
    $n.Dispose()
    exit 0
}

$keyword = $keyword.Trim()
Add-Type -AssemblyName System.Web
$encodedKeyword = [System.Web.HttpUtility]::UrlEncode($keyword)
$url = "https://cn.bing.com/search?q=$encodedKeyword"

try {
    Start-Process $url
    Write-Output (@{ status = "ok"; keyword = $keyword; url = $url } | ConvertTo-Json -Compress)
} catch {
    Write-Output (@{ status = "error"; error = "打开浏览器失败: $_" } | ConvertTo-Json -Compress)
    exit 1
}
