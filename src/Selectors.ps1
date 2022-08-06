using namespace System.Collections.Generic
using namespace System.Text

function ConvertTo-Filter {
    [CmdletBinding()]
    [OutputType('ProjectAccess.Filter')]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        $Selectors
    )

    process {
        $o = [PSCustomObject]@{
            'PSTypeName' = 'ProjectAccess.Filter'
            'includedTypes' = @{}
            'excludedTypes' = @{}
            'includedStates' = @{}
            'excludedStates' = @{}
            'includedStrings' = @{}
            'full' = $Selectors
        }

        $sels = -split $Selectors
        foreach ($sel in $sels) {
            $exclude = $sel.StartsWith('-')

            if ($sel -match '^-?is:(draft|issue|pr)$') {
                if ($exclude) { $o.excludedTypes[$Matches[1]] = $true }
                else { $o.includedTypes[$Matches[1]] = $true }
            } elseif ($sel -match '^-?is:(open|closed|merged)$') {
                if ($exclude) { $o.excludedStates[$Matches[1]] = $true }
                else { $o.includedStates[$Matches[1]] = $true }
            } else {
                $o.includedStrings[$sel] = $true
            }
        }

        $o
    }
}