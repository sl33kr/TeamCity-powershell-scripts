function Invoke-ReportPaddedBuildNumber($buildCounter, $buildNumber)
{
    $paddedBuildNumber = "{0:D4}" -f $buildCounter
    $newBuild = $buildNumber -Replace "{padded.build.counter}", $paddedBuildNumber
    Write-Host "##teamcity[setParameter name='padded.build.counter' value='$paddedBuildNumber']"
    Write-Host "##teamcity[buildNumber '$newBuild']"
}