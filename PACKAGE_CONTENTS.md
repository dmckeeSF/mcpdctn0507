# Package Contents - Agentforce Opportunity Manager

## Package Information
**Namespace:** `d26`  
**Type:** Managed Package (2GP)  
**Current Version:** 0.1.0.26 (04tao000005cbGbAAI)

---

## What's Included in Package

### 📦 Apex Classes (6 files)

**Invocable Actions:**
- `d26__GetOpportunityFieldsAction.cls` - Returns field metadata from Field Sets
- `d26__CreateCustomObjectAction.cls` - Creates Opportunities with validation
  - Field Set validation
  - Account resolution (ID or name search via SOSL)
  - Type conversion (Date, Decimal, Boolean, etc.)
  - Picklist validation
  - Rich text HTML link output

**Test Classes:**
- `d26__GetOpportunityFieldsActionTest.cls` - 100% coverage
- `d26__CreateCustomObjectActionTest.cls` - 100% coverage

### 🗂️ Custom Metadata Type

**Type Definition:**
- `d26__Agentforce_Opp_Config__mdt` - Configuration object
  - `Field_Set_Name__c` - References Opportunity Field Set
  - `Description__c` - Configuration purpose

**Records:**
- `Default` - Default configuration pointing to `Agentforce_Create_Fields`

### 📋 Field Sets

**Opportunity Field Sets:**
- `d26__Agentforce_Create_Fields` - Default field set
  - Required: Name, StageName, CloseDate, AccountId
  - Optional: OwnerId, Amount, Description, Type, LeadSource, NextStep

### 🤖 GenAiFunctions (with Input/Output Schemas)

**Agent Actions:**
- `Create_Opportunity/` - GenAiFunction wrapping `d26__CreateCustomObjectAction`
  - `Create_Opportunity.genAiFunction-meta.xml`
  - `input/schema.json` - Input parameters schema using lightning__textType
  - `output/schema.json` - Output response schema
- `Get_Opportunity_Fields/` - GenAiFunction wrapping `d26__GetOpportunityFieldsAction`
  - `Get_Opportunity_Fields.genAiFunction-meta.xml`
  - `input/schema.json` - Input parameters schema
  - `output/schema.json` - Output response schema

**Note:** Schemas use Lightning standard types (lightning__textType, lightning__booleanType, etc.) and are placed INSIDE GenAiFunction directories for proper package discovery.

### 🎨 Lightning Web Component

**agentScriptSetup (5 files):**
- Enhanced setup page with 4-step guided workflow
- Copy-to-clipboard functionality for:
  - Agent metadata fields (Name, Developer Name, Description)
  - Two Agent Script variants:
    - `MANAGE_OPPORTUNITIES_AGENT` - References `d26__` namespaced GenAiFunctions (for package)
    - `LOCAL_MANAGE_OPPORTUNITIES_AGENT` - References local non-namespaced actions (for demo)
- Step 1: Required permissions checklist
- Step 2: Agent creation with copy-paste fields
- Step 3: Agent Script selection
- Step 4: Field set customization instructions

### 📱 Custom Application

**d26__Agentforce_Opportunity_Manager:**
- Custom Lightning app with standard navigation
- Includes tabs:
  - Agentforce Studio (standard tab)
  - Opportunity Agent Setup (custom tab)
- Branded with Salesforce blue theme
- Provides integrated workflow for agent setup

### 🔐 Permission Set

**d26__Agentforce_Opportunity_Manager_Access:**
- Grants visibility to the custom app
- Grants access to the Opportunity Agent Setup tab
- Assign to users who need to configure agents

### 📄 Custom Tab & FlexiPage

- `d26__Agentforce_Setup` - Custom tab for setup page
- `d26__Agentforce_Opportunity_Setup` - FlexiPage containing the LWC

---

## Not Included in Package (Local Demo Only)

These files are in `local-demo/` directory and are NOT packaged:

### Local Apex Actions (for quick testing)
- `CreateCustomObjectActionLocal.cls` - Identical logic, no namespace
- `GetOpportunityFieldsActionLocal.cls` - Identical logic, no namespace

**Purpose:** Allow customers to quickly test the solution without installing the managed package.

---

## Package Structure

```
force-app/main/default/
├── classes/                           # 4 Apex files (namespaced)
│   ├── CreateCustomObjectAction.cls
│   ├── CreateCustomObjectActionTest.cls
│   ├── GetOpportunityFieldsAction.cls
│   └── GetOpportunityFieldsActionTest.cls
├── customMetadata/                    # 1 record
│   └── Agentforce_Opp_Config.Default.md-meta.xml
├── objects/
│   ├── Agentforce_Opp_Config__mdt/   # CMT definition + fields
│   │   ├── Agentforce_Opp_Config__mdt.object-meta.xml
│   │   └── fields/
│   │       ├── Description__c.field-meta.xml
│   │       └── Field_Set_Name__c.field-meta.xml
│   └── Opportunity/
│       └── fieldSets/                 # 1 field set
│           └── Agentforce_Create_Fields.fieldSet-meta.xml
├── genAiFunctions/                    # 2 actions with schemas
│   ├── Create_Opportunity/
│   │   ├── Create_Opportunity.genAiFunction-meta.xml
│   │   ├── input/
│   │   │   └── schema.json
│   │   └── output/
│   │       └── schema.json
│   └── Get_Opportunity_Fields/
│       ├── Get_Opportunity_Fields.genAiFunction-meta.xml
│       ├── input/
│       │   └── schema.json
│       └── output/
│           └── schema.json
├── lwc/                               # 5 files
│   └── agentScriptSetup/
│       ├── agentScriptSetup.html     # Enhanced 4-step UI
│       ├── agentScriptSetup.js       # Contains both Agent Scripts + metadata
│       ├── agentScriptSetup.css      # Styling
│       ├── agentScriptsData.js       # Agent Script constants
│       └── agentScriptSetup.js-meta.xml
├── applications/                      # 1 Custom App
│   └── Agentforce_Opportunity_Manager.app-meta.xml
├── permissionsets/                    # 1 Permission Set
│   └── Agentforce_Opportunity_Manager_Access.permissionset-meta.xml
├── flexipages/                        # 1 FlexiPage
│   └── Agentforce_Opportunity_Setup.flexipage-meta.xml
└── tabs/                              # 1 Custom Tab
    └── Agentforce_Setup.tab-meta.xml

local-demo/                            # NOT packaged
├── CreateCustomObjectActionLocal.cls
├── GetOpportunityFieldsActionLocal.cls
├── genAiFunctions/
│   ├── Create_Opportunity/           # References Local actions
│   └── Get_Opportunity_Fields/
└── (meta.xml files)
```

---

## Key Features

### ✅ Account Resolution
- Accepts Account ID (15 or 18 chars)
- Accepts Account name (fuzzy SOSL search)
- Returns helpful errors for multiple matches

### ✅ Rich Text Output
- `recordLink` output contains HTML: `<strong><a href="...">Opportunity Name</a></strong>`
- Agent displays clickable links directly in chat

### ✅ Validation
- Field Set enforcement (only allowed fields)
- Required field checking
- Date format validation (YYYY-MM-DD)
- Picklist value validation
- Reference field validation

### ✅ Type Conversion
- Automatic conversion: String, Date, Decimal, Boolean, Integer, Currency, Percent, DateTime

### ✅ Multi-Configuration Support
- Custom Metadata allows multiple configurations
- Each configuration points to different Field Set
- Example: Sales_Team, Partner_Team configs

---

## What's NOT Packaged (By Design)

### ❌ Agent Metadata
- `bots/` - Runtime artifacts (org-generated)
- `aiAuthoringBundles/` - Agent Script source (embedded in LWC as text)
- `genAiPlugins/` - Topics (org-generated)
- `genAiPlannerBundles/` - Compiled agent (org-generated)

**Why?** Agent metadata is org-specific and generated at runtime. Agent Script is distributed as copy-paste text in the setup LWC.

### ❌ Permission Sets
- Removed system permission sets (`sfdcInternalInt__*`)
- Removed agent-specific permission sets (reference non-existent bots)

---

## Installation & Setup

### 1. Install Package

```bash
sf package install --package 04tao000005cbGbAAI --wait 20
```

### 2. Assign Permission Set

```bash
sf org assign permset --name d26__Agentforce_Opportunity_Manager_Access
```

Or via Setup → Permission Sets → d26__Agentforce Opportunity Manager Access → Manage Assignments

### 3. Open Custom App

1. Click App Launcher (waffle icon)
2. Search for **"Agentforce Opportunity Manager"**
3. Open the app

### 4. Follow In-App Setup Instructions

The **Opportunity Agent Setup** tab provides:
- **Step 1:** Required permissions checklist
- **Step 2:** Create agent in Agentforce Studio with copy-paste fields
  - Name: "Opportunity Manager"
  - Developer Name: "Opportunity_Manager"
  - Description: Pre-generated
- **Step 3:** Copy Agent Script (packaged or local version)
- **Step 4:** Customize field sets (optional)

The Agent Script references GenAiFunctions with `source` + `target` pattern:
- `source: "d26__Get_Opportunity_Fields"` (GenAiFunction API name)
- `target: "apex://d26__GetOpportunityFieldsAction"` (Apex invocation URI)

---

## Version History

| Version | Package ID | Date | Changes |
|---------|-----------|------|---------|
| 0.1.0.26 | 04tao000005cbGbAAI | 2026-05-19 | Added custom app, permission set, enhanced setup UI - CURRENT STABLE |
| 0.1.0.24 | 04tao000005cb5JAAQ | 2026-05-19 | Aligned Agent Script with GenAiFunction schemas (removed list types) |
| 0.1.0.23 | 04tao000005cb3hAAA | 2026-05-19 | Added source field to Agent Script actions |
| 0.1.0.22 | 04tao000005cb25AAA | 2026-05-19 | Fixed GenAiFunction schemas to match Apex InvocableVariables |
| 0.1.0-19 | 04tao000005cau1AAA | 2026-05-19 | Removed GenAiPlannerBundle (runtime artifact) |
| 0.1.0-18 | 04tao000005casPAAQ | 2026-05-19 | Added GenAiFunction input/output schemas |

---

## Development Workflow

### Local Testing (No Package)
1. Use `LOCAL_MANAGE_OPPORTUNITIES_AGENT` from setup page
2. References `GetOpportunityFieldsActionLocal` and `CreateCustomObjectActionLocal`
3. Files in `local-demo/` directory
4. No namespace prefix

### Package Testing
1. Create package version: `sf package version create`
2. Install in subscriber org
3. Use `MANAGE_OPPORTUNITIES_AGENT` from setup page
4. References `d26__GetOpportunityFieldsAction` and `d26__CreateCustomObjectAction`

---

## Agent Script Packaging Pattern

### source + target Pattern
Agent Script actions reference packaged Apex via GenAiFunctions using both fields:

```agentscript
Get_Opportunity_Fields:
    source: "d26__Get_Opportunity_Fields"        # GenAiFunction API name
    target: "apex://d26__GetOpportunityFieldsAction"  # Apex invocation URI
```

**Why both fields?**
- `source`: Enables metadata discovery and strict validation
- `target`: Specifies actual Apex class to invoke
- Together: Provides proper package distribution via GenAiFunctions

### Type System Limitations
Agent Script does NOT support list types. Only declare outputs the agent uses:
- ✅ Supported: string, number, boolean, object, currency, date, datetime, time, timestamp, id, integer, long
- ❌ Not supported: list of string, arrays

**Impact:** GenAiFunction schemas must match Agent Script declarations exactly when `source` field is present.

See `docs/AGENTSCRIPT_PACKAGED_ACTIONS.md` for complete guide.

---

## Support

- **Technical Docs:** See README.md
- **Agent Script Reference:** See setup page in Opportunity Agent Setup tab
- **License:** MIT
