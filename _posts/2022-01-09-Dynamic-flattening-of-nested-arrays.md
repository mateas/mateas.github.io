---
layout: post
title: "Dynamic flattening of nested arrays"
date: 2022-01-09
tags: [ARM, ARM-template]
---

When working with nested arrays, sometimes you want to creata a flattened array.

This is what an input array could look like:

```json
{
  "parameters": {
    "myNestedArrayParam": {
      "type": "array",
      "defaultValue": [
        {
          "thisIsAInnerArrayProp": [
            {
              "abc": "this is the 1st abc in the 1st array object"
            }
          ]
        },
        {
          "thisIsAInnerArrayProp": [
            {
              "abc": "this is the 1st abc in the 2nd array object"
            },
            {
              "abc": "this is the 2nd abc in the 2nd array object"
            }
          ]
        }
      ]
    }
  }
}
```

This is the expexted result:

```json
[
  {
    "abc": "this is the 1st abc in the 1st array object"
  },
  {
    "abc": "this is the 1st abc in the 2nd array object"
  },
  {
    "abc": "this is the 2nd abc in the 2nd array object"
  }
]
```

## Solution

Use a resource copy function of a deployment resource and build the result array using the output variable. Reference the previous output variable as an input parameter.

**Like this:**

```json
{
  "type": "Microsoft.Resources/deployments",
  "apiVersion": "2021-04-01",
  "name": "[concat('nestedTemplate', copyIndex())]",
  "location": "westeurope",
  "properties": {
    "mode": "Incremental",
    "expressionEvaluationOptions": {
      "scope": "inner"
    },
    "parameters": {
      "currentArray": {
        "value": "[if(equals(copyIndex(),0), createArray(), reference(concat('nestedTemplate', sub(copyIndex(), 1))).outputs.result.value)]"
      },
      "arrayToAppend": {
        "value": "[parameters('myNestedArrayParam')[copyIndex()].thisIsAInnerArrayProp]"
      }
    },
    "template": {
      "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
      "contentVersion": "1.0.0.0",
      "parameters": {
        "currentArray": {
          "type": "array"
        },
        "arrayToAppend": {
          "type": "array"
        }
      },
      "resources": [],
      "outputs": {
        "result": {
          "type": "array",
          "value": "[union(parameters('currentArray'), parameters('arrayToAppend'))]"
        }
      }
    }
  },
  "copy": {
    "name": "iterator",
    "count": "[length(parameters('myNestedArrayParam'))]",
    "mode": "serial"
  }
}
```

**Try out the full example:**

```PowerShell
New-AzDeployment -TemplateUri "https://www.kingofarm.com/2022-01-09/flattening-nested-array-example.json" `
  -Location "westeurope"
```
