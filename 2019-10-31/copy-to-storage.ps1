param (
    [Parameter(Mandatory = $true)]
    $StorageAccountName,
    $ResourceGroupName = "arm-deployment",
    $ContainerName = "linkedfiles",
    $Location = "westeurope",
    $LinkedfilesLocalPath = "./NestedTemplates"
)
$ErrorActionPreference = "Stop"

Write-Host "Deploying a storage account using ARM template from kingofarm.com..."
New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force | Out-Null
$storageAccountDeployment = New-AzResourceGroupDeployment `
    -TemplateUri "http://kingofarm.com/2019-10-31/NestedTemplates/storage.json" `
    -Name 'storage-deployment' `
    -ResourceGroupName $ResourceGroupName `
    -TemplateParameterObject @{ `
        storageAccountName = $StorageAccountName; `
        containerName      = $ContainerName
}
Write-Host "Successfully deployed storage account '$StorageAccountName' in resource group '$ResourceGroupName'!"

$storageKeys = $storageAccountDeployment.Outputs.storageKeys.Value.ToString() | ConvertFrom-Json -AsHashtable
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageKeys.keys[0].value

Write-Host "Copying all files from '$LinkedfilesLocalPath' to the storage account..."
$LinkedfilesLocalPath = (Resolve-Path -Path $LinkedfilesLocalPath).Path
$counter = 0
Get-ChildItem -File -Recurse $LinkedfilesLocalPath | ForEach-Object {
    Set-AzStorageBlobContent `
        -File $_.FullName `
        -Blob $_.FullName.Substring($LinkedfilesLocalPath.Length + 1) `
        -Container $ContainerName `
        -Context $ctx `
        -Force | Out-Null
    $counter += 1
}
Write-Host "Successfully copied $counter files to storage account '$StorageAccountName'!"
