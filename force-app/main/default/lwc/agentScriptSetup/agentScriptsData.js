const MANAGE_OPPORTUNITIES_AGENT = `system:
    instructions: "You are an AI Agent that helps users create Opportunities in Salesforce."
    messages:
        welcome: |
            Hi! I can help you create Opportunities. What would you like to do?
        error: "Sorry, something went wrong. Please try again."

config:
    developer_name: "Manage_Opportunities_Agent"
    agent_label: "Manage Opportunities"
    agent_type: "AgentforceEmployeeAgent"
    description: "Agent for Opportunity creation with guided field collection"

language:
    default_locale: "en_US"

variables:
    opp_fields_json: mutable object = {}
        description: "Field metadata from GetOpportunityFieldsAction"
    opp_name: mutable string = ""
        description: "Opportunity Name"
    close_date: mutable string = ""
        description: "Close Date in YYYY-MM-DD format"
    stage_name: mutable string = ""
        description: "Opportunity Stage"
    account_id: mutable string = ""
        description: "Account ID (18 characters)"
    created_oppty_id: mutable string = ""
        description: "ID of created Opportunity"
    create_oppty_success: mutable boolean = False
        description: "Whether creation succeeded"
    create_oppty_error: mutable string = ""
        description: "Error from create action"
    last_error: mutable string = ""
        description: "Last validation or action error"
    user_confirm_create: mutable boolean = False
        description: "User confirmation to create"

start_agent create_opportunity:
    label: "Create Opportunity"
    description: "Guide user through creating an Opportunity"

    reasoning:
        instructions: ->
            # Always fetch field metadata first
            run @actions.Get_Opportunity_Fields
                with configurationName="Default"
                set @variables.opp_fields_json = @outputs.fieldsJson

            # Reset error each turn unless explicitly set later
            set @variables.last_error = ""

            # Clear old errors when user confirms (fresh attempt)
            if @variables.user_confirm_create == True:
                set @variables.create_oppty_error = ""

            # Reset success flag each turn unless already succeeded
            if @variables.created_oppty_id == "":
                set @variables.create_oppty_success = False

            # Guard: Basic required field validation
            if @variables.created_oppty_id == "" and (@variables.opp_name == "" or @variables.close_date == "" or @variables.stage_name == "" or @variables.account_id == ""):
                set @variables.last_error = "Missing required fields: Name, Close Date (YYYY-MM-DD), Stage, and Account ID."
                | Error: {!@variables.last_error}
                | If available, show stage options from {!@variables.opp_fields_json}.
                | Please provide corrected values.
                set @variables.user_confirm_create = False

            # Guard: Close date format validation
            if @variables.created_oppty_id == "" and @variables.last_error == "" and @variables.close_date != "" and (@variables.close_date[4] != "-" or @variables.close_date[7] != "-"):
                set @variables.last_error = "Close Date must be in YYYY-MM-DD format."
                | Error: {!@variables.last_error}
                | Please provide a valid date in YYYY-MM-DD format.
                set @variables.user_confirm_create = False

            # Guard: If validation passed but not yet confirmed, ask for confirmation
            if @variables.created_oppty_id == "" and @variables.last_error == "" and @variables.user_confirm_create == False:
                | Ready to create Opportunity with these details:
                | Name={!@variables.opp_name}, CloseDate={!@variables.close_date}, Stage={!@variables.stage_name}, AccountId={!@variables.account_id}
                | Confirm to create?

            # Guard: If confirmed and validated, create the opportunity
            if @variables.created_oppty_id == "" and @variables.last_error == "" and @variables.user_confirm_create == True:
                run @actions.Create_Opportunity
                    with configurationName="Default"
                    with fieldValuesJson="{\"Name\":\"" + @variables.opp_name + "\",\"CloseDate\":\"" + @variables.close_date + "\",\"StageName\":\"" + @variables.stage_name + "\",\"AccountId\":\"" + @variables.account_id + "\"}"
                    set @variables.created_oppty_id = @outputs.recordId
                    set @variables.create_oppty_error = @outputs.errorMessage

                # Handle create results immediately after action
                if @outputs.recordId != "" and @outputs.errorMessage == "":
                    set @variables.create_oppty_success = True
                    | Opportunity created successfully! ID: {!@outputs.recordId}
                    | View it at: /lightning/r/Opportunity/{!@outputs.recordId}/view

                if @outputs.errorMessage != "":
                    set @variables.create_oppty_success = False
                    set @variables.user_confirm_create = False
                    | Error creating Opportunity: {!@outputs.errorMessage}
                    | Please correct the issue and try again.

        actions:
            set_vars: @utils.setVariables
                description: "Set field values and confirmation flag"
                with opp_name=...
                with close_date=...
                with stage_name=...
                with account_id=...
                with user_confirm_create=...

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

        Create_Opportunity:
            description: "Creates an Opportunity record with validated fields"
            label: "Create Opportunity"
            source: "d26__Create_Opportunity"
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
                "errorMessage": string
                    description: "Error message if failed"
                    label: "Error Message"
                "isSuccess": boolean
                    description: "Success flag"
                    label: "Success"`;

const DEMO_MANAGE_OPPORTUNITIES_AGENT = `system:
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

        CRITICAL: When you receive HTML markup in your instructions (like <strong><a href="...">text</a></strong>), you MUST output it EXACTLY as provided. Do NOT paraphrase, summarize, or modify the HTML in any way. Copy it verbatim into your response.
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
    user_confirm_create: mutable boolean = False
        description: "User confirmation to create"
    created_oppty_id: mutable string = ""
        description: "ID of created Opportunity"
    created_oppty_link: mutable string = ""
        description: "Rich text hyperlink to created Opportunity"
    create_error: mutable string = ""
        description: "Error from create action"

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

            # Clear confirmation flag when user confirms (fresh attempt)
            if @variables.user_confirm_create == True:
                set @variables.create_error = ""

            # Guard 1: If not yet created and have field values but not confirmed, ask for confirmation
            if @variables.created_oppty_id == "" and @variables.field_values_json != "{}" and @variables.user_confirm_create == False:
                | Ready to create Opportunity with these details:
                | {!@variables.field_values_json}
                |
                | Confirm to create?

            # Guard 2: If confirmed and not yet created, create the opportunity
            if @variables.created_oppty_id == "" and @variables.field_values_json != "{}" and @variables.user_confirm_create == True:
                run @actions.Create_Opportunity
                    with configurationName="Default"
                    with fieldValuesJson=@variables.field_values_json
                    set @variables.created_oppty_id = @outputs.recordId
                    set @variables.created_oppty_link = @outputs.recordLink
                    set @variables.create_error = @outputs.errorMessage

            # Guard 3: If create failed (has error), show error and reset confirmation
            if @variables.create_error != "":
                set @variables.user_confirm_create = False
                | Error creating Opportunity: {!@variables.create_error}
                | Please provide corrected values.

            # Guard 4: If created successfully (no error and has ID), show success with clickable link
            if @variables.create_error == "" and @variables.created_oppty_id != "":
                | {!@variables.created_oppty_link}

        actions:
            set_vars: @utils.setVariables
                description: "Set field values and confirmation flag"
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

export { MANAGE_OPPORTUNITIES_AGENT, DEMO_MANAGE_OPPORTUNITIES_AGENT };
