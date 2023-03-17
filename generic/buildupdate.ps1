$RootPath = $PSScriptRoot
$ErrorActionPreference = "Stop"

. (Join-Path $RootPath "settings.ps1")

function Head($text) {
    Write-Host -ForegroundColor Yellow $text
}

$testImages = $false

$pushto = @()
$pushto = @("prod")

$tags = (get-navcontainerimagetags -imageName "mcr.microsoft.com/businesscentral").tags | Where-Object { $_ -like "*-sql2017" }
[Array]::Reverse($tags)

# Pull all
$tags | % {
    $tag = $_
    head $tag
    $image = "mcr.microsoft.com/businesscentral:$tag"
    docker pull $image
}

docker system prune --force

if ((Read-Host -prompt "Continue (yes/no)?") -ne "Yes") {
    throw "Mission aborted"
}

$tags | % {
    $tag = $_
    
    head $tag
    
    $isolation = "hyperv"
    $baseimage = "mcr.microsoft.com/businesscentral:$tag"
    $osversion = $tag.Substring(0,$tag.IndexOf('-'))

    docker pull $baseimage

    $image = "my:$osversion-$genericTag"

    docker images --format "{{.Repository}}:{{.Tag}}" | % { 
        if ($_ -eq $image) 
        {
            docker rmi $image -f
        }
    }
    
    $dockerfile = Join-Path $RootPath "DOCKERFILE.UPDATE"

@"
FROM $baseimage

COPY Run /Run/

LABEL tag="$genericTag" \
      created="$created"
"@ | Set-Content $dockerfile

    docker build --isolation=$isolation `
                 --tag $image `
                 --file $dockerfile `
                 --memory 4G `
                 $RootPath

    if ($LASTEXITCODE -ne 0) {
        throw "Failed with exit code $LastExitCode"
    }
    Write-Host "SUCCESS"
    Remove-Item $dockerfile -Force

    # Test image
    if ($testImages) {
        $artifactUrl = Get-BCArtifactUrl -type OnPrem -country w1
        $password = 'P@ssword1'
        $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
        $credential = New-Object pscredential 'admin', $securePassword
        
        $parameters = @{
            "accept_eula"               = $true
            "containerName"             = "test"
            "artifactUrl"               = $artifactUrl
            "useGenericImage"           = $image
            "auth"                      = "NAVUserPassword"
            "Credential"                = $credential
            "updateHosts"               = $true
            "doNotCheckHealth"          = $true
            "EnableTaskScheduler"       = $false
            "Isolation"                 = "hyperv"
            "MemoryLimit"               = "8G"
        }
        
        New-NavContainer @parameters
        Remove-NavContainer -containerName "test"
    }

    $newtags = @()
    if ($pushto.Contains("prod")) {
        $newtags += @(
            "mcrbusinesscentral.azurecr.io/public/businesscentral:$osversion-$genericTag"
            "mcrbusinesscentral.azurecr.io/public/businesscentral:$osversion-sql2017"
        )
    }
    $newtags | ForEach-Object {
        Write-Host "Push $_"
        docker tag $image $_
        docker push $_
    }
    $newtags | ForEach-Object {
        Write-Host "Remove $_"
        docker rmi $_
    }
    docker rmi $image
}
