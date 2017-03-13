Function Publish-OneDriveFolderLayout
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )
    $local:ErrorActionPreference = 'Stop';
    $local:idPrefix = (Get-Item '.').Name;
    $local:idPrefix = $local:idPrefix.Substring(0, $local:idPrefix.IndexOf('!') + 1).ToLowerInvariant();
    if ($local:idPrefix.Length -lt 6)
    {
        Write-Error 'Cannot find id prefix.';
        Return;
    }
    Get-ChildItem -Directory -Recurse:$false |
        Where-Object { -not $_.Name.ToLowerInvariant().StartsWith($local:idPrefix) } |
        ForEach-Object {
        $local:subfolder = New-OneDriveFolder -AccessToken $AccessToken -Name $_.Name;
        if ($local:subfolder -ne $null)
        {
            $local:desktopiniPath = './' + $local:subfolder.id + '/desktop.ini';
            $local:newIni = "[.ShellClassInfo]`r`nLocalizedResourceName=$($local:subfolder.name)`r`n`r`n";
            Remove-Item $local:subfolder.id -Recurse -Force;
            Move-Item $_.FullName $local:subfolder.id;
            $local:oldIni = '';
            if ((Test-Path $local:desktopiniPath))
            {
                $local:oldIni = (Get-Content $local:desktopiniPath -Raw);
            }
            ($local:newIni + $local:oldIni) | Set-Content $local:desktopiniPath -Force -NoNewline -Encoding 'Unicode';
        }
    };
    Get-ChildItem -Directory -Recurse:$false | ForEach-Object {
        Push-Location;
        Set-Location $_.FullName;
        Publish-OneDriveFolderLayout -AccessToken $AccessToken;
        Pop-Location;
    };
}
