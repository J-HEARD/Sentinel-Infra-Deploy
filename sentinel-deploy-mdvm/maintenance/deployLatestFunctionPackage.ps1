param(
    [string] $PackageUri = 'https://raw.githubusercontent.com/J-HEARD/Sentinel-Infra-Deploy/master/sentinel-deploy-mdvm/functionPackage.zip',
    [string] $ResourceGroupName,
    [string] $FunctionAppName
)

Invoke-WebRequest -Uri $PackageUri -OutFile functionPackage.zip
Publish-AzWebapp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ArchivePath functionPackage.zip -Force