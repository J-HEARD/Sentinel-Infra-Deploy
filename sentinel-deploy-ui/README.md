# 🛡️ Sentinel Deployment 🛡️

This repository contains ARM templates for deploying the core infrastructure components of Microsoft Sentinel.

## What This Deploys

This deployment focuses on the essential foundation for Microsoft Sentinel:

1. **Resource Group** - Creates a new resource group for all Sentinel resources
2. **Log Analytics Workspace** - Sets up the workspace with configurable retention and pricing
3. **Microsoft Sentinel** - Enables Sentinel on the workspace
4. **Data Connectors** - Configures selected data connectors (optional)
5. **UEBA Settings** - Configures User Entity Behavior Analytics (optional)

## Available Data Connectors

The following data connectors can be enabled during deployment:
- Azure Active Directory (includes Identity Protection alerts, with configurable log types)
- Office 365 (Exchange, SharePoint, Teams)
- Microsoft Defender for Cloud
- Microsoft 365 Defender
- Dynamics 365
- Microsoft Defender for IoT
- Office 365 Project
- Office IRM
- Power BI
- Threat Intelligence

## Deployment Options

### Deploy via Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FJ-HEARD%2FSentinel-Infra-Deploy%2Fmain%2Fsentinel-deploy-ui%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FJ-HEARD%2FSentinel-Infra-Deploy%2Fmain%2Fsentinel-deploy-ui%2FcreateUiDefinition.json)

### Deploy via Azure CLI

```bash
az deployment sub create \
  --location <location> \
  --template-uri https://raw.githubusercontent.com/J-HEARD/Sentinel-Infra-Deploy/main/sentinel-deploy-ui/azuredeploy.json \
  --parameters rgName=<resourceGroupName> workspaceName=<workspaceName>
```

### Deploy via PowerShell

```powershell
New-AzSubscriptionDeployment `
  -Location <location> `
  -TemplateUri "https://raw.githubusercontent.com/J-HEARD/Sentinel-Infra-Deploy/main/sentinel-deploy-ui/azuredeploy.json" `
  -rgName <resourceGroupName> `
  -workspaceName <workspaceName>
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| rgName | Resource group name | CISO-RG-SENTINEL |
| workspaceName | Log Analytics workspace name | CISO-WS-SENTINEL |
| location | Azure region for deployment | Deployment location |
| pricingTier | Workspace pricing tier | PerGB2018 |
| capacityReservation | Daily commitment (GB) for CapacityReservation tier | 100 |
| dailyQuota | Daily ingestion limit in GB (0 = unlimited) | 0 |
| dataRetention | Data retention in days (7-730) | 90 |
| enableUeba | Enable User Entity Behavior Analytics | true |
| enableDataConnectors | Array of data connectors to enable | [] |
| aadStreams | Azure AD log types to collect | [] |

## Architecture

```
Subscription
└── Resource Group (rgName)
    └── Log Analytics Workspace (workspaceName)
        ├── Microsoft Sentinel (enabled)
        ├── UEBA (optional)
        └── Data Connectors (optional)
```
