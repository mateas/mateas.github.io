---
layout: post
title:  "Deploy to multiple resource groups in one ARM template"
date:   2019-11-24 
categories: ARM
---

# Deploy to multiple resource groups within the same ARM template

Sometimes it is necessary to deploy resources to more than one single resource groups within the same arm and deployment. One example is when you have a virtual network (VNET) in one resource group and you want to deploy resources in a new resource group and in the same time deploy a subnet to the existing VNET. 

## Problem
Deploy to multiple resource groups within the same ARM template.


## Solution
Use the [_NestedTemplates_](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-linked-templates#nested-template) feature and the `resourceGroup` property to steer the deploymetn to another resource group. 

### Example
```json
"resources": [
  {
    "type": "Microsoft.Resources/deployments",
    "apiVersion": "2019-05-01",
    "name": "nestedTemplate",
    "resourceGroup": "[parameters('storageResourceGroup')",
    "properties": {
      "mode": "Incremental",
      "template": {
        "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "resources": [
          {
            "type": "Microsoft.Storage/storageAccounts",
            "apiVersion": "2019-04-01",
            "name": "[parameters('storageName')]",
            "location": "West US",
            "kind": "StorageV2",
            "sku": {
                "name": "Standard_LRS"
            }
          }
        ]
      }
    }
  }
]

```
<!---
[Full example ARM template](/link-to-raw-arm)
-->