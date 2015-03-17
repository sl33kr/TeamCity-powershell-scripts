# Installation

Create a new meta runner under your desired project (or parent project if you want to include in multiple) and paste in the below XML.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<meta-runner name="AssemblyInfo Patcher">
  <description>AssemblyInfo Patcher than can be run as a build step. This does not revert its changes.</description>
  <settings>
    <parameters>
      <param name="sourceserver.url" value="" spec="text description='Base url of your repo on your source control server.' display='normal' label='Source control server' validationMode='not_empty'" />
	  <param name="sourceserver.username" value="" spec="text description='Username of a user with read access.' display='normal' label='Source control user' validationMode='not_empty'" />
	  <param name="sourceserver.password" value="" spec="text description='Password of a user with read access.' display='normal' label='Source control password' validationMode='not_empty'" />
      <param name="assembly.version" value="" spec="text description='Specify assembly version format to update AssemblyVersion attribute' display='normal' label='Assembly Version' validationMode='not_empty'" />
      <param name="file.version" value="" spec="text description='Specify assembly file version format to update AssemblyFileVersion attribute. Leave blank to use same version as specified in assembly version.' display='normal' label='Assembly file version.' validationMode='any'" />
      <param name="informational.version" value="" spec="text description='Specify assembly informational version format to update AssemblyInformationalVersion attribute. Leave blank to leave attribute unchanged' display='normal' label='Assembly information version' validationMode='any'" />
    </parameters>
    <build-runners>
      <runner name="" type="jetbrains_powershell">
        <parameters>
          <param name="jetbrains_powershell_bitness" value="x86" />
          <param name="jetbrains_powershell_errorToError" value="true" />
          <param name="jetbrains_powershell_execution" value="PS1" />
          <param name="jetbrains_powershell_script_code"><![CDATA[Try
{
    $scriptName = "AssemblyInfoPatcherBuildStep.ps1"
	$repoUrl = "%sourceserver.url%"
	$repoUser = "%sourceserver.username%"
	$repoPassword = "%sourceserver.password%"
    $scriptDownloadInclude = Join-Path "%teamcity.agent.tools.dir%" "StashTeamCityRawFileRequest\TeamCityMetaRunnerScriptDownloader.ps1"
    
    Write-Host "Downloading $scriptName using $scriptDownloadInclude"
    
    . "$scriptDownloadInclude"

    if (Test-Path $scriptName)
    {
        Write-Host "$scriptName already exists, deleting."
        Remove-Item $scriptName
    }
	
    Write-Host "Downloading new version."
    Invoke-StashTeamCityRawFileRequest $repoUrl $scriptName $repoUser $repoPassword
    
    $assemblyVersion = "%assembly.version%"
    $fileVersion = "%file.version%"
    $informationalVersion = "%informational.version%" 
    
    Write-Host "Including $scriptName."
    . ".\$scriptName"
    
    Write-Host "Patching AssemblyInfo to $assemblyVersion; fileVersion: $fileVersion; informationalVersion = $informationalVersion"
    
    Invoke-PatchAssemblyFiles $assemblyVersion $fileVersion $informationalVersion

    Remove-Item $scriptName
}
Catch [Exception] {
    Write-Host $_.Exception.ToString()

    Write-Host "##teamcity[message text='Patching AssemblyInfo failed.' errorDetails='' status='ERROR']"
}]]></param>
          <param name="jetbrains_powershell_script_mode" value="CODE" />
          <param name="teamcity.step.mode" value="default" />
        </parameters>
      </runner>
    </build-runners>
    <requirements />
  </settings>
</meta-runner>
```