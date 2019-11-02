
param (
    [Parameter(Mandatory = $true)]
    $NewStorageAccountName,
    [Parameter(Mandatory = $true)]
    $NewResourceGroup,
    $Location = "west europe"
)

#Change NestedTemplatesStorageAccountName to something globally unique for you
$NestedTemplatesStorageAccountName = "kingofarmdeployment2"

. "./copy-to-storage.ps1" -StorageAccountName $NestedTemplatesStorageAccountName

$linkedTemplatesStorage = . "./get-sas-token.ps1" -StorageAccountName $NestedTemplatesStorageAccountName

Write-Host "Deploying a 'parent-arm.json' nested template example to resource group '$NewResourceGroup'..."
New-AzResourceGroup -Name $NewResourceGroup -Location $Location -Force | Out-Null
New-AzResourceGroupDeployment `
    -TemplateFile "./parent-arm.json" `
    -Name 'nested-deployment-example' `
    -ResourceGroupName $NewResourceGroup `
    -TemplateParameterObject @{ `
        TemplateURL        = $linkedTemplatesStorage.Endpoint; `
        TemplateToken      = $linkedTemplatesStorage.SASToken; `
        StorageAccountName = $NewStorageAccountName
}


