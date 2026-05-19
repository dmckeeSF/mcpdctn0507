/**
 * @description Invocable Apex action for creating Opportunity records with fields from Field Set
 * @author Claude Code
 * @date 2026-05-18
 */
@JsonAccess(serializable='always' deserializable='always')
global with sharing class CreateCustomObjectAction {

    private static final String DEFAULT_CONFIG = 'Default';

    /**
     * @description Wrapper for Field Set metadata
     */
    private class FieldSetMetadata {
        Set<String> allowedFields;
        Map<String, Schema.DescribeFieldResult> fieldDescribes;
        Set<String> requiredFields;
    }

    /**
     * @description Input parameters for the invocable action
     */
    @JsonAccess(serializable='always' deserializable='always')
    global class CreateRecordInput {
        @InvocableVariable(label='Configuration Name' description='Name of the Agentforce Opportunity Configuration (e.g., "Default", "Sales_Team"). If blank, uses "Default".')
        global String configurationName;

        @InvocableVariable(label='Field Values (JSON)' description='JSON string containing field API names and values. Example: {"Name":"Test Opportunity","StageName":"Prospecting","CloseDate":"2026-12-31"}' required=true)
        global String fieldValuesJson;
    }

    /**
     * @description Output parameters for the invocable action
     */
    @JsonAccess(serializable='always' deserializable='always')
    global class CreateRecordOutput {
        @InvocableVariable(label='Record Id' description='ID of the created record')
        global String recordId;

        @InvocableVariable(label='Record Name' description='Name of the created record')
        global String recordName;

        @InvocableVariable(label='Record Link' description='Rich text hyperlink to the created record')
        global String recordLink;

        @InvocableVariable(label='Success' description='Whether the record was created successfully')
        global Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if creation failed')
        global String errorMessage;
    }

    /**
     * @description Creates an Opportunity record with fields from Field Set
     * @param inputs List of input parameters
     * @return List of output results
     */
    @InvocableMethod(
        label='Create Opportunity'
        description='Creates an Opportunity record with fields defined in the Agentforce_Create_Fields Field Set'
        category='Agentforce Actions'
    )
    global static List<CreateRecordOutput> createRecord(List<CreateRecordInput> inputs) {
        List<CreateRecordOutput> outputs = new List<CreateRecordOutput>();

        for (CreateRecordInput input : inputs) {
            CreateRecordOutput output = new CreateRecordOutput();
            output.isSuccess = false;

            try {
                // Validate input
                if (String.isBlank(input.fieldValuesJson)) {
                    output.errorMessage = 'Field Values JSON is required';
                    outputs.add(output);
                    continue;
                }

                // Get configuration name
                String configName = DEFAULT_CONFIG;
                if (String.isNotBlank(input.configurationName)) {
                    configName = input.configurationName;
                }

                // Parse the JSON field values
                Map<String, Object> fieldValues;
                try {
                    fieldValues = (Map<String, Object>) JSON.deserializeUntyped(input.fieldValuesJson);
                } catch (Exception e) {
                    output.errorMessage = 'Invalid JSON format: ' + e.getMessage();
                    outputs.add(output);
                    continue;
                }

                // Resolve Account field if present (handles both ID and name)
                String accountResolutionError = resolveAccountField(fieldValues);
                if (String.isNotBlank(accountResolutionError)) {
                    output.errorMessage = accountResolutionError;
                    outputs.add(output);
                    continue;
                }

                // Get field metadata from configuration
                FieldSetMetadata fieldSetMeta = getFieldSetMetadata(configName);
                if (fieldSetMeta == null || fieldSetMeta.allowedFields.isEmpty()) {
                    output.errorMessage = 'Configuration "' + configName + '" not found or Field Set is empty';
                    outputs.add(output);
                    continue;
                }

                // Validate all required fields are present
                String missingFieldsError = validateRequiredFieldsPresent(fieldValues, fieldSetMeta);
                if (String.isNotBlank(missingFieldsError)) {
                    output.errorMessage = missingFieldsError;
                    outputs.add(output);
                    continue;
                }

                // Create Opportunity
                Opportunity newOpp = new Opportunity();
                Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Opportunity.fields.getMap();

                // Set and validate each field value
                for (String fieldName : fieldValues.keySet()) {
                    String fieldNameLower = fieldName.toLowerCase();

                    // Check field is in Field Set
                    if (!fieldSetMeta.allowedFields.contains(fieldNameLower)) {
                        output.errorMessage = 'Field "' + fieldName + '" is not in the configured Field Set';
                        break;
                    }

                    // Check field exists on Opportunity
                    if (!fieldMap.containsKey(fieldNameLower)) {
                        output.errorMessage = 'Field not found on Opportunity: ' + fieldName;
                        break;
                    }

                    Object fieldValue = fieldValues.get(fieldName);
                    Schema.SObjectField fieldToken = fieldMap.get(fieldNameLower);
                    Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();

                    // Validate and convert field value
                    String validationError = validateFieldValue(fieldName, fieldValue, fieldDescribe);
                    if (String.isNotBlank(validationError)) {
                        output.errorMessage = validationError;
                        break;
                    }

                    // Type conversion and set value
                    newOpp.put(fieldToken, convertFieldValue(fieldValue, fieldDescribe.getType()));
                }

                // If validation errors occurred during field processing, return early
                if (String.isNotBlank(output.errorMessage)) {
                    outputs.add(output);
                    continue;
                }

                // Set OwnerId to running user if not provided
                if (newOpp.OwnerId == null) {
                    newOpp.OwnerId = UserInfo.getUserId();
                }

                // Insert the record
                insert newOpp;

                output.recordId = newOpp.Id;
                output.recordName = newOpp.Name;
                output.recordLink = '<strong><a href="/lightning/r/Opportunity/' + newOpp.Id + '/view">' + newOpp.Name + '</a></strong>';
                output.isSuccess = true;
                output.errorMessage = '';

            } catch (DmlException e) {
                output.isSuccess = false;
                output.errorMessage = 'Database error: ' + e.getDmlMessage(0);
            } catch (Exception e) {
                output.isSuccess = false;
                output.errorMessage = e.getMessage();
            }

            outputs.add(output);
        }

        return outputs;
    }

    /**
     * @description Gets Field Set metadata including allowed fields and required fields
     * @param configName Name of the configuration
     * @return FieldSetMetadata wrapper or null if not found
     */
    private static FieldSetMetadata getFieldSetMetadata(String configName) {
        // Look up configuration
        List<Agentforce_Opp_Config__mdt> configs = [
            SELECT Field_Set_Name__c
            FROM Agentforce_Opp_Config__mdt
            WHERE DeveloperName = :configName
            LIMIT 1
        ];

        if (configs.isEmpty()) {
            return null;
        }

        String fieldSetName = configs[0].Field_Set_Name__c;
        if (String.isBlank(fieldSetName)) {
            return null;
        }

        // Get Field Set (handle both namespaced and non-namespaced)
        Schema.FieldSet fieldSet = Schema.SObjectType.Opportunity.fieldSets.getMap().get(fieldSetName);
        if (fieldSet == null) {
            // Try with d26 namespace prefix
            fieldSet = Schema.SObjectType.Opportunity.fieldSets.getMap().get('d26__' + fieldSetName);
        }
        if (fieldSet == null) {
            return null;
        }

        // Build metadata
        FieldSetMetadata meta = new FieldSetMetadata();
        meta.allowedFields = new Set<String>();
        meta.fieldDescribes = new Map<String, Schema.DescribeFieldResult>();
        meta.requiredFields = new Set<String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Opportunity.fields.getMap();

        for (Schema.FieldSetMember fsm : fieldSet.getFields()) {
            String fieldPath = fsm.getFieldPath().toLowerCase();
            meta.allowedFields.add(fieldPath);

            Schema.SObjectField fieldToken = fieldMap.get(fieldPath);
            if (fieldToken != null) {
                Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
                meta.fieldDescribes.put(fieldPath, fieldDescribe);

                // Track required fields
                if (fsm.getRequired() || (!fieldDescribe.isNillable() && !fieldDescribe.isDefaultedOnCreate())) {
                    meta.requiredFields.add(fieldPath);
                }
            }
        }

        return meta;
    }

    /**
     * @description Validates that all required fields are present in input JSON
     * @param fieldValues The field values from JSON
     * @param fieldSetMeta Field Set metadata
     * @return Error message if validation fails, null if valid
     */
    private static String validateRequiredFieldsPresent(Map<String, Object> fieldValues, FieldSetMetadata fieldSetMeta) {
        List<String> missingFields = new List<String>();

        for (String requiredField : fieldSetMeta.requiredFields) {
            Boolean fieldPresent = false;

            // Check if field is in the input (case-insensitive)
            for (String inputField : fieldValues.keySet()) {
                if (inputField.toLowerCase() == requiredField) {
                    Object value = fieldValues.get(inputField);
                    if (value != null && String.valueOf(value) != '') {
                        fieldPresent = true;
                        break;
                    }
                }
            }

            if (!fieldPresent) {
                Schema.DescribeFieldResult fieldDescribe = fieldSetMeta.fieldDescribes.get(requiredField);
                if (fieldDescribe != null) {
                    missingFields.add(fieldDescribe.getLabel());
                }
            }
        }

        if (!missingFields.isEmpty()) {
            return 'Missing required fields: ' + String.join(missingFields, ', ');
        }

        return null;
    }

    /**
     * @description Validates a field value based on its type
     * @param fieldName Name of the field
     * @param fieldValue Value to validate
     * @param fieldDescribe Field describe result
     * @return Error message if validation fails, null if valid
     */
    private static String validateFieldValue(String fieldName, Object fieldValue, Schema.DescribeFieldResult fieldDescribe) {
        if (fieldValue == null) {
            return null; // Null values are handled by required field validation
        }

        String valueStr = String.valueOf(fieldValue);
        Schema.DisplayType fieldType = fieldDescribe.getType();

        // Date validation
        if (fieldType == Schema.DisplayType.DATE) {
            return validateDateFormat(fieldName, valueStr);
        }

        // Picklist validation
        if (fieldType == Schema.DisplayType.PICKLIST) {
            return validatePicklistValue(fieldName, valueStr, fieldDescribe);
        }

        // Reference field validation (e.g., AccountId)
        if (fieldType == Schema.DisplayType.REFERENCE) {
            return validateReferenceField(fieldName, valueStr, fieldDescribe);
        }

        return null;
    }

    /**
     * @description Validates date format (YYYY-MM-DD)
     * @param fieldName Name of the field
     * @param dateStr Date string to validate
     * @return Error message if invalid, null if valid
     */
    private static String validateDateFormat(String fieldName, String dateStr) {
        if (String.isBlank(dateStr)) {
            return null;
        }

        // Check YYYY-MM-DD format
        if (dateStr.length() != 10 || dateStr.substring(4, 5) != '-' || dateStr.substring(7, 8) != '-') {
            return 'Field "' + fieldName + '" must be in YYYY-MM-DD format';
        }

        // Try to parse
        try {
            Date.valueOf(dateStr);
        } catch (Exception e) {
            return 'Field "' + fieldName + '" has invalid date value: ' + dateStr;
        }

        return null;
    }

    /**
     * @description Validates picklist value
     * @param fieldName Name of the field
     * @param value Value to validate
     * @param fieldDescribe Field describe result
     * @return Error message if invalid, null if valid
     */
    private static String validatePicklistValue(String fieldName, String value, Schema.DescribeFieldResult fieldDescribe) {
        if (String.isBlank(value)) {
            return null;
        }

        Set<String> validValues = new Set<String>();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive()) {
                validValues.add(entry.getLabel().toLowerCase());
                validValues.add(entry.getValue().toLowerCase());
            }
        }

        if (!validValues.contains(value.toLowerCase())) {
            List<String> validLabels = new List<String>();
            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                if (entry.isActive()) {
                    validLabels.add(entry.getLabel());
                }
            }
            return 'Field "' + fieldName + '" has invalid value "' + value + '". Valid values: ' + String.join(validLabels, ', ');
        }

        return null;
    }

    /**
     * @description Validates reference field (e.g., AccountId)
     * @param fieldName Name of the field
     * @param recordId Record ID to validate
     * @param fieldDescribe Field describe result
     * @return Error message if invalid, null if valid
     */
    private static String validateReferenceField(String fieldName, String recordId, Schema.DescribeFieldResult fieldDescribe) {
        if (String.isBlank(recordId)) {
            return null;
        }

        // Check ID format
        if (recordId.length() != 15 && recordId.length() != 18) {
            return 'Field "' + fieldName + '" must be a valid Salesforce ID (15 or 18 characters)';
        }

        // Check ID is alphanumeric
        if (!recordId.isAlphanumeric()) {
            return 'Field "' + fieldName + '" must be a valid Salesforce ID';
        }

        // Account resolution happens earlier in resolveAccountField, so skip validation here
        // Other reference fields can be validated if needed in the future

        return null;
    }

    /**
     * @description Resolves Account field from name or ID
     * @param fieldValues The field values map (modified in place)
     * @return Error message if resolution fails, null if success or no Account field
     */
    private static String resolveAccountField(Map<String, Object> fieldValues) {
        // Check if Account or AccountId is present
        String accountKey = null;
        Object accountValue = null;

        for (String key : fieldValues.keySet()) {
            if (key.equalsIgnoreCase('Account') || key.equalsIgnoreCase('AccountId')) {
                accountKey = key;
                accountValue = fieldValues.get(key);
                break;
            }
        }

        // No account field provided
        if (accountKey == null || accountValue == null) {
            return null;
        }

        String accountInput = String.valueOf(accountValue).trim();
        if (String.isBlank(accountInput)) {
            return null;
        }

        // Check if input looks like a Salesforce ID (15 or 18 chars, alphanumeric)
        Boolean isId = (accountInput.length() == 15 || accountInput.length() == 18) && accountInput.isAlphanumeric();

        String resolvedAccountId = null;

        if (isId) {
            // Treat as ID lookup
            List<Account> accounts = [SELECT Id FROM Account WHERE Id = :accountInput LIMIT 1];
            if (accounts.isEmpty()) {
                return 'Account not found with ID: ' + accountInput;
            }
            resolvedAccountId = accounts[0].Id;
        } else {
            // Treat as name search - use SOSL for fuzzy matching
            String searchQuery = 'FIND \'' + String.escapeSingleQuotes(accountInput) + '*\' IN NAME FIELDS RETURNING Account(Id, Name ORDER BY Name LIMIT 10)';
            List<List<SObject>> searchResults = Search.query(searchQuery);
            List<Account> accounts = (List<Account>) searchResults[0];

            if (accounts.isEmpty()) {
                return 'Account not found matching: "' + accountInput + '". Please provide a valid Account ID (15/18 characters) or exact Account Name.';
            } else if (accounts.size() == 1) {
                // Single match - use it
                resolvedAccountId = accounts[0].Id;
            } else {
                // Multiple matches - return error with options
                List<String> accountNames = new List<String>();
                for (Account acc : accounts) {
                    accountNames.add(acc.Name + ' (' + acc.Id + ')');
                }
                return 'Multiple accounts found matching "' + accountInput + '": ' + String.join(accountNames, ', ') + '. Please provide the exact Account ID.';
            }
        }

        // Replace the Account/AccountId field with resolved ID
        fieldValues.remove(accountKey);
        fieldValues.put('AccountId', resolvedAccountId);

        return null;
    }

    /**
     * @description Converts field value to appropriate type
     * @param value The value to convert
     * @param fieldType The target field type
     * @return Converted value
     */
    private static Object convertFieldValue(Object value, Schema.DisplayType fieldType) {
        if (value == null) {
            return null;
        }

        try {
            switch on fieldType {
                when BOOLEAN {
                    return Boolean.valueOf(value);
                }
                when INTEGER {
                    return Integer.valueOf(value);
                }
                when DOUBLE, CURRENCY, PERCENT {
                    return Decimal.valueOf(String.valueOf(value));
                }
                when DATE {
                    return Date.valueOf(String.valueOf(value));
                }
                when DATETIME {
                    return DateTime.valueOf(String.valueOf(value));
                }
                when else {
                    return String.valueOf(value);
                }
            }
        } catch (Exception e) {
            // Validation should have caught this, but return null to prevent DML failure
            return null;
        }
    }
}
