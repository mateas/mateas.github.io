---
layout: post
title:  "ARM template defaults"
date:   2019-10-27
tags: [ARM, ARM-template]
---
Working with the `deafultValue` on ARM parameters is good when you want the template to become a bit more flexible and easy to use. A pattern tha I have found usefull is to use a combination of parameter defaults and _variables_ to write the most flexible and powerfull ARM templates.

An example is when you want to refer to another resource in your template, such as a Log Anayltics instance, and you want to support both the full ResourceID as a single parameter or a combination of three paramters which in combination tagets the correct instance. 

The steps in this example will target the `Microsoft.OperationalInsights/workspaces` resource but the same pattern works for any other Azure resource.

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