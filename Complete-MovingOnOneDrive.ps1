Function Complete-MovingOnOneDrive
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$AccessToken,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Files
    )
    $local:ErrorActionPreference = 'Stop';
    $local:validParents = [System.Collections.Generic.HashSet[string]]::new();
    $Files | ForEach-Object {
        if (-not (Test-Path $_))
        {
            Write-Warning -Message ('Resource ' + $_ + ' does not exist and is skipped.');
        }
        else
        {
            $local:childId = [System.IO.Path]::GetFileNameWithoutExtension($_);
            $local:childItem = Get-OneDriveItem -AccessToken $AccessToken -Id $local:childId;
            if ($local:childItem -ne $null)
            {
                $local:parentId = [System.IO.Path]::GetFileName([System.IO.Path]::GetDirectoryName($_));
                if (-not ($local:validParents.Contains($local:parentId)))
                {
                    $local:parentItem = Get-OneDriveItem -AccessToken $AccessToken -Id $local:parentId;
                    if ($local:parentItem -ne $null -and $local:parentItem.folder -ne $null)
                    {
                        $local:validParents.Add($local:parentId);
                    }
                    else
                    {
                        Write-Warning -Message ('Parent objcet (' + $local:parentId + ') is not a folder.');
                    }
                }
                if ($local:validParents.Contains($local:parentId))
                {
                    $local:payload = @{ 'parentReference' = @{ 'id' = $local:parentId } } | ConvertTo-Json -Depth 10 -Compress;
                    $local:responseObject = Invoke-WebRequest -Uri ('https://graph.microsoft.com/v1.0/me/drive/items/' + $local:childId) -Method 'Patch' -ContentType 'application/json' -Body $local:payload -Headers @{ 'Authorization' = 'Bearer ' + $AccessToken } -UseBasicParsing -ErrorAction:Stop | ConvertFrom-Json;
                    Assert-NoOneDriveError $local:responseObject;
                }
            }
        }
    } | Out-Null;
}
