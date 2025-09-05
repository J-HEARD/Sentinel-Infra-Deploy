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

# Sentinel Deploy UI

This project provides a streamlined deployment for Azure Sentinel (Microsoft Sentinel) and its Log Analytics workspace.

## Default Configuration

By default, the deployment provisions:

- **Pricing tier**: `PerGB2018` (Pay-as-you-go)
- **Daily quota**: `1 GB/day`
- **Data retention**: `730 days`
- **Immediate purge**: Off
- **UEBA**: Enabled
- **Data connectors enabled**:
  - Azure Active Directory
  - Office 365
  - Microsoft Defender for Cloud
  - Microsoft 365 Defender
  - Dynamics 365
  - IoT
  - Office365 Project
  - OfficeIRM
  - PowerBI
  - Threat Intelligence
- **AAD streams enabled**:
  - AuditLogs
  - SignInLogs
  - RiskyUsers
  - ServicePrincipalSignInLogs
  - NonInteractiveUserSignInLogs
- **Location**: `australiaeast`

## Deployment

### CLI (Subscription-level)

```bash
# Deploy using default parameters
az deployment sub create \
  --name SentinelDeploy \
  --location australiaeast \
  --template-file ./sentinel-deploy-ui/main.infra.bicep \
  --parameters @./sentinel-deploy-ui/main.infra.parameters.json
```

### Custom Parameters

You can override defaults inline. Example:

```bash
az deployment sub create \
  --name SentinelDeployCustom \
  --location australiaeast \
  --template-file ./sentinel-deploy-ui/main.infra.bicep \
  --parameters pricingTier=Free dataRetention=90 dailyQuota=5 enableUEBA=false
```

### Portal Button (basic)
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FJ-HEARD%2FSentinel-Infra-Deploy%2Fmaster%2Fsentinel-deploy-ui%2Fazuredeploy.json)

### Deploy via Azure CLI

```bash
az deployment sub create \
  --location <location> \
  --template-uri https://raw.githubusercontent.com/J-HEARD/Sentinel-Infra-Deploy/master/sentinel-deploy-ui/azuredeploy.json \
  --parameters rgName=<resourceGroupName> workspaceName=<workspaceName>
```

### Deploy via PowerShell

```powershell
New-AzSubscriptionDeployment `
  -Location <location> `
  -TemplateUri "https://raw.githubusercontent.com/J-HEARD/Sentinel-Infra-Deploy/master/sentinel-deploy-ui/azuredeploy.json" `
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
