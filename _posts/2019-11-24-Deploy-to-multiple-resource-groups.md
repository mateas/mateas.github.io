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
Use the ARM templates [_NestedTemplates_](http://link-to-the-docs) feature to steer the deploymetn to another resource group. 

### Example

<!---```json


```

[Full example ARM template](/link-to-raw-arm)
-->