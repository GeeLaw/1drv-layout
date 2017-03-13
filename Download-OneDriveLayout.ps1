Function Download-OneDriveLayout
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$AccessToken,
        [Parameter(Mandatory = $true)]
        [string]$RootId,
        [Parameter(Mandatory = $false)]
        [ValidateRange(10, 55)]
        [int]$MaxJobCount = 55
    )
    $local:ErrorActionPreference = 'Stop';
    $local:root = Get-OneDriveItem -AccessToken $AccessToken -Id $RootId -Verbose:$false;
    Push-Location;
    If (-not (Test-Path ('./' + $local:root.id)))
    {
        New-Item -Path '.' -Name $local:root.id -ItemType 'Directory' | Set-Location;
    }
    Else
    {
        Set-Location ('./' + $local:root.id);
    }
    if (-not (Test-Path './desktop.ini'))
    {
        $local:jobs = @();
        $local:children = Get-OneDriveChildren -AccessToken $AccessToken -Id $RootId -ItemType 'file' -Verbose:$false;
        $local:desktopini = $local:children | ForEach-Object {
            if ($_.thumbnails.Count -ne 0)
            {
                while ((Get-BitsTransfer).Count -ge $MaxJobCount)
                {
                    Start-Sleep 1;
                    while (($local:jobs | Where-Object JobState -ne 'Transferred').Count -ne 0)
                    {
                        Start-Sleep 1;
                    }
                    $local:jobs | Complete-BitsTransfer;
                    $local:jobs = @();
                    Write-Verbose 'Finished all current downloading.';
                }
                if (-not (Test-Path ('./' + $_.id + '.jpg')))
                {
                    $local:jobs += Start-BitsTransfer -Asynchronous -Source $_.thumbnails[0].large.url -Destination ('./' + $_.id + '.jpg') -Description ('Downloaded the thumbnail of ' + $_.name + ' (' + $_.id + ')');
                    Write-Verbose ('Added the thumbnail of ' + $_.name + ' to the job list');
                }
                Write-Output ($_.id + '.jpg=' + $_.name);
            }
            else
            {
                ('CreateObject("WScript.Shell").Run "' + $_.webUrl + '"') | Set-Content "./$($_.id).vbs" -Encoding Ascii;
                Write-Verbose ('Created link for ' + $_.name);
                Write-Output ($_.id + '.vbs=' + $_.name);
            }
        };
        while (($local:jobs | Where-Object JobState -ne 'Transferred').Count -ne 0)
        {
            Start-Sleep 1;
        }
        $local:jobs | Complete-BitsTransfer;
        Write-Verbose 'Finished all current downloading.';
        (@('[.ShellClassInfo]', "LocalizedResourceName=$($local:root.name)", '',
            '[LocalizedFileNames]') + $desktopini + @('')) -join "`r`n" | Set-Content '.\desktop.ini' -Encoding Unicode -NoNewline -Force;
        $local:attrItem = Get-ChildItem '.\desktop.ini' -Force;
        $local:attrItem.Attributes = $local:attrItem.Attributes -bor [System.IO.FileAttributes]::System -bor [System.IO.FileAttributes]::Hidden;
    }
    else
    {
        Write-Verbose 'Skipping this folder, it is already done.';
    }
    $local:attrItem = Get-Item '.';
    $local:attrItem.Attributes = $local:attrItem.Attributes -bor [System.IO.FileAttributes]::System;
    $local:children = Get-OneDriveChildren -AccessToken $AccessToken -Id $RootId -ItemType 'folder' -Verbose:$false;
    $local:children | Where-Object folder -ne $null | ForEach-Object {
        Write-Verbose ('Processing subfolder ' + $_.name);
        Download-OneDriveLayout -AccessToken $AccessToken -RootId $_.id -MaxJobCount $MaxJobCount;
        Write-Verbose ('Finished processing subfolder ' + $_.name);
    };
    Pop-Location;
}
