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

Try out the example:

```PowerShell
New-AzDeployment -TemplateUri "http://kingofarm.com/2022-01-09/flattening-nested-array-example.json" `
  -Location "westeurope"
```
