function Assert-Auth {
    if ($null -eq $GH_TOKEN) {
        throw 'Not authenticated. Use: ''Set-GithubAuth''.';
    }
}

function Edit-ProjectItemField {
    [CmdletBinding(DefaultParameterSetName='Text')]
    [OutputType([Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject])]
    param(
        [Parameter(Mandatory)]
        [string]
        $ProjectID,
        [Parameter(Mandatory)]
        [string]
        $ItemID,
        [Parameter(Mandatory)]
        [string]
        $FieldID,
        
        [Parameter(Mandatory, ParameterSetName='Date')]
        [string] $DateValue,
        [Parameter(Mandatory, ParameterSetName='IterationID')]
        [string] $IterationIDValue,
        [Parameter(Mandatory, ParameterSetName='Number')]
        [float] $NumberValue,
        [Parameter(Mandatory, ParameterSetName='SingleSelectionOptionID')]
        [string] $SingleSelectionIDValue,
        [Parameter(Mandatory, ParameterSetName='Text')]
        [string] $TextValue
    )

    process {
        $val = switch ($PSCmdlet.ParameterSetName) {
            'Date' { "date:\`"$DateValue\`""; break; }
            'IterationID' { "iterationId:\`"$IterationIDValue\`""; break; }
            'Number' { "number: $NumberValue"; break; }
            'SingleSelectionOptionID' { "singleSelectOptionId:\`"$SingleSelectionIDValue\`""; break; }
            'Text' { "text:\`"$TextValue\`""; break; }
            default { throw "Unknown value type: '$($switch.Current)'." }
        }

        $query = "
        mutation UpdateItem {
            addF:updateProjectV2ItemFieldValue(input:{
                projectId:\`"$ProjectID\`"
                itemId:\`"$ItemID\`"
                fieldId:\`"$FieldID\`"
                value:{ $val }
            }) {
                clientMutationId
                projectV2Item {
                    id
                }
            }
        }"

        Send-GraphQLQuery -Query $query | Write-Output
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
        $query = "
        mutation AddItem {
            addF:addProjectV2ItemById(input:{
                projectId:\`"$ProjectID\`"
                contentId:\`"$ContentID\`"
            }) {
                item {
                    id
                }
            }
        }"

        Send-GraphQLQuery -Query $query | Write-Output
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
            'Token' = $GH_TOKEN
            'Headers' = @{
                'Accept' = 'application/vnd.github+json'
            }
        }
        $userData = Invoke-RestMethod @splat
    
        $userData
    }
}

function Request-ProjectFields {
    [CmdletBinding(DefaultParameterSetName='First')]
    [OutputType([Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject])]
    param(
        [Parameter(Mandatory)]
        [int] $ProjectNumber,

        [Parameter(Mandatory, ParameterSetName='First')]
        [Parameter(Mandatory, ParameterSetName='FirstAfter')]
        [Parameter(Mandatory, ParameterSetName='FirstBefore')]
        [int] $First,
        [Parameter(Mandatory, ParameterSetName='Last')]
        [Parameter(Mandatory, ParameterSetName='LastAfter')]
        [Parameter(Mandatory, ParameterSetName='LastBefore')]
        [int] $Last,
        [Parameter(Mandatory, ParameterSetName='FirstAfter')]
        [Parameter(Mandatory, ParameterSetName='LastAfter')]
        [string] $After,
        [Parameter(Mandatory, ParameterSetName='FirstBefore')]
        [Parameter(Mandatory, ParameterSetName='LastBefore')]
        [string] $Before
    )

    process {
        $fieldsParams = switch ($PSCmdlet.ParameterSetName) {
            'First' { "first:$First"; break; }
            'FirstAfter' { "first:$First, after:\`"$After\`""; break; }
            'FirstBefore' { "first:$First, before:\`"$Before\`""; break; }
            'Last' { "last:$Last"; break; }
            'LastAfter' { "last:$Last, after:\`"$After\`""; break; }
            'LastBefore' { "last:$Last, before:\`"$Before\`""; break; }
            default { throw "Unhandled parameter set: '$($PSCmdlet.ParameterSetName)'." }
        }

        $query = "
        query {
            viewer {
                projectV2(number:$ProjectNumber) {
                    id
                    title
                    fields($fieldsParams) {
                        edges {
                            cursor
                            node {
                                ... on ProjectV2FieldCommon {
                                    id
                                    databaseId
                                    dataType
                                    name
                                    createdAt
                                    updatedAt
                                }
                                ... on ProjectV2IterationField {
                                    configuration {
                                        duration
                                        iterations {
                                            id
                                            title
                                            startDate
                                            duration
                                        }
                                        completedIterations {
                                            id
                                            title
                                            startDate
                                            duration
                                        }
                                    }
                                }
                                ... on ProjectV2SingleSelectField {
                                    options {
                                        id
                                        name
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        "
        Send-GraphQLQuery -Query $query | Write-Output
    }
}

function Send-GraphQLQuery {
    [CmdletBinding()]
    [OutputType([Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject])]
    param(
        [Parameter(Mandatory)]
        [string]
        $Query
    )

    process {
        Assert-Auth

        $params = @{
            'Uri' = 'https://api.github.com/graphql'
            'Method' = 'POST'
            'Authentication' = 'OAuth'
            'Token' = $GH_TOKEN
            'Body' = "{ `"query`":`" " + $($Query -replace '(\r\n?)|(\n)',"") + "`"}"
            'ContentType' = 'application/json'
        }

        Write-Host "Query: $Query"
        Write-Host '[ProjectAccess] Sending request...'
        $res = Invoke-RestMethod @params -StatusCodeVariable 'statusCode'
        Write-Host "[ProjectAccess] Request reponse status code: $statusCode"
        if ($null -ne $res.errors) {
            Write-Error "ERROR"
            foreach ($err in $res.errors) {
                Write-Error "$($err.type) --- $($err.message)"
            }
            return $null
        }

        Write-Output $res
    }
}

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
        $script:GH_TOKEN = ConvertTo-SecureString $Token -AsPlainText -Force
    }
}