
# Get-Response
function Get-Response([string]$url, [Microsoft.PowerShell.Commands.WebRequestSession]$session, [int]$delay = 100, [int]$retry = 10) {
    for ($try = 0; $try -lt $retry; $try++) {
        Start-Sleep -Milliseconds $delay
        try { $response = Invoke-WebRequest -Uri $url -WebSession $session } catch {}
        if ($response.StatusCode -eq 200) { break }
    }
    return $response
}

# Import-Cookies
function Import-Cookies([string]$cookies) {
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    foreach ($c in Get-Content $cookies | ConvertFrom-Json) {
        $cookie = New-Object System.Net.Cookie($c.Name, $c.Value, $c.Path, $c.Domain)
        $session.Cookies.Add($cookie)
    }
    return $session
}

# Test-Cookies
function Test-Cookies([Microsoft.PowerShell.Commands.WebRequestSession]$session) {
    $url = "https://exhentai.org/mytags"
    $response = Get-Response $url $session
    if ($response.StatusCode -ne 200) {
        return @{ success = $false; message = "connection error!" }
    } elseif ($response.RawContentLength -le 0) {
        return @{ success = $false; message = "invalid cookies!" }
    } else {
        return @{ success = $true; message = "valid cookies." }
    }
}

# Get-Gallery
function Get-Gallery([string]$url, [Microsoft.PowerShell.Commands.WebRequestSession]$session) {
    # response
    $response = Get-Response $url $session
    if ($response.StatusCode -ne 200) {
        return @{ imageUrl = ""; nextPage = ""; success = $false; message = "connection error!" }
    } elseif ($response.RawContentLength -le 0) {
        return @{ imageUrl = ""; nextPage = ""; success = $false; message = "invalid cookies!" }
    }
    # imageUrl
    if ($response.Content -match '<a href="(\S+)">Download original \d+ x \d+ \S+ \S+</a>') {
        $imageUrl = $matches[1]
    } elseif ($response.Content -match '<img id="img" src="(\S+)" style="\S+" onerror=".+?" onload="\S+"/>') {
        $imageUrl = $matches[1]
    } else {
        $imageUrl = ""
    }
    # nextPage
    if ($response.Content -match '<a id="next" onclick=".+?" href="(\S+)">') {
        $nextPage = $matches[1]
    } else {
        $nextPage = ""
    }
    # return
    if ($imageUrl -and $nextPage) {
        return @{ imageUrl = $imageUrl; nextPage = $nextPage; success = $true; message = "valid gallery." }
    } else {
        return @{ imageUrl = ""; nextPage = ""; success = $false; message = "invalid gallery!" }
    }
}

# Save-Image
function Save-Image([string]$dir, [string]$url, [Microsoft.PowerShell.Commands.WebRequestSession]$session) {
    # response
    $response = Get-Response $url $session
    if ($response.StatusCode -ne 200) {
        return @{ success = $false; message = "connection error!" }
    } elseif ($response.RawContentLength -le 0) {
        return @{ success = $false; message = "invalid cookies!" }
    } elseif ($response.Headers['Content-Type'] -notmatch '^image/\w+$' -or $url -notmatch '/([^/]+)$') {
        return @{ success = $false; message = "invalid image!" }
    } else {
        # file
        $file = $matches[1]
    }
    # save
    try {
        Set-Content -Path (Join-Path $dir $file) -Value $response.Content -AsByteStream -ErrorAction Stop
        return @{ success = $true; message = $file + " saved." }
    } catch {
        return @{ success = $false; message = "failed to save image: " + $_.Exception.Message }
    }
}

