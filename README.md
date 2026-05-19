# Agentforce Opportunity Manager - ISV Package

**Namespace:** `d26`  
**Type:** Managed Package (2GP)

Hybrid Custom Metadata + Field Set solution for Agentforce that enables intelligent Opportunity creation with flexible, multi-team configurations.

## Overview

This ISV solution provides two Agentforce actions with support for multiple named configurations:
1. **Get Opportunity Fields** - Returns available fields with metadata
2. **Create Opportunity** - Creates Opportunities with validated fields

Each configuration references a Field Set, allowing customers to define different field sets for different teams (e.g., Sales Team, Partner Team).

## Architecture: Hybrid Approach (Option 3)

**Custom Metadata Type** (`Agentforce_Opp_Config__mdt`) stores named configurations:
- `Label`: User-friendly name (e.g., "Sales Team", "Partner Team")
- `Field_Set_Name__c`: References an Opportunity Field Set
- `Description__c`: Configuration purpose

**Field Sets** define the actual fields declaratively.

**Benefits:**
- ✅ Multiple named configurations for different teams
- ✅ Field Sets remain declarative and user-friendly
- ✅ Agent specifies which configuration to use
- ✅ ISV packageable with customer customization

## Files Included

### Apex Actions (Packaged)
- `d26__GetOpportunityFieldsAction` - Invocable action that returns field metadata
- `d26__CreateCustomObjectAction` - Invocable action that creates Opportunities
- Test classes with 100% coverage

### Custom Metadata Type (Packaged)
- `Agentforce_Opp_Config__mdt` - Configuration object
- `Agentforce_Opp_Config.Default` - Default configuration record

### Field Set (Packaged)
- `Opportunity.d26__Agentforce_Create_Fields` - Default field set

### Setup Page (Packaged)
- `Opportunity Agent Setup` custom tab with setup instructions

### GenAiFunction Metadata (Packaged)
- `Create_Opportunity` - GenAiFunction wrapping CreateCustomObjectAction
- `Get_Opportunity_Fields` - GenAiFunction wrapping GetOpportunityFieldsAction
- Input/output schemas for both actions using Lightning standard types

**Note**: GenAiFunction metadata IS packageable in 2GP (Winter '25+). The package includes both the Apex actions and their GenAiFunction wrappers with complete input/output schema definitions.

## Usage

### 1. Get Available Fields

```json
Input: {
  "configurationName": "Default"
}

Output: {
  "fieldsJson": "[{\"apiName\":\"Name\",\"label\":\"Opportunity Name\",\"fieldType\":\"STRING\",\"isRequired\":true,...}]",
  "isSuccess": true
}
```

### 2. Create Opportunity

```json
Input: {
  "configurationName": "Default",
  "fieldValuesJson": "{\"Name\":\"Enterprise Deal\",\"StageName\":\"Qualification\",\"CloseDate\":\"2026-12-31\"}"
}

Output: {
  "recordId": "006...",
  "isSuccess": true
}
```

## Setup Instructions

### Step 1: Install the Package

Install via the subscriber package version ID:
```bash
sf package install --package 04tao000005cau1AAA --wait 20
```

### Step 2: Access Setup Page

Navigate to the **Opportunity Agent Setup** tab for guided setup instructions.

### Step 3: Create Agent in Agent Builder

1. Go to **Setup → Agent Builder**
2. Click **New Agent** → Choose **Employee Agent**
3. Name it **"Opportunity Manager"**
4. In **Topics & Actions**, search for **"d26__GetOpportunityFieldsAction"** and **"d26__CreateCustomObjectAction"**
5. Add both actions to your agent
6. Configure the agent's instructions to:
   - First call `d26__GetOpportunityFieldsAction` to retrieve available fields
   - Collect values from the user based on returned field metadata
   - Call `d26__CreateCustomObjectAction` with the collected values
7. **Publish** and **Activate** the agent

### Step 4 (Optional): Customize Fields

1. Go to **Setup → Object Manager → Opportunity → Field Sets**
2. Edit **d26__Agentforce_Create_Fields** to add/remove fields
3. Create additional Custom Metadata records for team-specific configurations:
   - **Setup → Custom Metadata Types → Agentforce Opportunity Configuration**
   - Click **Manage Records** → **New**
   - Link to different Field Sets for different teams

**Example Multi-Team Setup:**
- **Sales_Team** → References `Sales_Opportunity_Fields` Field Set
- **Partner_Team** → References `Partner_Opportunity_Fields` Field Set
- **Default** → References `d26__Agentforce_Create_Fields` Field Set

## For ISV Partners

### Package Structure

This is a 2GP managed package with namespace `d26`. The package includes:
- Apex invocable actions (automatically discoverable by Agent Builder)
- Custom Metadata Type for configuration
- Field Sets for dynamic field definition
- Setup page with copy/paste Agent Script example

### GenAiFunction Packaging (Winter '25+)

GenAiFunction metadata IS packageable in 2GP as of Winter '25. This package includes:
1. GenAiFunction definitions for both actions
2. Input/output schemas using Lightning standard types (lightning__textType, etc.)
3. Complete metadata structure for Agent Builder discovery

Schema files are placed inside GenAiFunction directories:
```
genAiFunctions/
├── Create_Opportunity/
│   ├── Create_Opportunity.genAiFunction-meta.xml
│   ├── input/schema.json
│   └── output/schema.json
└── Get_Opportunity_Fields/
    ├── Get_Opportunity_Fields.genAiFunction-meta.xml
    ├── input/schema.json
    └── output/schema.json
```

When subscribers install the package, the GenAiFunctions are immediately available in Agent Builder for adding to agents.

## Features

- ✅ **Multi-team support** - Different configurations for different teams
- ✅ **Hybrid architecture** - CMT + Field Sets
- ✅ **ISV-ready** - Packageable and customer-configurable
- ✅ **Dynamic discovery** - Agent adapts to configuration
- ✅ **Field-level security** - Respects user permissions (`with sharing`)
- ✅ **Type conversion** - Handles all Salesforce field types
- ✅ **Picklist discovery** - Returns valid values
- ✅ **100% test coverage**

## Agent Instructions

```
When creating an opportunity, first call "Get Opportunity Fields" with the 
appropriate configuration name (e.g., "Sales_Team" or "Default"). Use the 
returned field metadata to ask the user for values, then call "Create Opportunity" 
with the same configuration name.
```

## Agent Script Implementations

### Local Version (Demo)
**File:** `force-app/main/default/lwc/agentScriptSetup/agentScriptsData.js` → `LOCAL_MANAGE_OPPORTUNITIES_AGENT`

Fully functional Agent Script using local Apex actions. Copy-paste ready for quick demos.

**Actions:**
- `GetOpportunityFieldsActionLocal`
- `CreateCustomObjectActionLocal`

**Status:** ✅ Works perfectly

### Packaged Version (Work in Progress)
**File:** `force-app/main/default/lwc/agentScriptSetup/agentScriptsData.js` → `MANAGE_OPPORTUNITIES_AGENT`

Agent Script targeting managed package actions with `d26__` namespace prefix.

**Actions:**
- `d26__GetOpportunityFieldsAction`
- `d26__CreateCustomObjectAction`

**Status:** ⚠️ Work in progress

**Current Error:**
```
Action name not found: d26__GetOpportunityFieldsAction
```

**Root Cause:** The packaged agent references Apex actions with the `d26__` namespace prefix (managed package convention), but the managed package is not installed in the target org. The org only has local, non-namespaced versions of these actions.

**Attempts Made:**
1. Added `recordLink` and `recordName` outputs to packaged Apex action to match local version
2. Removed `source` attribute from action definitions (only needed for Flow actions, not direct Apex references)
3. Synced packaged Apex implementation with local version (Account resolution, validation logic)
4. Attempted removing `d26__` prefix to point to local actions (reverted per user request)

**Resolution Options:**
- Install the `d26` managed package containing the namespaced actions
- Point packaged agent to local actions by removing `d26__` prefix
- Deploy namespaced versions of the actions to the target org

## License

MIT
