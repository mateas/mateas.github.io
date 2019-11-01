---
layout: post
title: "Nested template as a transform function"
date: 2019-11-24
tags: [ARM, ARM-template]

---

When working with complex ARM templates it is something desirable to separate some of the logic from the primary template.

Example:
```PowerShell
New-AzDeployment -TemplateUri "http://kingofarm.com/2019-11-28-Use-NestedTemplates-as-a-Transform-Function/collection-creator-example.json " `
  -Location "west europe" `
  -TemplateParameterObject @{collection=@(@{param = "collectionParam1"})}
```