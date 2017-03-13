Function Get-OneDriveChildren
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
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [ValidateSet('folder', 'file')]
        [string]$ItemType
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
    $local:requestUri += '/children?filter=' + $ItemType + '%20ne%20null&select=id,name,size,webUrl,' + $ItemType + '&expand=thumbnails';
    Write-Verbose ('First request URI is ' + $local:requestUri);
    $local:allChildren = @();
    while ($local:requestUri -ne $null)
    {
        Write-Verbose ('Current page URI is ' + $local:requestUri);
        $local:response = Invoke-WebRequest -Uri $local:requestUri -Headers @{ 'Authorization' = 'Bearer ' + $AccessToken } -UseBasicParsing -ErrorAction:Stop;
        $local:responseObject = $local:response.Content | ConvertFrom-Json;
        if (-not (Assert-NoOneDriveError $local:responseObject))
        {
            Return;
        }
        $local:allChildren += $local:responseObject.value;
        $local:requestUri = $local:responseObject.'@odata.nextLink';
    }
    Write-Verbose 'No more pages.';
    Write-Output $local:allChildren;
}
