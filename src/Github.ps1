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