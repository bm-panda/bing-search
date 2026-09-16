param($paramPath)

function Send-Bubble {
    param(
        [string]$ApiBase,
        [ValidateSet("success", "error", "info")]
        [string]$NotifyType,
        [string]$Message,
        [int]$Duration = 5000
    )
    try {
        $body = @{ notify_type = $NotifyType; message = $Message; duration = $Duration } | ConvertTo-Json -Compress
        Invoke-RestMethod -Method Post -Uri "$ApiBase/api/notify" -ContentType "application/json; charset=utf-8" -Body $body -TimeoutSec 5 | Out-Null
    } catch {
        Write-Output (@{ status = "notify_failed"; detail = $_.Exception.Message } | ConvertTo-Json -Compress)
    }
}

if (-not $paramPath) {
    Write-Output (@{ status = "error"; error = "缺少参数文件路径" } | ConvertTo-Json -Compress)
    exit 1
}

try {
    $payload = Get-Content -LiteralPath $paramPath -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    Write-Output (@{ status = "error"; error = "无法解析参数文件: $_" } | ConvertTo-Json -Compress)
    exit 1
}

$env = $payload.environment
$data = if ($payload.data) { $payload.data } else { @{} }

$keyword = [string]::Empty
if ($data.target_text) {
    $keyword = @($data.target_text)[0]
}
$keyword = $keyword.Trim()

if ([string]::IsNullOrWhiteSpace($keyword)) {
    if ($env -and $env.api_base) {
        Send-Bubble -ApiBase $env.api_base -NotifyType "info" -Message "请先复制文本，再双击 Ctrl+C 快速搜索必应" -Duration 3000
    }
    Write-Output (@{ status = "info"; message = "搜索关键词为空" } | ConvertTo-Json -Compress)
    exit 0
}

$encodedKeyword = [uri]::EscapeDataString($keyword)
$url = "https://cn.bing.com/search?q=$encodedKeyword"

if (-not [uri]::TryCreate($url, [System.UriKind]::Absolute, [ref]$null)) {
    if ($env -and $env.api_base) {
        Send-Bubble -ApiBase $env.api_base -NotifyType "error" -Message "搜索链接生成失败" -Duration 3000
    }
    Write-Output (@{ status = "error"; error = "搜索链接生成失败" } | ConvertTo-Json -Compress)
    exit 1
}

try {
    Start-Process $url
    Write-Output (@{ status = "ok"; keyword = $keyword; url = $url } | ConvertTo-Json -Compress)
} catch {
    try {
        [System.Diagnostics.Process]::Start($url) | Out-Null
        Write-Output (@{ status = "ok"; keyword = $keyword; url = $url } | ConvertTo-Json -Compress)
    } catch {
        if ($env -and $env.api_base) {
            Send-Bubble -ApiBase $env.api_base -NotifyType "error" -Message "打开浏览器失败: $($_.Exception.Message)" -Duration 3000
        }
        Write-Output (@{ status = "error"; error = "打开浏览器失败: $($_.Exception.Message)" } | ConvertTo-Json -Compress)
        exit 1
    }
}