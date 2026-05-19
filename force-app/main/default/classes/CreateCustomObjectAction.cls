/**
 * @description Invocable Apex action for creating Opportunity records with fields from Field Set
 * @author Claude Code
 * @date 2026-05-12
 */
@JsonAccess(serializable='always' deserializable='always')
global with sharing class CreateCustomObjectAction {

    private static final String DEFAULT_CONFIG = 'Default';

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
                    throw new IllegalArgumentException('Field Values JSON is required');
                }

                // Get configuration name
                String configName = DEFAULT_CONFIG;
                if (String.isNotBlank(input.configurationName)) {
                    configName = input.configurationName;
                }

                // Parse the JSON field values
                Map<String, Object> fieldValues = (Map<String, Object>) JSON.deserializeUntyped(input.fieldValuesJson);

                // Get allowed fields from configuration
                Set<String> allowedFields = getAllowedFieldsFromConfig(configName);
                if (allowedFields.isEmpty()) {
                    throw new IllegalArgumentException('Configuration "' + configName + '" not found or Field Set is empty');
                }

                // Create Opportunity
                Opportunity newOpp = new Opportunity();

                // Get field metadata
                Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Opportunity.fields.getMap();

                // Set field values (only if in Field Set)
                for (String fieldName : fieldValues.keySet()) {
                    String fieldNameLower = fieldName.toLowerCase();

                    if (!allowedFields.contains(fieldNameLower)) {
                        throw new IllegalArgumentException('Field "' + fieldName + '" is not in the configured Field Set');
                    }

                    if (!fieldMap.containsKey(fieldNameLower)) {
                        throw new IllegalArgumentException('Field not found on Opportunity: ' + fieldName);
                    }

                    Object fieldValue = fieldValues.get(fieldName);
                    Schema.SObjectField fieldToken = fieldMap.get(fieldNameLower);
                    Schema.DisplayType fieldType = fieldToken.getDescribe().getType();

                    // Type conversion based on field type
                    newOpp.put(fieldToken, convertFieldValue(fieldValue, fieldType));
                }

                // Validate required fields
                validateRequiredFields(newOpp, allowedFields, fieldMap);

                // Insert the record
                insert newOpp;

                output.recordId = newOpp.Id;
                output.recordName = newOpp.Name;
                output.recordLink = '<strong><a href="/lightning/r/Opportunity/' + newOpp.Id + '/view">' + newOpp.Name + '</a></strong>';
                output.isSuccess = true;
                output.errorMessage = '';

            } catch (Exception e) {
                output.isSuccess = false;
                output.errorMessage = e.getMessage();
            }

            outputs.add(output);
        }

        return outputs;
    }

    /**
     * @description Gets allowed fields from the configuration's Field Set
     * @param configName Name of the configuration
     * @return Set of field API names (lowercase)
     */
    private static Set<String> getAllowedFieldsFromConfig(String configName) {
        Set<String> allowedFields = new Set<String>();

        // Look up configuration
        List<Agentforce_Opp_Config__mdt> configs = [
            SELECT Field_Set_Name__c
            FROM Agentforce_Opp_Config__mdt
            WHERE DeveloperName = :configName
            LIMIT 1
        ];

        if (configs.isEmpty()) {
            return allowedFields;
        }

        String fieldSetName = configs[0].Field_Set_Name__c;
        if (String.isBlank(fieldSetName)) {
            return allowedFields;
        }

        // Get Field Set
        Schema.FieldSet fieldSet = Schema.SObjectType.Opportunity.fieldSets.getMap().get(fieldSetName);
        if (fieldSet != null) {
            for (Schema.FieldSetMember field : fieldSet.getFields()) {
                allowedFields.add(field.getFieldPath().toLowerCase());
            }
        }

        return allowedFields;
    }

    /**
     * @description Validates that all required fields are populated
     * @param opp The Opportunity record
     * @param allowedFields Set of allowed field names
     * @param fieldMap Map of field API names to field tokens
     */
    private static void validateRequiredFields(Opportunity opp, Set<String> allowedFields, Map<String, Schema.SObjectField> fieldMap) {
        List<String> missingFields = new List<String>();

        for (String fieldName : allowedFields) {
            Schema.SObjectField fieldToken = fieldMap.get(fieldName);
            if (fieldToken != null) {
                Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();

                // Check if required and not populated
                if (!fieldDescribe.isNillable() && !fieldDescribe.isDefaultedOnCreate()) {
                    Object fieldValue = opp.get(fieldToken);
                    if (fieldValue == null) {
                        missingFields.add(fieldDescribe.getLabel());
                    }
                }
            }
        }

        if (!missingFields.isEmpty()) {
            throw new IllegalArgumentException('Missing required fields: ' + String.join(missingFields, ', '));
        }
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
    }
}
