Function Request-OneDriveToken
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$AppId
    )
    Start-Process ('https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=' + $AppId + '&scope=files.readwrite&response_type=token&redirect_uri=https://login.live.com/oauth20_desktop.srf');
    $local:responseUri = Read-Host -Prompt "Paste the result URI (leave empty to retrieve from the clipboard)";
    if ([System.String]::IsNullOrWhiteSpace($local:responseUri))
    {
        $local:responseUri = (Get-Clipboard -Format 'Text') -join '&';
    }
    $local:responseUri = $local:responseUri + '&';
    $local:matches = [System.Text.RegularExpressions.Regex]::new('access_token=(.*?)&').Matches($local:responseUri);
    if ($local:matches.Count -ne 1)
    {
        Write-Verbose ('Response URI is ' + $local:responseUri);
        Write-Error 'The matching does not exist or is not exact.';
        Return;
    }
    Write-Output ([System.Uri]::UnescapeDataString($local:matches[0].Groups[1].Value));
}
