Function Reset-OneDriveMess
{
    0..99 | ForEach-Object { Pop-Location; };
    $local:replacer = [System.Text.RegularExpressions.Regex]::new('=@(.*?),\d+');
    Get-ChildItem desktop.ini -Force -File -Recurse | ForEach-Object {
        $local:content = Get-Content -Path $_.FullName -Raw;
        $local:content = $local:replacer.Replace($local:content, '=$1');
        $local:content | Set-Content -Path $_.FullName -Encoding Unicode -NoNewline;
        $_.Attributes = $_.Attributes -bor [System.IO.FileAttributes]::System -bor [System.IO.FileAttributes]::Hidden;
    };
    Get-ChildItem -Directory -Recurse -Force | ForEach-Object {
        $_.Attributes = $_.Attributes -bor [System.IO.FileAttributes]::System;
    };
    0..5 | ForEach-Object {
        If ((Get-BitsTransfer).Count -ne 0)
        {
            Start-Sleep 1;
            Get-BitsTransfer | Resume-BitsTransfer;
        }
    };
    Write-Host 'Try Get-BitsTransfer to make sure no more transfers are in progress.';
    Write-Host 'You can try resuming the task, perhaps after renewing the token.';
}
