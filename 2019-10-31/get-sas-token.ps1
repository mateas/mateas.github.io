param (
    [Parameter(Mandatory = $true)]
    $StorageAccountName,
    $ResourceGroupName = "arm-deployment",
    $ContainerName = "linkedfiles",
    $Location = "westeurope",
    $LinkedfilesLocalPath = "./NestedTemplates"
)
$ErrorActionPreference = "Stop"

Write-Host "Creating a one hour valid SAS token for storage account '$StorageAccountName' and container '$ContainerName'..."
$storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$ReadPermission = 'r'
$StartTime = Get-Date
$EndTime = $startTime.AddHours(1)
$sasToken = New-AzStorageContainerSASToken `
    -Container $ContainerName `
    -StartTime $StartTime `
    -ExpiryTime $EndTime `
    -Permission $ReadPermission `
    -Context $storageAccount.Context
return $sasToken