---
layout: post
title: "Work with linked templates"
date: 2019-11-02
tags: [ARM, ARM-template, PowerShell, Azure, Deployment]
---

Linked templates is the ARM template feature that allows you to separate different resource deployments into simple and easy to use templates. A common pattern is to separate all individual resources into separate templates and then having one or multiple "parent" templates referenceing those individual ones. This is what Microsoft calls <a href="https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-linked-templates#external-template" target="_blank">_linked templates_</a>.

The only issue with linked templates is that the template tha is being linked must be availbale on the Internet and cannot be supplied at deploytime together with the _parent_ template.

## Step 1: Make your templates available in private storage account

A simple solution to this is to copy you linked templates into a Azure storage account container with no public access. When you are to deploy your master template, create a SAS token for the container and supply that to your master template as a ARM parameter.

### Copy-script for your linked templates

#### Create a Azure storage account for your nested templates

You can use a ARM template from kingofarm.com as in following example but there are alternatives. You can use AZ CLI, Az PowerShell module or an custom ARM template of your own to create the storage account. Here we use a simple ARM template located at <a href="{{site.baseurl}}/2019-11-02/NestedTemplates/storage.json">{{site.baseurl}}/2019-11-02/NestedTemplates/storage.json</a>

```powershell
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force | Out-Null
$storageAccountDeployment = New-AzResourceGroupDeployment `
    -TemplateUri "http://kingofarm.com/2019-11-02/NestedTemplates/storage.json" `
    -Name storage-deployment `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -TemplateParameterObject @{ `
        storageAccountName = $storageAccountName; `
        containerName      = $containerName
}
```

#### Copy all nested template files

Arrange all your nested templates into a single folder and copy each file to the blob storage container recursively. Use `New-AzStorageContext` to create a context connected to the storage accoutn required for the copy function `Set-AzStorageBlobContent`.

```powershell
...

$ctx = New-AzStorageContext `
    -StorageAccountName $storageAccountName `
    -StorageAccountKey $storageKeys.keys[0].value

...

Get-ChildItem -File -Recurse $linkedfilesLocalPath | ForEach-Object {
    Set-AzStorageBlobContent `
        -File $_.FullName `
        -Blob $_.FullName.Substring($linkedfilesLocalPath.Length + 1) `
        -Container $containerName `
        -Context $ctx `
        -Force | Out-Null
}
```

[Download the full script]({{site.baseurl}}/2019-11-02/copy-to-storage.ps1)

## Step 2: Use the linked templates in your storage account

Introduce 2 parameters in the _parent_ template; `TemplateURL` and `TemplateToken` which will hold the values to access the linked template.

Before doing the deployment of the parent template, fetch the storage account using PowerShell and the value of `TemplateURL` and `TemplateToken` and use those in the ARM template deployment.

### Parameters in the _parent_ template

```json
"parameters": {
    "TemplateURL": {
        "type": "string"
    },
    "TemplateToken": {
        "type": "string"
    }
}
```

Use these in all the linked templates resousrces. Here you can see one example

```json
"resources": [
 {
      "type": "Microsoft.Resources/deployments",
      "apiVersion": "2018-05-01",
      "name": "linkedTemplate",
      "properties": {
          "mode": "Incremental",
          "templateLink": {
              "uri": "[concat(parameters('TemplateURL'), '/NestedTemplates/storage.json', parameters('TemplateToken'))]",
              "contentVersion": "1.0.0.0"
          },
          "parameters": {
              "StorageAccountName": {
                  "value": "[parameters('StorageAccountName')]"
              }
          }
      }
  }
]
```

[Download the full ARM template]({{site.baseurl}}/2019-11-02/parent-arm.json)

### Script for fetching the SAS token

Creating a new SAS token for the storage accoutn and container is an easy operation using `New-AzStorageContainerSASToken`. SAS tokens are not stored in Azure in any way, they are generated on request signed by keys for the storage account. Read more about
<a href="https://docs.microsoft.com/en-us/rest/api/storageservices/create-account-sas" target="_blank">SAS tokens on Microsoft Azure</a>.

```powershell
$sasToken = New-AzStorageContainerSASToken `
    -Container $ContainerName `
    -StartTime $StartTime `
    -ExpiryTime $EndTime `
    -Permission $ReadPermission `
    -Context $storageAccount.Context
```

[Download the full script]({{site.baseurl}}/2019-11-02/get-sas-token.ps1)

### Gluing it all together in an ARM template deployment

Now we have a PowerShell script _publishing_ the linked templates into a Azure Storage Account and another script for fetching the SAS token for that same storage account. We also have a _parent_ ARM template that is using the linked templates feature for <a href="https://en.wikipedia.org/wiki/Separation_of_concerns">_separation of concerns_</a>.

```powershell
param (
    [Parameter(Mandatory = $true)]
    $NewStorageAccountName,
    [Parameter(Mandatory = $true)]
    $NewResourceGroup,
    $Location = "west europe"
)

#Change NestedTemplatesStorageAccountName to something globally unique for you
$NestedTemplatesStorageAccountName = "kingofarmdeployment"
. "./copy-to-storage.ps1" -StorageAccountName $NestedTemplatesStorageAccountName
$linkedTemplatesStorage = . "./get-sas-token.ps1" -StorageAccountName $NestedTemplatesStorageAccountName

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
```

[Download the full script]({{site.baseurl}}/2019-11-02/deploy-parent-arm.ps1)

>Note: We are using PowerShell dotsourcing to execute the scripts. You probably want to wrap these into PowerShell modules to get a better packaging of your code

>Note 2: You might not want to publish your nested templates folder on each deployment (unless running locally during development). This may be part of you build pipeline instead and treat your published storage container as a build artifact.

### Troubleshoot

If you get error in `New-AzResourceGroupDeployment` then add the Debug switch to the command and you will get usefull debug information in the console.
