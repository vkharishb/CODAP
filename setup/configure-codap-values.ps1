[CmdletBinding()]
param(
    [string]$Profile = "codap",
    [string]$Region = "ap-south-2"
)

$ErrorActionPreference = "Stop"

function ConvertFrom-SecureStringPlainText {
    param([Parameter(Mandatory)][Security.SecureString]$SecureValue)
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

Write-Host "Configuring CODAP CI/CD values in AWS Region $Region using profile $Profile"

$sonarTokenSecure = Read-Host "Enter SONAR_TOKEN" -AsSecureString
$nvdApiKeySecure = Read-Host "Enter NVD_API_KEY (press Enter for empty)" -AsSecureString
$sonarToken = ConvertFrom-SecureStringPlainText $sonarTokenSecure
$nvdApiKey = ConvertFrom-SecureStringPlainText $nvdApiKeySecure

if ([string]::IsNullOrWhiteSpace($sonarToken)) {
    throw "SONAR_TOKEN cannot be empty."
}

$secretObject = [ordered]@{
    SONAR_TOKEN = $sonarToken
    NVD_API_KEY  = $nvdApiKey
}

$tempSecretFile = Join-Path $env:TEMP ("codap-ci-security-{0}.json" -f ([guid]::NewGuid()))
try {
    $secretObject | ConvertTo-Json -Compress | Set-Content -Path $tempSecretFile -Encoding utf8NoBOM

    aws secretsmanager describe-secret `
        --secret-id codap/ci-security `
        --region $Region `
        --profile $Profile *> $null

    if ($LASTEXITCODE -eq 0) {
        aws secretsmanager put-secret-value `
            --secret-id codap/ci-security `
            --secret-string "file://$tempSecretFile" `
            --region $Region `
            --profile $Profile | Out-Null
        Write-Host "Updated Secrets Manager secret: codap/ci-security"
    }
    else {
        aws secretsmanager create-secret `
            --name codap/ci-security `
            --description "CODAP CI security scanner credentials" `
            --secret-string "file://$tempSecretFile" `
            --region $Region `
            --profile $Profile | Out-Null
        Write-Host "Created Secrets Manager secret: codap/ci-security"
    }
}
finally {
    if (Test-Path $tempSecretFile) {
        Remove-Item -Force $tempSecretFile
    }
    $sonarToken = $null
    $nvdApiKey = $null
}

$tfBackendBucket = Read-Host "Terraform backend S3 bucket name"
$eksClusterName = Read-Host "EKS cluster name"
$sonarHostUrl = Read-Host "Sonar host URL (example: https://sonarcloud.io)"
$sonarOrganization = Read-Host "Sonar organization"
$sonarProjectKey = Read-Host "Sonar project key (example: vkharishb_CODAP)"

$parameters = [ordered]@{
    "/codap/dev/tf-backend-bucket" = $tfBackendBucket
    "/codap/dev/eks-cluster-name" = $eksClusterName
    "/codap/ci/sonar-host-url" = $sonarHostUrl
    "/codap/ci/sonar-organization" = $sonarOrganization
    "/codap/ci/sonar-project-key" = $sonarProjectKey
}

foreach ($entry in $parameters.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace($entry.Value)) {
        throw "Parameter $($entry.Key) cannot be empty."
    }

    aws ssm put-parameter `
        --name $entry.Key `
        --type String `
        --value $entry.Value `
        --overwrite `
        --region $Region `
        --profile $Profile | Out-Null

    Write-Host "Configured Parameter Store value: $($entry.Key)"
}

Write-Host "CODAP Secrets Manager and Parameter Store configuration completed."
