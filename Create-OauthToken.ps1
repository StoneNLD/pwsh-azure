param(
    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $ClientSecret = "",

    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $TenantId = "",

    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $ClientId = "",

    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Redirect_URI = "https://localhost:5001/",

    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $Scope = ".default offline_access"
)

$ClientSecret = [System.Web.HttpUtility]::UrlEncode($ClientSecret)
$Scope = [System.Web.HttpUtility]::UrlEncode($Scope)

# Cleanup
netsh http delete sslcert ipport=0.0.0.0:5001 > $null

# Remove Old certificates
Get-Childitem -Path 'Cert:\LocalMachine\My\' | where-object FriendlyName -eq 'Localhost Certificate for DevOps OAUTH' | remove-item
Get-Childitem -Path 'Cert:\LocalMachine\Root\' | where-object FriendlyName -eq 'Localhost Certificate for DevOps OAUTH' | remove-item

# Create new self signed and trust it.
$certificateObject = @{
    Subject = 'localhost'
    KeyAlgorithm = 'RSA'
    KeyLength = '2048'
    NotBefore = (Get-Date)
    NotAfter = (Get-Date).AddHours(2)
    CertStoreLocation = "cert:LocalMachine\My"
    FriendlyName = "Localhost Certificate for DevOps OAUTH"
    HashAlgorithm = 'SHA256'
    KeyExportPolicy = 'Exportable'
    KeyUsage = @('DigitalSignature', 'KeyEncipherment', 'DataEncipherment')
    TextExtension = @("2.5.29.17={text}DNS=localhost&IPAddress=127.0.0.1&IPAddress=::1")
}

$certificate = New-SelfSignedCertificate @certificateObject
$certificatePath = 'Cert:\LocalMachine\My\' + ($certificate.ThumbPrint) 

#make this certificate trusted (locally) (i.e. copy it from Personal store to Trusted Root CAs store)
$srcStore = New-Object System.Security.Cryptography.X509Certificates.X509Store "My", "LocalMachine"
$srcStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
 
$cert = $srcStore.certificates -match $certificate.Thumbprint
 
$dstStore = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root", "LocalMachine"
$dstStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
$dstStore.Add($cert[0])
 
$srcStore.Close()
$dstStore.Close()

# Assign Certificate to locahost:5001
netsh http add sslcert ipport=0.0.0.0:5001 certhash=($certificate.ThumbPrint).ToLower() appid=`{EDE3C891-306C-40fe-BAD4-895B236A1CC8`} > $null

$httpListener = New-Object System.Net.HttpListener
$httpListener.Prefixes.Add($Redirect_URI)
$httpListener.Start()

$URL = -join @(
    "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/authorize",
    "?client_id=$ClientId",
    "&response_type=code",
    "&response_mode=query",
    "&scope=$Scope",
    "&redirect_uri=$Redirect_URI"
)

Write-Output $URL

While ($httpListener.IsListening) {
    $context = $httpListener.GetContext()
    $Code = ($context.Request.RawUrl).split('/?code=')[1]
    $Code = ($Code).split('&')[0]
    $httpListener.Close()
}
netsh http delete sslcert ipport=0.0.0.0:5001 > $null

Get-Childitem -Path 'Cert:\LocalMachine\My\' | where-object FriendlyName -eq 'Localhost Certificate for DevOps OAUTH' | remove-item
Get-Childitem -Path 'Cert:\LocalMachine\Root\' | where-object FriendlyName -eq 'Localhost Certificate for DevOps OAUTH' | remove-item

$context | ConvertTo-Json -Depth 10
pause

## Get RefreshToken
$Body = -join @(
    "client_id=$ClientId",
    "&client_secret=$ClientSecret",
    "&code=$Code",
    "&grant_type=authorization_code",
    "&scope=$Scope",
    "&redirect_uri=$Redirect_URI"
)

$requestbody = @{
    Uri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    Method = 'POST'
    ContentType = "application/x-www-form-urlencoded"
}

$response = Invoke-WebRequest @requestbody -Body $Body
write-output $response.Content | ConvertFrom-Json