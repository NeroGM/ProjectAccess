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

##### Authentication

$Env:GH_TOKEN=$token;

Write-Host "Fetching user info...";
$userInfoQuery = gh api -H "Accept: application/vnd.github+json" /user;
Write-Host "Query result: `r`n $userInfoQuery";
Try { $userInfo = ConvertFrom-Json $userInfoQuery; }
Catch { Write-Host "User info fetching failed. (Invalid token?)"; exit 1; }

##### Fetch project id

If ($projectNumber -gt -1) {
    $projectInfoQuery = gh api graphql -f query="query GetItem {
        user(login:\`"$($userInfo.login)\`") {
          name
          projectV2(number:$projectNumber) {
            id
          }
        }
    }";
    Try { $json = ConvertFrom-Json $projectInfoQuery; }
    Catch { Write-Host "Project ID fetching failed. (token doesn't have `"project`" scope?)"; exit 1; }

    $projectId = $json.data.user.projectV2.id;
    Write-Host "Project ID fetched from given project number.";
}