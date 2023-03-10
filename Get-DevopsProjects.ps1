param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $Organization,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $PAT 
)

# $AccessToken = (Get-AzAccessToken).Token
# $Header = @{ Authorization = "Bearer {0}" -f $AccessToken }

$Uri = 'https://dev.azure.com/{0}/_apis/projects?api-version=5.1' -f $Organization
$Header = @{
    Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) 
}

Invoke-RestMethod -Uri $Uri -Method get -Headers $Header 