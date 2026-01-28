
# parameter
param (
    [Parameter(Mandatory)]
    [string]$url
)

# paths
. "$PSScriptRoot/function.ps1"
$cookies = "$PSScriptRoot/cookies.json"

# settings
$dir = (Get-Location).Path
$maxPages = 999
$minDelay = 1000
$maxDelay = 2001

# import cookies
Write-Host "Import cookies: " -NoNewLine
$session = Import-Cookies $cookies
# test cookies
$test = Test-Cookies $session
Write-Host $test.message
if (-not $test.success) { exit }

# download gallery
Write-Host "Download gallery to $($dir)."
$currentPage = $url
for ($i = 0; $i -lt $maxPages; $i++) {
    # random delay
    $delay = Get-Random -Min $minDelay -Max $maxDelay
    Start-Sleep -Milliseconds $delay
    # get current page
    Write-Host "$($currentPage): " -NoNewLine
    $gallery = Get-Gallery $currentPage $session
    if (-not $gallery.success) {
        Write-Host $gallery.message
        Write-Host "Failed!"
        exit
    }
    # save image
    $save = Save-Image $dir $gallery.imageUrl $session
    Write-Host $save.message
    if (-not $save.success) {
        Write-Host "Failed!"
        exit
    }
    # check next page
    if ($gallery.nextPage -ne $currentPage) {
        $currentPage = $gallery.nextPage
    } else {
        Write-Host "Finished."
        exit
    }
}

