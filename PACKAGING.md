# ISV Packaging Guide - Agentforce Opportunity Manager

## Overview

This package demonstrates the ISV pattern for distributing Agentforce Agent Script agents when `AiAuthoringBundle` is not yet fully supported in managed packages.

## Package Contents

### ✅ Packaged (Managed/Protected)
- **Apex Classes**: 
  - `FGBTNS01__GetOpportunityFieldsAction` - Retrieves field metadata from Field Sets
  - `FGBTNS01__CreateCustomObjectAction` - Creates Opportunity records
  - Test classes with 100% coverage

- **Custom Metadata Types**:
  - `FGBTNS01__Agentforce_Opp_Config__mdt` - Multi-team configuration
  - Default configuration record included

- **Field Sets**:
  - `Opportunity.FGBTNS01__Agentforce_Create_Fields` - Default fields

- **Lightning Web Component**:
  - `agentScriptSetup` - Post-install setup page with Agent Script

- **Custom Tab & FlexiPage**:
  - "Agentforce Setup" tab for easy access

### 📄 Documented (Not Packaged)
- **Agent Script**: Embedded as text in LWC for customer to copy/paste

## Installation Flow

### For ISV (You)

1. **Link namespace to Dev Hub**:
   ```bash
   sf org create scratch -f config/project-scratch-def.json -a scratch-org --set-default
   ```

2. **Create managed package**:
   ```bash
   sf package create \
     --name "Agentforce Opportunity Manager" \
     --package-type Managed \
     --path force-app
   ```

3. **Create package version**:
   ```bash
   sf package version create \
     --package "Agentforce Opportunity Manager" \
     --installation-key-bypass \
     --wait 20
   ```

4. **Promote to released**:
   ```bash
   sf package version promote --package 04t...
   ```

### For Customer (Post-Install)

1. **Install package** from AppExchange or install URL

2. **Navigate to Setup Tab**:
   - Go to **App Launcher** → **Agentforce Setup**
   - Or go to **Setup** → **Custom Code** → **Lightning Components** → Select the `agentScriptSetup` component

3. **Copy Agent Script**:
   - Click **"Copy Agent Script"** button
   - Agent Script is now in clipboard

4. **Create Agent in Agent Builder**:
   - Go to **Setup** → **Agent Builder**
   - Click **New Agent**
   - Choose **Employee Agent**
   - Name: "Opportunity Manager"
   - Click **Code** tab
   - Paste the Agent Script
   - Click **Save**

5. **Publish & Activate**:
   - Click **Publish** (creates version 1)
   - Click **Activate**
   - Agent is now live!

## How It Works

### The Agent Script References Packaged Apex

Note the `target:` lines in the Agent Script (embedded in LWC):

```yaml
target: "apex://FGBTNS01__GetOpportunityFieldsAction"
target: "apex://FGBTNS01__CreateCustomObjectAction"
```

The namespace prefix `FGBTNS01__` ensures the agent connects to YOUR managed Apex actions, not any local classes the customer might have.

### Benefits of This Approach

✅ **Commercial Distribution**: Apex is protected in managed package  
✅ **Agent Script Benefits**: Customers get deterministic, version-controlled agent logic  
✅ **Easy Setup**: Copy/paste setup in < 5 minutes  
✅ **Customizable**: Customers can modify Agent Script post-install  
✅ **Multi-Team Support**: Customers can extend with additional configurations  

## Customization for Customers

After setup, customers can:

1. **Add/Remove Fields**:
   - Edit Field Set: `Opportunity.FGBTNS01__Agentforce_Create_Fields`

2. **Create Team-Specific Configs**:
   - Create new `FGBTNS01__Agentforce_Opp_Config__mdt` records
   - Point to different Field Sets
   - Modify Agent Script to use different config names

3. **Modify Agent Behavior**:
   - Edit the `.agent` file in Agent Builder Code tab
   - Republish to update

## Architecture Pattern

```
┌─────────────────────────────────────────┐
│   Managed Package (Protected)           │
│  ┌────────────────────────────────────┐ │
│  │ Apex: GetOpportunityFieldsAction   │ │
│  │ Apex: CreateCustomObjectAction     │ │
│  │ Custom Metadata: Config__mdt       │ │
│  │ Field Sets                         │ │
│  └────────────────────────────────────┘ │
│  ┌────────────────────────────────────┐ │
│  │ LWC: agentScriptSetup              │ │
│  │   (contains Agent Script as text)  │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
              ↓ (customer copies)
┌─────────────────────────────────────────┐
│   Customer's Org (Customizable)         │
│  ┌────────────────────────────────────┐ │
│  │ Agent Builder                      │ │
│  │   → Paste Agent Script             │ │
│  │   → Publish                        │ │
│  │   → Activate                       │ │
│  └────────────────────────────────────┘ │
│              ↓ (connects to)            │
│  ┌────────────────────────────────────┐ │
│  │ Managed Apex Actions               │ │
│  │   FGBTNS01__GetOpportunityFields   │ │
│  │   FGBTNS01__CreateCustomObject     │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Why This Pattern?

**Current State** (as of Winter '26):  
- `AiAuthoringBundle` metadata type exists
- Can be deployed/retrieved
- ❌ Not supported in managed packages (yet)

**This Workaround**:  
- ✅ Protects your Apex IP (managed package)
- ✅ Distributes Agent Script as documentation
- ✅ Customer gets full Agent Script benefits
- ✅ ISV-ready for AppExchange today

**Future State** (when available):  
- Package `AiAuthoringBundle` directly
- Customer installs = agent already configured
- No manual setup required

## License

MIT - See LICENSE file
