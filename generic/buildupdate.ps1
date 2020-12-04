$RootPath = $PSScriptRoot
$ErrorActionPreference = "Stop"

. (Join-Path $RootPath "settings.ps1")

function Head($text) {
    try {
        $s = (New-Object System.Net.WebClient).DownloadString("http://artii.herokuapp.com/make?text=$text")
    } catch {
        $s = $text
    }
    Write-Host -ForegroundColor Yellow $s
}

$testImages = $false

$pushto = @()
$pushto = @("prod")

$tags = @(
"10.0.14393.2906-0.1.0.25"
"10.0.14393.2972-0.1.0.25"
"10.0.14393.3025-0.1.0.25"
"10.0.14393.3085-0.1.0.25"
"10.0.14393.3144-0.1.0.25"
"10.0.14393.3204-0.1.0.25"
"10.0.14393.3326-0.1.0.25"
"10.0.14393.3384-0.1.0.25"
"10.0.14393.3443-0.1.0.25"
"10.0.14393.3630-0.1.0.25"
"10.0.14393.3750-0.1.0.25"
"10.0.14393.3808-0.1.0.25"
"10.0.14393.3866-0.1.0.25"
"10.0.14393.3930-0.1.0.25"
"10.0.14393.3986-0.1.0.25"
"10.0.14393.4046-0.1.0.25"
"10.0.17134.1006-0.1.0.25"
"10.0.17134.1130-0.1.0.25"
"10.0.17134.706-0.1.0.25"
"10.0.17134.766-0.1.0.25"
"10.0.17134.829-0.1.0.25"
"10.0.17134.885-0.1.0.25"
"10.0.17134.950-0.1.0.25"
"10.0.17763.1158-0.1.0.25"
"10.0.17763.1282-0.1.0.25"
"10.0.17763.1339-0.1.0.25"
"10.0.17763.1397-0.1.0.25"
"10.0.17763.1457-0.1.0.25"
"10.0.17763.1518-0.1.0.25"
"10.0.17763.1577-0.1.0.25"
"10.0.17763.437-0.1.0.25"
"10.0.17763.504-0.1.0.25"
"10.0.17763.557-0.1.0.25"
"10.0.17763.615-0.1.0.25"
"10.0.17763.678-0.1.0.25"
"10.0.17763.737-0.1.0.25"
"10.0.17763.864-0.1.0.25"
"10.0.17763.914-0.1.0.25"
"10.0.17763.973-0.1.0.25"
"10.0.18362.1016-0.1.0.25"
"10.0.18362.1082-0.1.0.25"
"10.0.18362.1139-0.1.0.25"
"10.0.18362.116-0.1.0.25"
"10.0.18362.1198-0.1.0.25"
"10.0.18362.175-0.1.0.25"
"10.0.18362.239-0.1.0.25"
"10.0.18362.295-0.1.0.25"
"10.0.18362.356-0.1.0.25"
"10.0.18362.476-0.1.0.25"
"10.0.18362.535-0.1.0.25"
"10.0.18362.592-0.1.0.25"
"10.0.18362.658-0.1.0.25"
"10.0.18362.778-0.1.0.25"
"10.0.18362.900-0.1.0.25"
"10.0.18362.959-0.1.0.25"
"10.0.18363.1016-0.1.0.25"
"10.0.18363.1082-0.1.0.25"
"10.0.18363.1139-0.1.0.25"
"10.0.18363.1198-0.1.0.25"
"10.0.18363.476-0.1.0.25"
"10.0.18363.535-0.1.0.25"
"10.0.18363.592-0.1.0.25"
"10.0.18363.658-0.1.0.25"
"10.0.18363.778-0.1.0.25"
"10.0.18363.900-0.1.0.25"
"10.0.18363.959-0.1.0.25"
"10.0.19041.329-0.1.0.25"
"10.0.19041.388-0.1.0.25"
"10.0.19041.450-0.1.0.25"
"10.0.19041.508-0.1.0.25"
"10.0.19041.572-0.1.0.25"
"10.0.19041.630-0.1.0.25"
"10.0.19042.572-0.1.0.25"
"10.0.19042.630-0.1.0.25"

)

[Array]::Reverse($tags)

$oldGenericTag = "0.1.0.26"
$tags | % {
    $tag = $_
    
    $osversion = $tag.Substring(0,$tag.IndexOf('-'))
    $image = "my:$osversion-$oldGenericTag"

    docker images --format "{{.Repository}}:{{.Tag}}" | % { 
        if ($_ -eq $image) 
        {
            docker rmi $image -f
        }
    }
}

$tags | % {
    $tag = $_
    head $tag
    $image = "mcr.microsoft.com/businesscentral:$tag"
    docker pull $image
}

throw "go!"

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
            "mcrbusinesscentral.azurecr.io/public/businesscentral:$osversion-$genericTag")
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
}
