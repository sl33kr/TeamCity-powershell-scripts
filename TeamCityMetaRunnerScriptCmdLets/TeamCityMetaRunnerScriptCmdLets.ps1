<#
THIS FILE IS TO BE COPIED TO THE StashTeamCityRawFileRequest Folder in TeamCityData\plugins\.tools
#>

<#
.Synopsis
   Downloads the given script from the Stash repo.
.DESCRIPTION
   Downloads the given script from the Stash repo.
.EXAMPLE
   Example of how to use this cmdlet
#>
function Invoke-StashTeamCityRawFileRequest
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=0)]
        $stashRepoUrl,
		[Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=1)]
        $scriptName,
		[Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=2)]
        $userName,
		[Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=3)]
        $password
    )

    Process
    {
        $scriptUrl = $stashRepoUrl + $scriptName + '?raw'

        $headers = Get-StashAuthHeader $userName $password
        
        if (Test-Path $scriptName)
        {
            Remove-Item $scriptName
        }

        Invoke-WebRequest -Uri $scriptUrl -OutFile "$scriptName" -Headers $headers
    }
}

function Get-StashAuthHeader
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
		[Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=0)]
        $user,
		[Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=1)]
        $pass
    )

    Process
    {
        $auth = $user + ":" + $pass
        $encodedAuth = [System.Text.Encoding]::UTF8.GetBytes($auth)
        $encodedPass = [System.Convert]::ToBase64String($encodedAuth)

        $headers = @{"Authorization"="Basic $($encodedPass)"}

        $headers
    }
}