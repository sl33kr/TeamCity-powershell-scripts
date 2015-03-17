function PatchVersion ($assemblyInfo, $version, $fileVersion, $informationVersion)
{
    Write-Host ""
    Write-Host "Patching $assemblyInfo"

    if ($fileVersion -eq "") { $fileVersion = $version }

    $content = Get-Content $assemblyInfo | ForEach-Object {
                                                $_ = StringReplace $_ "" $version
                                                $_ = StringReplace $_ "File" $fileVersion
                                                if ($informationVersion -ne "") { $_ = StringReplace $_ "Informational" $informationVersion }
                                                $_
                                            }

    Set-Content -Path $assemblyInfo -Value $content -Encoding UTF8
}

function StringReplace ($content, $versionType, $versionNumber)
{
    $searchString = "^(<|\[)(a|A)ssembly: Assembly" + $versionType + "Version\(`".*`"\)(>|\])"
    $replaceString = '$1$2ssembly: Assembly' + $versionType + 'Version("' + $versionNumber + '")$3'
    if ($content -match $searchString)
    {
        return $content -replace $searchString, $replaceString
    }
    else
    {
        return $content
    }
}

function Invoke-PatchAssemblyFiles($assemblyVersion, $fileVersion, $informationalVersion)
{
	Get-ChildItem -Directory -Recurse |
	  Where-Object { $_.Name -match "(My Project|Properties)" } |
	  ForEach-Object { Get-ChildItem $_.FullName } |
	  Where-Object { $_.Name -match "AssemblyInfo\.(cs|vb)" } |
	  ForEach-Object { PatchVersion $_.FullName $assemblyVersion $fileVersion $informationalVersion }
}