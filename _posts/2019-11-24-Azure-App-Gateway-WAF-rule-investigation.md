---
layout: post
title: "Investigate blocked requests in Application Gateway WAF"
date: 2019-11-24
tags: [Azure, WAFv2, Application Gateway]
---

Azure Application Gateway (AppGw) logs all _blocked_ requests to Log Analytics (make sure you have enabled monitoring and connected your Application Gateway instance to Log Analytics) when you have the AppGw in _Prevention_ Firewall mode. 
>Note: Firewall _Prevention_ mode not only detects and logs traffic according to selected rule set (OWASP 3.0, 3.1 or ), but also blocks the traffic. If _Detection_ mode is selected, no traffic is blocked and below queries won´t giva any result.

Logs are available in Log Analytics `AzureDiagnostics` namespace and category `ApplicationGatewayFirewallLog`. 

To see all blocked requests, use this query:

```bash
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.NETWORK" and Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
```

To get an overview of what rules are the most common ones, use this query that groups on _Uri_ and _Rulename_:

```bash
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.NETWORK" and Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| extend fullUri_s = strcat(hostname_s, requestUri_s)
| summarize count() by FullUri_s, details_file_s
```

For a better understanding of each rule (in parameter _details_file_s_ in above query), see <a href="https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-crs-rulegroups-rules?tabs=owasp3" target="_blank">Web application firewall CRS rule groups and rules on Microsoft Azure</a>


