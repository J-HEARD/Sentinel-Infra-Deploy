param(
    [string] $PackageUri = 'https://raw.githubusercontent.com/J-HEARD/sentinel-deploy-mdvm/master/functionPackage.zip',
    [string] $ResourceGroupName,
    [string] $FunctionAppName
)

Invoke-WebRequest -Uri $PackageUri -OutFile functionPackage.zip
Publish-AzWebapp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ArchivePath functionPackage.zip -Force