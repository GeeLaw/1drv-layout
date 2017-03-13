Function New-OneDriveFolder
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$AccessToken,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    $local:ErrorActionPreference = 'Stop';
    $local:parent = Get-OneDriveItem -AccessToken $AccessToken -Id ((Get-Item '.').Name);
    if ($local:parent -eq $null)
    {
        Return;
    }
    if ($local:parent.folder -eq $null)
    {
        Write-Error 'Current object is not a folder.' -Category 'InvalidOperation';
        Return;
    }
    $local:payload = ($Name.GetEnumerator() | ForEach-Object {
        '\u' | Write-Output;
        ([int]$_).ToString('x4') | Write-Output;
    }) -join '';
    $local:payload = '{"name":"' + $local:payload + '","folder":{}}';
    $local:responseObject = Invoke-WebRequest -Uri ('https://graph.microsoft.com/v1.0/me/drive/items/' + $local:parent.id + '/children') -Method 'Post' -ContentType 'application/json' -Body $local:payload -Headers @{ 'Authorization' = ('Bearer ' + $AccessToken) } -UseBasicParsing -ErrorAction:Stop | ConvertFrom-Json;
    if (-not (Assert-NoOneDriveError $local:responseObject))
    {
        Return;
    }
    Download-OneDriveLayout -AccessToken $AccessToken -RootId $local:responseObject.id;
    $local:responseObject | Write-Output;
}
