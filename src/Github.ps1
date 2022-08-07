function Set-GithubAuth {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param(
        [Parameter(Mandatory)]
        [string]
        $Token
    )

    process {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseDeclaredVarsMoreThanAssignments','',Scope='Global')]
        $global:GH_TOKEN = ConvertTo-SecureString $Token -AsPlainText -Force
    }
}

function Request-GithubUserData {
    [CmdletBinding()]
    [OutputType([Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject])]
    param()

    process {
        $splat = @{
            'Uri' = 'https://api.github.com/user'
            'Authentication' = 'OAuth'
            'Token' = $global:GH_TOKEN
            'Headers' = @{
                'Accept' = 'application/vnd.github+json'
            }
        }
        $userData = Invoke-RestMethod @splat
    
        $userData
    }
}

function Register-ProjectItem {
    [CmdletBinding()]
    [OutputType([Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject])]
    param(
        [Parameter(Mandatory)]
        [string]
        $ProjectID,
        [Parameter(Mandatory)]
        [string]
        $ContentID
    )

    process {
        if ($null -eq $global:GH_TOKEN) {
            throw 'Not authenticated. Use: ''Set-GithubAuth''.';
        }

        $query = "{ `"query`":`"
            mutation addItem {
                addF:addProjectV2ItemById(input:{
                    projectId:\`"$ProjectID\`"
                    contentId:\`"$ContentID\`"
                }) {
                    item {
                        id
                    }
                }
            }`"
        }"

        $params = @{
            'Uri' = 'https://api.github.com/graphql'
            'Method' = 'POST'
            'Authentication' = 'OAuth'
            'Token' = $global:GH_TOKEN
            'Headers' = @{
                'Accept' = 'application/vnd.github+json'
            }
            'Body' = $($query -replace "`r`n","")
            'ContentType' = 'application/json'
        }

        Write-Host '[ProjectAccess] Sending request...'
        $res = Invoke-RestMethod @params -StatusCodeVariable 'statusCode'
        Write-Host "[ProjectAccess] Status code received: $statusCode"
        
        Write-Output $res
    }
}