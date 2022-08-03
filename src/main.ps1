Param(
    [string]$token="",
    [string]$projectUrl="",
    [int]$projectNumber=-1,
    [string]$getItems="",
    [string]$readFields="",
    [string]$readItems="",
    [string]$addItems="",
    [string]$editFields=""
)

$Env:GH_TOKEN=$token;

Write-Host "Fetching user info...";
$userInfoQuery = gh api -H "Accept: application/vnd.github+json" /user;
Write-Host "Query result: `r`n $userInfoQuery";
Try {
    $userInfo = ConvertFrom-Json $userInfoQuery;
} Catch {
    Write-Host "User info fetching failed. (Invalid token?)";
    exit;
}