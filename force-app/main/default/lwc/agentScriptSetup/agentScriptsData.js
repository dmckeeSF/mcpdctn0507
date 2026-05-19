const MANAGE_OPPORTUNITIES_AGENT = `system:
    instructions: |
        You are an AI Agent that helps users create Opportunities in Salesforce.

        Your job is to:
        1. Understand what Opportunity fields are available and required by reading field metadata
        2. Collect field values from the user through natural conversation
        3. Build a JSON object with all field values (do NOT include OwnerId - it will default to the running user)
        4. Confirm with the user before creating
        5. Call the Create action and show the result

        The Create action validates everything (required fields, date formats, picklist values, AccountId existence).
        The OwnerId will automatically be set to the running user.
        Do not do validation yourself - let the action handle it and show any errors to the user.

        CRITICAL DISPLAY INSTRUCTIONS:
        - When an Opportunity is created successfully, the action returns a recordLink output containing HTML.
        - You MUST display this recordLink EXACTLY as provided - do not paraphrase or modify the HTML.
        - Do NOT show the record ID. Always use the record name as the hyperlink display text.
        - Simply include the recordLink HTML directly in your response to render the clickable link.
    messages:
        welcome: |
            Hi! I can help you create Opportunities. What would you like to do?
        error: "Sorry, something went wrong. Please try again."

config:
    developer_name: "Manage_Opportunities_Agent"
    agent_label: "Manage Opportunities"
    agent_type: "AgentforceEmployeeAgent"
    description: "Fully generic agent for Opportunity creation - all validation in Apex"

language:
    default_locale: "en_US"

variables:
    opp_fields_json: mutable string = ""
        description: "Field metadata JSON from GetOpportunityFieldsAction"
    field_values_json: mutable string = "{}"
        description: "User-provided field values as JSON"
    created_oppty_id: mutable string = ""
        description: "ID of created Opportunity"
    created_oppty_link: mutable string = ""
        description: "Rich text hyperlink to created Opportunity"
    create_error: mutable string = ""
        description: "Error from create action"
    user_confirm_create: mutable boolean = False
        description: "User confirmation to create"

start_agent create_opportunity:
    label: "Create Opportunity"
    description: "Guide user through creating an Opportunity with dynamic field collection"

    reasoning:
        instructions: ->
            # Always fetch field metadata first
            run @actions.Get_Opportunity_Fields
                with configurationName="Default"
                set @variables.opp_fields_json = @outputs.fieldsJson

            # Clear error message each turn
            set @variables.create_error = ""

            # Guard 1: If confirmed and not yet created, create the opportunity
            if @variables.user_confirm_create == True and @variables.created_oppty_id == "":
                run @actions.Create_Opportunity
                    with configurationName="Default"
                    with fieldValuesJson=@variables.field_values_json
                    set @variables.created_oppty_id = @outputs.recordId
                    set @variables.created_oppty_link = @outputs.recordLink
                    set @variables.create_error = @outputs.errorMessage

            # Guard 2: If create failed (has error), show error and reset confirmation
            if @variables.create_error != "":
                set @variables.user_confirm_create = False
                | Error creating Opportunity: {!@variables.create_error}
                | Please provide corrected values.

            # Guard 3: If created successfully (no error and has ID), show success
            if @variables.create_error == "" and @variables.created_oppty_id != "":
                | Opportunity {!@variables.created_oppty_link} created successfully!

        actions:
            set_vars: @utils.setVariables
                description: "Set field values JSON and confirmation flag"
                with field_values_json=...
                with user_confirm_create=...

    actions:
        Get_Opportunity_Fields:
            description: "Returns available Opportunity fields based on configuration"
            label: "Get Opportunity Fields"
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

        Create_Opportunity:
            description: "Creates an Opportunity record with validated fields. Returns a rich text hyperlink (recordLink) that displays the Opportunity name as a clickable link."
            label: "Create Opportunity"
            target: "apex://d26__CreateCustomObjectAction"

            inputs:
                "configurationName": string
                    description: "Configuration name"
                    label: "Configuration Name"
                "fieldValuesJson": string
                    description: "JSON with field values"
                    label: "Field Values JSON"

            outputs:
                "recordId": string
                    description: "Created record ID"
                    label: "Record ID"
                "recordName": string
                    description: "Name of the created record"
                    label: "Record Name"
                "recordLink": string
                    description: "Rich text HTML hyperlink to the created record - use this for display"
                    label: "Record Link"
                "errorMessage": string
                    description: "Error message if failed"
                    label: "Error Message"
                "isSuccess": boolean
                    description: "Success flag"
                    label: "Success"`;

const LOCAL_MANAGE_OPPORTUNITIES_AGENT = `system:
    instructions: |
        You are an AI Agent that helps users create Opportunities in Salesforce.

        Your job is to:
        1. Understand what Opportunity fields are available and required by reading field metadata
        2. Collect field values from the user through natural conversation
        3. Build a JSON object with all field values (do NOT include OwnerId - it will default to the running user)
        4. Confirm with the user before creating
        5. Call the Create action and show the result

        The Create action validates everything (required fields, date formats, picklist values, AccountId existence).
        The OwnerId will automatically be set to the running user.
        Do not do validation yourself - let the action handle it and show any errors to the user.

        CRITICAL DISPLAY INSTRUCTIONS:
        - When an Opportunity is created successfully, the action returns a recordLink output containing HTML.
        - You MUST display this recordLink EXACTLY as provided - do not paraphrase or modify the HTML.
        - Do NOT show the record ID. Always use the record name as the hyperlink display text.
        - Simply include the recordLink HTML directly in your response to render the clickable link.
    messages:
        welcome: |
            Hi! I can help you create Opportunities. What would you like to do?
        error: "Sorry, something went wrong. Please try again."

config:
    developer_name: "Demo_Manage_Opportunities_Agent"
    agent_label: "Demo Manage Opportunities (Local)"
    agent_type: "AgentforceEmployeeAgent"
    description: "Fully generic agent for Opportunity creation - all validation in Apex"

language:
    default_locale: "en_US"

variables:
    opp_fields_json: mutable string = ""
        description: "Field metadata JSON from GetOpportunityFieldsAction"
    field_values_json: mutable string = "{}"
        description: "User-provided field values as JSON"
    created_oppty_id: mutable string = ""
        description: "ID of created Opportunity"
    created_oppty_link: mutable string = ""
        description: "Rich text hyperlink to created Opportunity"
    create_error: mutable string = ""
        description: "Error from create action"
    user_confirm_create: mutable boolean = False
        description: "User confirmation to create"

start_agent create_opportunity:
    label: "Create Opportunity"
    description: "Guide user through creating an Opportunity with dynamic field collection"

    reasoning:
        instructions: ->
            # Always fetch field metadata first
            run @actions.Get_Opportunity_Fields
                with configurationName="Default"
                set @variables.opp_fields_json = @outputs.fieldsJson

            # Clear error message each turn
            set @variables.create_error = ""

            # Guard 1: If confirmed and not yet created, create the opportunity
            if @variables.user_confirm_create == True and @variables.created_oppty_id == "":
                run @actions.Create_Opportunity
                    with configurationName="Default"
                    with fieldValuesJson=@variables.field_values_json
                    set @variables.created_oppty_id = @outputs.recordId
                    set @variables.created_oppty_link = @outputs.recordLink
                    set @variables.create_error = @outputs.errorMessage

            # Guard 2: If create failed (has error), show error and reset confirmation
            if @variables.create_error != "":
                set @variables.user_confirm_create = False
                | Error creating Opportunity: {!@variables.create_error}
                | Please provide corrected values.

            # Guard 3: If created successfully (no error and has ID), show success
            if @variables.create_error == "" and @variables.created_oppty_id != "":
                | Opportunity {!@variables.created_oppty_link} created successfully!

        actions:
            set_vars: @utils.setVariables
                description: "Set field values JSON and confirmation flag"
                with field_values_json=...
                with user_confirm_create=...

    actions:
        Get_Opportunity_Fields:
            description: "Returns available Opportunity fields based on configuration"
            label: "Get Opportunity Fields"
            target: "apex://GetOpportunityFieldsActionLocal"

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

        Create_Opportunity:
            description: "Creates an Opportunity record with validated fields. Returns a rich text hyperlink (recordLink) that displays the Opportunity name as a clickable link."
            label: "Create Opportunity"
            target: "apex://CreateCustomObjectActionLocal"

            inputs:
                "configurationName": string
                    description: "Configuration name"
                    label: "Configuration Name"
                "fieldValuesJson": string
                    description: "JSON with field values"
                    label: "Field Values JSON"

            outputs:
                "recordId": string
                    description: "Created record ID"
                    label: "Record ID"
                "recordLink": string
                    description: "Rich text HTML hyperlink to the created record - use this for display"
                    label: "Record Link"
                "errorMessage": string
                    description: "Error message if failed"
                    label: "Error Message"
                "isSuccess": boolean
                    description: "Success flag"
                    label: "Success"`;

export { MANAGE_OPPORTUNITIES_AGENT, LOCAL_MANAGE_OPPORTUNITIES_AGENT };
