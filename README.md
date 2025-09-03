# 🛡️ Microsoft Sentinel Complete Infrastructure Deployment 🛡️

This repository provides a comprehensive deployment solution for Microsoft Sentinel infrastructure, combining core Sentinel deployment with advanced Microsoft Defender Vulnerability Management (MDVM) data integration.

## 📋 Overview

This solution consists of two main deployment components that work together to provide a complete Microsoft Sentinel security monitoring platform:

1. **Core Sentinel Infrastructure (sentinel-deploy-ui)** - Deploys the fundamental Sentinel components
2. **MDVM Data Connector (sentinel-deploy-mdvm)** - Adds vulnerability management capabilities

## 🏗️ Architecture

```
Azure Subscription
├── Core Infrastructure (sentinel-deploy-ui)
│   ├── Resource Group
│   ├── Log Analytics Workspace
│   ├── Microsoft Sentinel
│   ├── Data Connectors (Optional)
│   │   ├── Azure Active Directory
│   │   ├── Office 365
│   │   ├── Microsoft Defender for Cloud
│   │   ├── Microsoft 365 Defender
│   │   └── [Additional Connectors]
│   └── UEBA Settings
│
└── MDVM Infrastructure (sentinel-deploy-mdvm)
    ├── Function App (with Managed Identity)
    ├── Application Insights
    ├── Storage Account
    ├── Data Collection Endpoint
    ├── Data Collection Rules
    ├── Custom Tables
    │   ├── MDVMCVEKB_CL
    │   ├── MDVMNISTCVEKB_CL
    │   ├── MDVMNISTConfigurations_CL
    │   ├── MDVMRecommendations_CL
    │   ├── MDVMSecureConfigurationsByDevice_CL
    │   └── MDVMVulnerabilitiesByDevice_CL
    └── Sentinel Workbook
```

## 🚀 Quick Deployment

### Option 1: Deploy Everything (Recommended)
Deploy both components in the correct order:

1. **First, deploy the core Sentinel infrastructure:**
   
   [![Deploy Core Sentinel](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FJ-HEARD%2Fsentinel-deploy-ui%2Fmain%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FJ-HEARD%2Fsentinel-deploy-ui%2Fmain%2FcreateUiDefinition.json)

2. **Then, deploy the MDVM data connector:**
   
   [![Deploy MDVM Connector](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FJ-HEARD%2Fsentinel-deploy-mdvm%2Fmaster%2FazureDeploy.json)

### Option 2: Deploy Only Core Sentinel
If you only need the base Sentinel infrastructure without MDVM capabilities, deploy just the first component.

## 📦 What Gets Deployed

### Core Sentinel Infrastructure (sentinel-deploy-ui)
- **Resource Group**: Container for all Sentinel resources
- **Log Analytics Workspace**: Central data repository with configurable retention
- **Microsoft Sentinel**: SIEM and SOAR capabilities
- **Data Connectors**: Integration with Microsoft security services
- **UEBA**: User and Entity Behavior Analytics

### MDVM Data Connector (sentinel-deploy-mdvm)
- **Function App**: Automated data collection from M365 Defender API
- **Custom Tables**: Vulnerability and configuration assessment data
- **Data Collection Infrastructure**: DCE and DCR for secure data ingestion
- **Sentinel Workbook**: Visualization of vulnerability data
- **Managed Identity**: Secure authentication to M365 Defender

## 🔧 Prerequisites

### General Requirements
- Azure Subscription with appropriate permissions
- Owner permissions on target resource group
- Log Analytics Contributor permissions on the workspace

### For MDVM Deployment
- Global Admin or Application Administrator in the M365 Defender tenant
- Existing Log Analytics workspace (created by sentinel-deploy-ui)

## 📊 Data Flow

```
Microsoft 365 Defender API
         │
         ▼
    Function App (Daily)
         │
         ├─── Vulnerability Data
         ├─── CVE Knowledge Base
         ├─── NIST CVE Data
         └─── Recommendations
                │
                ▼
        Data Collection Rules
                │
                ▼
      Log Analytics Workspace
                │
                ▼
         Microsoft Sentinel
                │
                ├─── Analytics Rules
                ├─── Workbooks
                └─── Hunting Queries
```

## 🔐 Security Features

- **Managed Identity**: Passwordless authentication for Function App
- **Private Endpoints**: Optional network isolation
- **RBAC**: Role-based access control throughout
- **Data Encryption**: At-rest and in-transit encryption
- **Compliance**: Supports various compliance standards

## 📈 Monitoring and Alerting

The solution provides:
- Real-time vulnerability tracking
- Security configuration assessment
- CVE correlation with NIST database
- Custom alerting based on vulnerability severity
- Comprehensive dashboards and workbooks

## 🛠️ Customization Options

### Core Sentinel
- Workspace retention period (7-730 days)
- Pricing tier selection
- Data connector configuration
- UEBA enablement

### MDVM Connector
- Function App schedule
- Private networking options
- Custom table schemas
- Workbook customization

## 📚 Additional Resources

- [Microsoft Sentinel Documentation](https://docs.microsoft.com/azure/sentinel/)
- [Microsoft Defender Vulnerability Management](https://docs.microsoft.com/microsoft-365/security/defender-vulnerability-management/)
- [Log Analytics Workspace Design](https://docs.microsoft.com/azure/azure-monitor/logs/workspace-design)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests to improve this deployment solution.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Credits

- Core Sentinel deployment design by J-HEARD
- MDVM connector originally developed by Alex Anders
- Community contributions and feedback

---

For detailed deployment instructions, see the [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)
