---
layout: post
title: "Nested template as a transform function"
date: 2019-12-01
tags: [ARM, ARM-template]
---

When working with complex ARM templates it is something desirable to separate some of the logic from the primary template. In this example we run a linked template as a "collection creator" including all the transformation logic. The output can later be used in the outer template.

The property copy function is used to create the object transform for each object in the array:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "collection": {
      "type": "array"
    }
  },
  "variables": {
    "result": {
      "copy": [
        {
          "name": "createdValue",
          "count": "[length(parameters('collection'))]",
          "input": {
            "name": "[concat('name', copyIndex('createdValue'))]",
            "valueFromCollection": "[parameters('collection')[copyIndex('createdValue')].param]"
          }
        }
      ]
    }
  },
  "outputs": {
    "Result": {
      "value": "[variables('result').createdValue]",
      "type": "array"
    }
  }
}
```

This will create the variable `createdValue` which is reference as the output value `Result`.

**Run the example:**

```PowerShell
New-AzDeployment -TemplateUri "https://www.kingofarm.com/2019-11-28-Use-NestedTemplates-as-a-Transform-Function/collection-creator-example.json" `
  -Location "westeurope" `
  -TemplateParameterObject @{collection=@(@{param = "collectionParam1"})}
```
