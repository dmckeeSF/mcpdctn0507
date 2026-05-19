# Agent Script: Referencing Packaged Apex Actions via GenAiFunctions

## Overview

When distributing Agent Script implementations that reference managed package Apex actions, you must use GenAiFunction metadata as an intermediary layer. This document explains the pattern, validation requirements, and type system constraints.

## The Pattern: source + target

Agent Script actions that reference packaged Apex must declare both fields:

```agentscript
actions:
    Get_Opportunity_Fields:
        description: "Returns available Opportunity fields based on configuration"
        label: "Get Opportunity Fields"
        source: "d26__Get_Opportunity_Fields"
        target: "apex://d26__GetOpportunityFieldsAction"
        
        inputs:
            "configurationName": string
                description: "Configuration name"
                label: "Configuration Name"
        
        outputs:
            "fieldsJson": string
                description: "Field metadata JSON"
                label: "Fields JSON"
            "isSuccess": boolean
                description: "Success flag"
                label: "Success"
            "errorMessage": string
                description: "Error message if failed"
                label: "Error Message"
```

### Field Meanings

- **`source`**: GenAiFunction API name (e.g., `d26__Get_Opportunity_Fields`)
  - Used for metadata resolution at design time and runtime
  - Enables strict validation between Agent Script and GenAiFunction schemas
  - Must match the `fullName` in the GenAiFunction's `-meta.xml` file

- **`target`**: Apex invocation URI (e.g., `apex://d26__GetOpportunityFieldsAction`)
  - Specifies the actual Apex class to invoke
  - Uses standard Apex invocation protocol
  - Namespace prefix included for managed package classes

## Why Both Fields Are Required

The `source` field was discovered through Ronit's Package-Visualizer example and enables:

1. **Metadata Discovery** - Agent Builder can find and display the action with proper schemas
2. **Strict Validation** - GenAiFunction schemas are validated against Agent Script declarations
3. **Runtime Resolution** - The platform can resolve the action through multiple metadata layers
4. **Package Distribution** - GenAiFunctions are packageable (Winter '25+) and travel with the package

Without the `source` field, the action may work in preview but fail validation or not appear correctly in Agent Builder.

## Strict Validation Rules

When the `source` field is present, the platform enforces **exact schema alignment**:

### Rule 1: Agent Script outputs must match GenAiFunction schema exactly

All outputs declared in the GenAiFunction's `output/schema.json` must also be declared in the Agent Script action's `outputs` block, and vice versa.

**Example Error:**
```
Validation failed for action(s) 'Get_Opportunity_Fields' due to invalid attribute value for 'output'. 
The following output parameters defined on the source action were missing: 
'requiredFieldApiNames, recommendedFieldApiNames, fieldMetadataByApi'
```

This error occurs when:
- GenAiFunction schema declares outputs that Agent Script doesn't
- Agent Script declares outputs that GenAiFunction schema doesn't

### Rule 2: Input parameter names must match Apex @InvocableVariable names exactly

The GenAiFunction input schema must use the exact property names from the Apex `@InvocableVariable` declarations.

**Wrong:**
```json
{
  "properties": {
    "accountId": { "lightning:type": "lightning__textType" },
    "fieldValues": { "lightning:type": "lightning__textType" }
  }
}
```

**Right:**
```json
{
  "properties": {
    "configurationName": { "lightning:type": "lightning__textType" },
    "fieldValuesJson": { "lightning:type": "lightning__textType" }
  }
}
```

The names must match what's in your Apex:
```java
@InvocableVariable(label='Configuration Name' required=false)
public String configurationName;

@InvocableVariable(label='Field Values (JSON)' required=true)
public String fieldValuesJson;
```

### Rule 3: Output parameter names must match Apex @InvocableVariable names exactly

Same rule applies to outputs - GenAiFunction schema must match Apex output class variable names:

```java
@InvocableVariable(label='Record ID')
public String recordId;

@InvocableVariable(label='Record Name')  
public String recordName;

@InvocableVariable(label='Record Link')
public String recordLink;
```

GenAiFunction schema must have:
```json
{
  "properties": {
    "recordId": { "lightning:type": "lightning__textType" },
    "recordName": { "lightning:type": "lightning__textType" },
    "recordLink": { "lightning:type": "lightning__textType" }
  }
}
```

## Agent Script Type System Limitations

Agent Script has a **limited type system** that does not include list/array types:

### Supported Types
- `string`
- `number`
- `boolean`
- `object`
- `currency`
- `date`
- `datetime`
- `time`
- `timestamp`
- `id`
- `integer`
- `long`

### Unsupported Types
- ❌ `list of string` - Syntax error
- ❌ `list of number` - Syntax error
- ❌ Arrays of any type - Not supported

### Impact on GenAiFunction Schemas

Even though GenAiFunction schemas support list types (via `lightning__listType`), you **cannot expose them** to Agent Script when using the `source` field:

**This will fail validation:**

GenAiFunction schema:
```json
{
  "properties": {
    "fieldsJson": { "lightning:type": "lightning__textType" },
    "requiredFieldApiNames": {
      "lightning:type": "lightning__listType",
      "items": { "lightning:type": "lightning__textType" }
    }
  }
}
```

Agent Script:
```agentscript
outputs:
    "fieldsJson": string
    "requiredFieldApiNames": list of string  # ❌ Syntax error
```

**Error messages:**
```
Syntax error: unexpected 'of string'
Unknown type 'of' for outputs requiredFieldApiNames
Unknown modifier 'list' for outputs requiredFieldApiNames
```

### Solution: Remove List Types from Both Layers

If your Apex returns list-type outputs that Agent Script doesn't use, remove them from both:

1. **GenAiFunction output schema** - Remove the list-type properties
2. **Agent Script outputs** - Only declare what you actually reference

The Apex can still return those values - they just won't be exposed to the Agent Script reasoning layer.

**Example:**

Apex returns 6 outputs:
```java
@InvocableVariable public String fieldsJson;
@InvocableVariable public Boolean isSuccess;
@InvocableVariable public String errorMessage;
@InvocableVariable public List<String> requiredFieldApiNames;
@InvocableVariable public List<String> recommendedFieldApiNames;
@InvocableVariable public String fieldMetadataByApi;
```

But Agent Script only uses 3:
```agentscript
outputs:
    "fieldsJson": string
    "isSuccess": boolean
    "errorMessage": string
```

GenAiFunction schema should match Agent Script (only 3 properties):
```json
{
  "properties": {
    "fieldsJson": { "lightning:type": "lightning__textType" },
    "isSuccess": { "lightning:type": "lightning__booleanType" },
    "errorMessage": { "lightning:type": "lightning__textType" }
  }
}
```

## Directory Structure

```
force-app/main/default/
├── classes/
│   ├── GetOpportunityFieldsAction.cls
│   └── CreateCustomObjectAction.cls
├── genAiFunctions/
│   ├── Get_Opportunity_Fields/
│   │   ├── Get_Opportunity_Fields.genAiFunction-meta.xml
│   │   ├── input/
│   │   │   └── schema.json
│   │   └── output/
│   │       └── schema.json
│   └── Create_Opportunity/
│       ├── Create_Opportunity.genAiFunction-meta.xml
│       ├── input/
│       │   └── schema.json
│       └── output/
│           └── schema.json
└── lwc/
    └── agentScriptSetup/
        ├── agentScriptSetup.html
        ├── agentScriptSetup.js
        └── agentScriptsData.js  # Contains Agent Script source
```

## Complete Example

### 1. Apex Class (d26__GetOpportunityFieldsAction)

```java
public class GetOpportunityFieldsAction {
    
    public class Request {
        @InvocableVariable(label='Configuration Name' required=false)
        public String configurationName;
    }
    
    public class Response {
        @InvocableVariable(label='Fields (JSON)')
        public String fieldsJson;
        
        @InvocableVariable(label='Success')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Error Message')
        public String errorMessage;
        
        // These are returned but not exposed to Agent Script
        @InvocableVariable(label='Required Field API Names')
        public List<String> requiredFieldApiNames;
        
        @InvocableVariable(label='Recommended Field API Names')
        public List<String> recommendedFieldApiNames;
    }
    
    @InvocableMethod(label='Get Opportunity Fields' description='Returns available fields')
    public static List<Response> execute(List<Request> requests) {
        // Implementation
    }
}
```

### 2. GenAiFunction Metadata (d26__Get_Opportunity_Fields.genAiFunction-meta.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GenAiFunction xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiName>d26__Get_Opportunity_Fields</apiName>
    <description>Returns available Opportunity fields based on configuration</description>
    <invocationTarget>
        <invocationTargetType>apex</invocationTargetType>
        <targetClassName>d26.GetOpportunityFieldsAction</targetClassName>
    </invocationTarget>
    <label>Get Opportunity Fields</label>
</GenAiFunction>
```

### 3. GenAiFunction Input Schema (input/schema.json)

```json
{
  "unevaluatedProperties": false,
  "properties": {
    "configurationName": {
      "title": "Configuration Name",
      "description": "Name of the configuration",
      "lightning:type": "lightning__textType",
      "lightning:isPII": false,
      "copilotAction:isUserInput": false
    }
  },
  "lightning:type": "lightning__objectType"
}
```

### 4. GenAiFunction Output Schema (output/schema.json)

```json
{
  "unevaluatedProperties": false,
  "properties": {
    "fieldsJson": {
      "title": "Fields (JSON)",
      "description": "JSON array of available fields with metadata",
      "lightning:type": "lightning__textType",
      "lightning:isPII": false,
      "copilotAction:isDisplayable": true,
      "copilotAction:isUsedByPlanner": true
    },
    "isSuccess": {
      "title": "Success",
      "description": "Whether the operation was successful",
      "lightning:type": "lightning__booleanType",
      "lightning:isPII": false,
      "copilotAction:isDisplayable": true,
      "copilotAction:isUsedByPlanner": true
    },
    "errorMessage": {
      "title": "Error Message",
      "description": "Error message if operation failed",
      "lightning:type": "lightning__textType",
      "lightning:isPII": false,
      "copilotAction:isDisplayable": true,
      "copilotAction:isUsedByPlanner": true
    }
  },
  "lightning:type": "lightning__objectType"
}
```

Note: The list-type outputs (`requiredFieldApiNames`, `recommendedFieldApiNames`) are **excluded** from this schema because Agent Script doesn't support list types.

### 5. Agent Script (agentScriptsData.js)

```javascript
const MANAGE_OPPORTUNITIES_AGENT = `system:
    instructions: |
        You are an AI Agent that helps users create Opportunities in Salesforce.
        
        Your job is to:
        1. Understand what Opportunity fields are available by reading field metadata
        2. Collect field values from the user through natural conversation
        3. Build a JSON object with all field values
        4. Confirm with the user before creating
        5. Call the Create action and show the result

config:
    developer_name: "Manage_Opportunities_Agent"
    agent_label: "Manage Opportunities"
    agent_type: "AgentforceEmployeeAgent"

variables:
    opp_fields_json: mutable string = ""
        description: "Field metadata JSON from GetOpportunityFieldsAction"
    field_values_json: mutable string = "{}"
        description: "User-provided field values as JSON"

start_agent create_opportunity:
    label: "Create Opportunity"
    description: "Guide user through creating an Opportunity"
    
    reasoning:
        instructions: ->
            # Always fetch field metadata first
            run @actions.Get_Opportunity_Fields
                with configurationName="Default"
                set @variables.opp_fields_json = @outputs.fieldsJson
        
        actions:
            set_vars: @utils.setVariables
                description: "Set field values JSON"
                with field_values_json=...
    
    actions:
        Get_Opportunity_Fields:
            description: "Returns available Opportunity fields based on configuration"
            label: "Get Opportunity Fields"
            source: "d26__Get_Opportunity_Fields"
            target: "apex://d26__GetOpportunityFieldsAction"
            
            inputs:
                "configurationName": string
                    description: "Configuration name"
                    label: "Configuration Name"
            
            outputs:
                "fieldsJson": string
                    description: "Field metadata JSON"
                    label: "Fields JSON"
                "isSuccess": boolean
                    description: "Success flag"
                    label: "Success"
                "errorMessage": string
                    description: "Error message if failed"
                    label: "Error Message"
`;

export { MANAGE_OPPORTUNITIES_AGENT };
```

## Key Takeaways

1. **Always use both `source` and `target`** when referencing packaged Apex via GenAiFunctions
2. **GenAiFunction schemas must match Apex @InvocableVariable names** exactly
3. **Agent Script outputs must match GenAiFunction schemas** exactly when `source` is present
4. **Agent Script doesn't support list types** - remove them from both layers
5. **Apex can return more than you expose** - only declare what Agent Script uses
6. **GenAiFunctions are packageable** in 2GP (Winter '25+) and travel with your managed package
7. **Strict validation is enforced** when the `source` field is present

## Version History

- **v0.1.0.24** - Aligned Agent Script outputs with GenAiFunction schemas, removed list-type outputs
- **v0.1.0.23** - Added `source` field to packaged actions
- **v0.1.0.22** - Fixed GenAiFunction schemas to match Apex InvocableVariables
