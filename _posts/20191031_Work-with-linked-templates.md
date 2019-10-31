---
layout: post
title:  "Work with linked templates"
date:   2019-10-31
tags: [ARM, ARM-template]
---
Linked templates is the ARM template feature that allows you to separate different resource deployments into simple and easy to use templates. A common pattern is to separate all individual resources into separate templates and then having one or multiple "parent" templates referenceing those individual ones. This is what Microsoft calls [_linked templates_](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-linked-templates#external-template).


The only issue with linked templates is that the template tha is being linked must be availbale on the Internet and cannot be supplied at deploytime together with the _parent_ template. 

## Make your templates available in private storage account
A simple solution to this is to copy you linked templates into a Azure storage account container with no public access. When you are to deploy your master template, create a SAS token for the container and supply that to your master template as a ARM parameter. 

# Copy script for your linked templates


### Step 1
Use the `defaultValue` of the `ResourceID` parameter to _create_ the full ResourceId based on the other parameters `SubsriptonId`, `ResourecGroup` and `WorkspaceName`. 

```json
  "parameters": {
    "SubscriptionId": {
      "type": "string",
      "defaultValue": "[split(resourceGroup().id,'/')[2]]"
    },
    "ResourceGroup": {
      "type": "string",
      "defaultValue": "[resourceGroup().name]"
    },
    "WorkspaceName": {
      "type": "string",
      "defaultValue": ""
    },
    "ResourceID": {
      "type": "string",
      "defaultValue": "[resourceId(parameters('SubscriptionId'), parameters('ResourceGroup'), 'Microsoft.OperationalInsights/workspaces', parameters('WorkspaceName'))]"
    },
  }
```

### Step 2
To be able to use values of `SubsriptonId`, `ResourecGroup` and `WorkspaceName`, don´t use the parameters . Instead, create variables that calculates their values based on the `ResourceId` parameter.

```json
  "variables": {
      "SubscriptionId": "[split(parameters('ResourceID'),'/')[2]]",
      "ResourceGroup": "[split(parameters('ResourceID'),'/')[4]]",
      "WorkspaceName": "[split(parameters('ResourceID'),'/')[8]]"
  },
```

### Step 3
Now you can refer to any value of `SubsriptonId`, `ResourecGroup`, `WorkspaceName` or `ResourceÍD`in your template not worrying if the value has been set or not.


```json
"resources": [
        {
            "type": "Microsoft.Resources/deployments",
            "name": "nestedResourceDeploymentName",
            "apiVersion": "2017-05-10",
            "subscriptionId": "[variables('SubscriptionId')]",
            "resourceGroup": "[variables('ResourceGroup')]",
            "properties": {
                "mode": "Incremental",
                "template": {
                    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                    "contentVersion": "1.0.0.0",
                    "parameters": {},
                    "variables": {},
                    "resources": [
                        {
                            "apiVersion": "2015-11-01-preview",
                            "type": "Microsoft.OperationsManagement/solutions",
                            ...
                            "properties": {
                                "workspaceResourceId": "[parameters('ResourceID')]"
                            }
                        }
                    ]
                }
            }
        }
    ]
```

### ARM template usage

When using this pattern, any of these alternatives may be used as input:
* only use `ResourceID` parameter (this is the primary option and will override any usage of the other parameters)
* only use `WorkspaceName` parameter (when instance is located in the same subscription and resource group)
* use both `WorkspaceName` and `ResourecGroup` parameters (when instance is located in the same subscription but a different resource group)
* use all three parameters `SubsriptonId`, `ResourecGroup` and `WorkspaceName`