function Invoke-ReplacePrereleaseInFile($prereleaseTag, $file)
{
    $content = Get-Content $file
    $content -replace $prereleaseTag, '' | Set-Content $file
}

function Invoke-AddOrReplaceReleaseNotes($file, $releaseNotes)
{
    $content = Get-Content $file

    if ([string]::IsNullOrWhiteSpace($releaseNotes))
    {
		$content = $content -replace "\s*<releaseNotes>Summary of changes made in this release of the package.</releaseNotes>", ""
	}
	else
	{
        $generatedReleaseNoteTag = "<releaseNotes>Summary of changes made in this release of the package.</releaseNotes>"
        $emptyReleaseNoteTag = "<releaseNotes></releaseNotes>"
        $anyReleaseNotes = "<releaseNotes>.*</releaseNotes>"
        $newReleaseNotes = "<releaseNotes>$releaseNotes</releaseNotes>"

        if ($content -match $generatedReleaseNoteTag -or $content -match $emptyReleaseNoteTag)
		{
            $content = $content -replace $anyReleaseNotes, $newReleaseNotes
        }
        elseif (-not ($content -match $anyReleaseNotes))
        {
            $metadataCloseTag = "  </metadata>"
            
            $content = $content -replace $metadataCloseTag, "    $newReleaseNotes`r`n$metadataCloseTag"
        }
	}

    Set-Content $file $content
}

function Invoke-CheckPreReleaseDependencies($nuspecPath, $nupkgPackages)
{
    # Look through the dependencies in the file. If we find any that are 
    # prerelease packages (have a - in the version number) and aren't being
    # promoted as part of this process throw an exception! You shouldn't
    # have a released package with a prerelease dependency.
    $prereleaseCheck = "(<dependency id=.* version=.*\d(\.\d)+-.*/>)"

    $matches = Select-String $nuspecPath -Pattern $prereleaseCheck -AllMatches

    foreach ($match in $matches)
    {
        $dependantFilename = $match.Matches.Value -replace '<dependency id="(.*)" version="(.*\d(\.\d)+-.*)"\s*/>', '$1.$2.nupkg'
            
        $beingPromotedByUs = $false

        foreach ($package in $nupkgPackages)
        {
        
         # Package may or may not have symbols include - which alters the filename to .symbols.nupkg.
         # For this test, we want to match either .nupkg or .symbols.nupkg.
         $cleanedPackageName = $package.Name -Replace '.symbols', ''

            if ($cleanedPackageName -eq $dependantFilename)
            {
                $beingPromotedByUs = $true
                break
            }
        }

        if (!$beingPromotedByUs)
        {
            throw $nupkgFile.Name + " contains prerelease dependency " + $match.Matches.Value
        }
    }
}

function Invoke-PromotePackages($prereleaseTag, $allPackageNames, $releaseNotes) 
{
    foreach ($nupkgFile in $allPackageNames)
    {
        $nugetTempDir = $nupkgFile.Directory.FullName + "\nupkgpromotetmp"
	
        $zipfile = [Ionic.Zip.ZipFile]::Read($nupkgFile)
        #Extract the contents
        $zipfile.ExtractAll($nugetTempDir)
        $zipfile.Dispose()
    
        Write-Host "Promoting " $nupkgFile.Name
    
        # Strip the prerelease portion from the filename.
        $promotedNupkgFile = $nupkgFile.Name -Replace $prereleaseTag, ''
    
        # The Nuspec file inside the packge will use the following naming:
        # Some.Package.2.0.0-prerelease0012.symbols.nupkg
        # Some.Package.nuspec
        # So we already removed the -prerelease0012 above so here we want to ditch
        # the .symbols bit of the filename.
        $nuspecFilename = $promotedNupkgFile -Replace '.symbols', ''
    
        # Ok now we change 2.0.0.nupkg to just .nuspec
        # so we should now just have Some.Package.nuspec!
        $nuspecFilename = $nuspecFilename -Replace "(\.\d*)*.nupkg", ".nuspec"

        Invoke-CheckPreReleaseDependencies $nugetTempDir\$nuspecFilename $allPackageNames

        $nuspecFile = Get-ChildItem $nugetTempDir\$nuspecFilename
        Invoke-ReplacePrereleaseInFile $prereleaseTag $nuspecFile
        Invoke-AddOrReplaceReleaseNotes $nuspecFile $releaseNotes

        $manifestFile = Get-ChildItem $nugetTempDir\package\services\metadata\core-properties\*.psmdcp
        Invoke-ReplacePrereleaseInFile $prereleaseTag $manifestFile

        #Rebuild the nuget package
        $newPackagePath = $nupkgFile.Directory.FullName + "\" + $promotedNupkgFile
        
        Write-Host "Creating new package $newPackagePath."
        $zipfile = New-Object Ionic.Zip.ZipFile($newPackagePath)
        $zipfile.ParallelDeflateThreshold = -1;
        
        Write-Host "Adding $nugetTempDir."
        $zipfile.AddDirectory($nugetTempDir, '')
        
        Write-Host "Saving nupkg."
        $zipfile.Save()
        $zipfile.Dispose()

        Write-Host "Promoted to $promotedNupkgFile"
        Write-Host ""

        Remove-Item $nupkgFile
        Remove-Item $nugetTempDir -Force -Recurse
    }
}

function Invoke-CommenceUpgrade ($prereleaseTag, $nupkgFolder, $releaseNotes, $ionicZipDllLocation)
{
	if (!(Test-Path $ionicZipDllLocation))
    {
        Write-Host "##teamcity[buildProblem description='Could not find ionic zip dll $ionicZipDllLocation']"
        exit 1
    }
    
    Unblock-File -Path $zipDll
    Add-Type -Path $zipDll
    
    if ($nupkgFolder -ne "" -and -not $nupkgFolder.EndsWith("\"))
    {
        $nupkgFolder = $nupkgFolder + "\"
    }
	
	$nupkgSearch = $nupkgFolder + "*.nupkg"

    Write-Host "Looking for packages that contain $prereleaseTag in $nupkgSearch"

    $nupkgPackages = Get-ChildItem $nupkgSearch | Where-Object { $_.Name -match $prereleaseTag}

    Invoke-PromotePackages $prereleaseTag $nupkgPackages $releaseNotes
}