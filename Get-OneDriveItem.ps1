Function Get-OneDriveItem
{
    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$AccessToken,
        [Parameter(Mandatory = $false, ParameterSetName = 'ByPath')]
        [string]$Path = '/',
        [Parameter(Mandatory = $true, ParameterSetName = 'BySpecialFolderName')]
        [ValidateSet('documents', 'photos', 'cameraroll', 'approot', 'music')]
        [string]$SpecialFolder,
        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string]$Id
    )
    $local:requestUri = 'https://graph.microsoft.com/v1.0/me/drive/';
    switch ($PSCmdlet.ParameterSetName)
    {
        'ByPath'
        {
            $local:requestUri += 'root:' + [System.Uri]::EscapeUriString($Path) + ':';
        }
        'BySpecialFolderName'
        {
            $local:requestUri += 'special/' + $SpecialFolder;
        }
        'ById'
        {
            $local:requestUri += 'items/' + $Id;
        }
    }
    Write-Verbose ('Request URI is ' + $local:requestUri);
    $local:response = Invoke-WebRequest -Uri $local:requestUri -Headers @{ 'Authorization' = 'Bearer ' + $AccessToken } -UseBasicParsing -ErrorAction:Stop;
    $local:responseObject = $local:response.Content | ConvertFrom-Json;
    if (-not (Assert-NoOneDriveError $local:responseObject))
    {
        Return;
    }
    $local:responseObject | Write-Output;
}
