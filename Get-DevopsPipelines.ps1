param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string] $Organization,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string] $Project,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $PAT 
)

$Uri = 'https://dev.azure.com/{0}/{1}/_apis/pipelines?api-version=7.0' -f $Organization, $Project
$Header = @{
    Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) 
}

Invoke-WebRequest -UseBasicParsing -Uri $Uri -Header $Header


