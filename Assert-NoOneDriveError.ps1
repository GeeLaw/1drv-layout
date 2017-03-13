Function Assert-NoOneDriveError
{
    Param
    (
        [object]$ResponseObject
    )
    if ($ResponseObject.error -eq $null)
    {
        Return $true;
    }
    $local:mainErrorCode = $ResponseObject.error.code;
    $local:errorSb = [System.Text.StringBuilder]::new($ResponseObject.error.message);
    $local:errorSb.Append(' Error chain: ');
    $local:errorSb.Append($local:mainErrorCode);
    $local:recursiveError = $ResponseObject.error.innerError;
    while ($local:recursiveError -ne $null)
    {
        $local:errorSb.Append(' <- ');
        $local:errorSb.Append($local:recursiveError.code);
    }
    Write-Error -Message ($local:errorSb.ToString()) -Category 'InvalidResult' -ErrorId $local:mainErrorCode -RecommendedAction 'Analyse the problem and continue later.';
    Return $false;
}
