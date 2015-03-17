function GetPatchNumberFromStash($buildAgentToolsDir, $stashBaseUrl, $stashProjectKey, $stashRepoSlug)
{
    $TeamCityMetaRunnerScriptCmdLets = Join-Path $buildAgentToolsDir "TeamCityMetaRunnerScriptCmdLets\TeamCityMetaRunnerScriptCmdLets.ps1"
    . $TeamCityMetaRunnerScriptCmdLets
    
    $headers = Get-StashAuthHeader
    
    $stashUrl = "$stashBaseUrl/rest/api/1.0/projects/$stashProjectKey/repos/$stashRepoSlug/tags?orderBy=MODIFICATION"

    $response = Invoke-RestMethod $stashUrl -Method Get -Headers $headers -ContentType "application/json"

    Write-Host "Looking for tags to match %version.major.minor%"
    
    $versionsToConsider = @()
    if ($response.values.Count -ne 0)
    {
        foreach ($tag in $response.values)
        {
            if ($tag.displayId.StartsWith("%version.major.minor%"))
            {
                $versionsToConsider= $versionsToConsider + @(New-Object System.Version($tag.displayId))
            }
        }
    }

    $nextPatchVersion = 0

    if ($versionsToConsider.Count -ne 0)
    {
        Write-Host "Found the following tags that match this Major.Minor"
        foreach($v in $versionsToConsider)
        {
            Write-Host $v.ToString()
        }

        $versionsToConsider = $versionsToConsider | Sort

        $max = $versionsToConsider[$versionsToConsider.Count - 1]
        Write-Host "Max version is $max"

        $nextPatchVersion = $max.Build + 1
    }

    Write-Host "Next patch is $nextPatchVersion"

    $nextPatchVersion
}

function Get-StashPatchVersion($buildAgentToolsDir, $currentBuild, $stashProjectKey, $stashRepoSlug, $stashBaseUrl, $majorMinor)
{
    $patchPlaceHolder = "{tag.patch}"
    
    if(!$currentBuild.Contains($patchPlaceHolder))
    {
        Write-Host "##teamcity[message text='Could not find place holder $patchPlaceHolder in build number $currentBuild' status='WARNING']"
        Exit
    }

    $nextPatchVersion = GetPatchNumberFromStash $buildAgentToolsDir $stashBaseUrl $stashProjectKey $stashRepoSlug

    $newBuild = $currentBuild -replace $patchPlaceHolder, $nextPatchVersion

    Write-Host "##teamcity[setParameter name='build.version' value='$majorMinor.$nextPatchVersion']"
    Write-Host "##teamcity[buildNumber '$newBuild']"
}