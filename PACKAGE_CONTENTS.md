# Package Contents - Agentforce Opportunity Manager

## Package Information
**Namespace:** `d26`  
**Type:** Managed Package (2GP)  
**Current Version:** 0.1.0-19 (04tao000005cau1AAA)

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

**agentScriptSetup (3 files):**
- Setup page with embedded Agent Script examples
- Copy-to-clipboard functionality for two agent variants:
  - `MANAGE_OPPORTUNITIES_AGENT` - References `d26__` namespaced actions (for package)
  - `LOCAL_MANAGE_OPPORTUNITIES_AGENT` - References local non-namespaced actions (for demo)
- Step-by-step instructions

### 📄 Custom Tab & FlexiPage

- `d26__Opportunity_Agent_Setup` - Custom tab for setup page
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
├── lwc/                               # 3 files
│   └── agentScriptSetup/
│       ├── agentScriptSetup.html
│       ├── agentScriptSetup.js       # Contains both Agent Scripts
│       └── agentScriptSetup.js-meta.xml
├── flexipages/                        # 1 FlexiPage
│   └── Agentforce_Opportunity_Setup.flexipage-meta.xml
└── tabs/                              # 1 Custom Tab
    └── Opportunity_Agent_Setup.tab-meta.xml

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
sf package install --package 04tao000005cau1AAA --wait 20
```

### 2. Access Setup Page

Navigate to **Opportunity Agent Setup** tab.

### 3. Copy Agent Script

- Click "Copy Packaged Agent Script" button
- Paste into Agent Builder (Setup → Agent Builder → New Agent → Code Editor)

### 4. Create Agent in Agent Builder

The Agent Script references:
- `apex://d26__GetOpportunityFieldsAction`
- `apex://d26__CreateCustomObjectAction`

These actions are automatically discovered from the managed package.

### 5. Validate & Publish

```bash
sf agent validate authoring-bundle --api-name <Developer_Name>
sf agent publish authoring-bundle --api-name <Developer_Name>
sf agent activate --api-name <Developer_Name>
```

---

## Version History

| Version | Package ID | Date | Changes |
|---------|-----------|------|---------|
| 0.1.0-19 | 04tao000005cau1AAA | 2026-05-19 | Removed GenAiPlannerBundle (runtime artifact) - CURRENT STABLE |
| 0.1.0-18 | 04tao000005casPAAQ | 2026-05-19 | Added GenAiFunction input/output schemas (had GenAiPlannerBundle issue) |
| 0.1.0-17 | 04tao000005capBAAQ | 2026-05-19 | Previous version (without GenAiFunctions) |
| 0.1.0-16 | 04tao000005cVzBAAU | 2026-05-19 | Earlier version |

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

## Known Issues

### Packaged Agent Error
**Error:** `Action name not found: d26__GetOpportunityFieldsAction`

**Root Cause:** Packaged Agent Script references `d26__` namespaced actions, but managed package is not installed in target org.

**Resolution:**
- Install managed package, OR
- Use `LOCAL_MANAGE_OPPORTUNITIES_AGENT` variant (no namespace)

---

## Support

- **Technical Docs:** See README.md
- **Agent Script Reference:** See setup page in Opportunity Agent Setup tab
- **License:** MIT
