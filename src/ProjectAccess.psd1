@{
    GUID = '7e005485-5645-49c1-a0d7-03ce8ec884f1';
    PowerShellVersion = '7.0'

    RootModule = 'ProjectAccess.psm1';
    ModuleVersion = '0.1.0';
    Author = 'NeroGM';
    Copyright = 'No rights reserved.';

    FunctionsToExport = @(
        'ConvertTo-Filter'
        'Edit-ProjectItemField'
        'Register-ProjectItem'
        'Request-GithubUserData'
        'Request-ProjectFields'
        'Send-GraphQLQuery'
        'Set-GithubAuth'
    );
    CmdletsToExport = @();
    VariablesToExport = '*';
    AliasesToExport = @();
}