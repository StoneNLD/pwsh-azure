# Using a PAT creating a PAT does not seem to work
# Line |
#   16 |  Invoke-WebRequest -UseBasicParsing -Uri $Uri -Header $Header
#      |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#      | {"$id":"1","innerException":null,"message":"The requested operation is not allowed.","typeName":"Microsoft.TeamFoundation.Framework.Server.InvalidAccessException,
#      | Microsoft.TeamFoundation.Framework.Server","typeKey":"InvalidAccessException","errorCode":0,"eventId":3000}

# Found it
# https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/manage-personal-access-tokens-via-api?view=azure-devops

param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string] $Organization,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string] $PAT
)

$Uri = 'https://vssps.dev.azure.com/{0}/_apis/tokens/pats?api-version=7.0-preview.1' -f $Organization
$Header = @{
    Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) 
}

Invoke-WebRequest -UseBasicParsing -Uri $Uri -Header $Header

