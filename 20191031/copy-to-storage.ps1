#Change the storageAccountName to something gloabally unique
$storageAccountName = "kingofarmdeployment"

$resourceGroupName = "arm-deployment"
$containerName = "linkedfiles"
$location = "westeurope"

$linkedfilesLocalPath = "./NestedTemplates"

Write-Host "Deploying a storage account using ARM template from kingofarm.com..."
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force | Out-Null
$storageAccountDeployment = New-AzResourceGroupDeployment `
    -TemplateUri "http://kingofarm.com/20191031/NestedTemplates/storage.json" `
    -Name storage-deployment `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -TemplateParameterObject @{ `
        storageAccountName = $storageAccountName; `
        containerName      = $containerName
}
Write-Host "Successfully deployed storage account '$storageAccountName' in resource group '$resourceGroupName'!"

$storageKeys = $storageAccountDeployment.Outputs.storageKeys.Value.ToString() | ConvertFrom-Json -AsHashtable
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKeys.keys[0].value

Write-Host "Copying all files from '$linkedfilesLocalPath' to the storage account..."
$linkedfilesLocalPath = (Resolve-Path -Path $linkedfilesLocalPath).Path
$counter = 0
Get-ChildItem -File -Recurse $linkedfilesLocalPath | ForEach-Object {
    Set-AzStorageBlobContent `
        -File $_.FullName `
        -Blob $_.FullName.Substring($linkedfilesLocalPath.Length + 1) `
        -Container $containerName `
        -Context $ctx `
        -Force | Out-Null
    $counter += 1
}
Write-Host "Successfully copied $counter files to storage account '$storageAccountName'!"
