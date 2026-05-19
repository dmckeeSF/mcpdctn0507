/**
 * @description Invocable Apex action that returns available Opportunity fields from Field Set
 * @author Claude Code
 * @date 2026-05-18
 */
@JsonAccess(serializable='always' deserializable='always')
global with sharing class GetOpportunityFieldsActionLocal {

    private static final String DEFAULT_CONFIG = 'Default';

    /**
     * @description Output parameters containing field metadata
     */
    @JsonAccess(serializable='always' deserializable='always')
    global class FieldMetadata {
        @InvocableVariable(label='Field API Name' description='API name of the field')
        global String apiName;

        @InvocableVariable(label='Field Label' description='User-friendly label')
        global String label;

        @InvocableVariable(label='Field Type' description='Data type (TEXT, PICKLIST, DATE, etc.)')
        global String fieldType;

        @InvocableVariable(label='Is Required' description='Whether the field is required')
        global Boolean isRequired;

        @InvocableVariable(label='Help Text' description='Field help text or description')
        global String helpText;

        @InvocableVariable(label='Picklist Values' description='Available picklist values (comma-separated)')
        global String picklistValues;
    }

    /**
     * @description Input parameters for the invocable action
     */
    @JsonAccess(serializable='always' deserializable='always')
    global class GetFieldsInput {
        @InvocableVariable(label='Configuration Name' description='Name of the Agentforce Opportunity Configuration (e.g., "Default", "Sales_Team"). If blank, uses "Default".')
        global String configurationName;
    }

    /**
     * @description Output wrapper for the invocable action
     */
    @JsonAccess(serializable='always' deserializable='always')
    global class GetFieldsOutput {
        @InvocableVariable(label='Fields (JSON)' description='JSON array of available fields with metadata')
        global String fieldsJson;

        @InvocableVariable(label='Success' description='Whether the operation was successful')
        global Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if operation failed')
        global String errorMessage;

        @InvocableVariable(label='Required Field API Names' description='List of API names for required fields')
        global List<String> requiredFieldApiNames;

        @InvocableVariable(label='Recommended Field API Names' description='List of API names for recommended fields')
        global List<String> recommendedFieldApiNames;

        @InvocableVariable(label='Field Metadata By API' description='Map of apiName to field metadata object')
        global String fieldMetadataByApi;
    }

    /**
     * @description Gets available Opportunity fields from Field Set referenced by configuration
     * @param inputs List of input parameters with configuration name
     * @return List of output results
     */
    @InvocableMethod(
        label='Get Opportunity Fields (Local)'
        description='Returns available Opportunity fields based on configuration - Local Demo Version'
        category='Agentforce Actions'
    )
    global static List<GetFieldsOutput> getFields(List<GetFieldsInput> inputs) {
        List<GetFieldsOutput> outputs = new List<GetFieldsOutput>();
        GetFieldsOutput output = new GetFieldsOutput();
        output.isSuccess = false;

        try {
            // Get configuration name
            String configName = DEFAULT_CONFIG;
            if (inputs != null && !inputs.isEmpty() && String.isNotBlank(inputs[0].configurationName)) {
                configName = inputs[0].configurationName;
            }

            // Look up configuration
            List<Agentforce_Opp_Config__mdt> configs = [
                SELECT Field_Set_Name__c, Description__c
                FROM Agentforce_Opp_Config__mdt
                WHERE DeveloperName = :configName
                LIMIT 1
            ];

            if (configs.isEmpty()) {
                throw new IllegalArgumentException('Configuration "' + configName + '" not found');
            }

            String fieldSetName = configs[0].Field_Set_Name__c;
            if (String.isBlank(fieldSetName)) {
                throw new IllegalArgumentException('Configuration "' + configName + '" has no Field Set specified');
            }

            // Get Field Set (handle both namespaced and non-namespaced)
            Schema.FieldSet fieldSet = Schema.SObjectType.Opportunity.fieldSets.getMap().get(fieldSetName);
            if (fieldSet == null) {
                // Try with d26 namespace prefix
                fieldSet = Schema.SObjectType.Opportunity.fieldSets.getMap().get('d26__' + fieldSetName);
            }
            if (fieldSet == null) {
                throw new IllegalArgumentException('Field Set "' + fieldSetName + '" not found on Opportunity object');
            }

            // Build field metadata
            List<FieldMetadata> fieldMetadataList = new List<FieldMetadata>();
            List<String> requiredFields = new List<String>();
            List<String> recommendedFields = new List<String>();
            Map<String, Object> metadataByApi = new Map<String, Object>();
            Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Opportunity.fields.getMap();

            for (Schema.FieldSetMember fsm : fieldSet.getFields()) {
                String fieldPath = fsm.getFieldPath();
                Schema.SObjectField fieldToken = fieldMap.get(fieldPath.toLowerCase());

                if (fieldToken != null) {
                    Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
                    FieldMetadata metadata = new FieldMetadata();

                    metadata.apiName = fieldDescribe.getName();
                    metadata.label = fieldDescribe.getLabel();
                    metadata.fieldType = String.valueOf(fieldDescribe.getType());
                    metadata.isRequired = fsm.getRequired() || (!fieldDescribe.isNillable() && !fieldDescribe.isDefaultedOnCreate());
                    metadata.helpText = fieldDescribe.getInlineHelpText();

                    // Get picklist values if applicable
                    if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST ||
                        fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        List<String> picklistLabels = new List<String>();
                        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                            if (entry.isActive()) {
                                picklistLabels.add(entry.getLabel());
                            }
                        }
                        metadata.picklistValues = String.join(picklistLabels, ', ');
                    }

                    fieldMetadataList.add(metadata);

                    // Build required fields list
                    if (metadata.isRequired) {
                        requiredFields.add(metadata.apiName);
                    }

                    // Build recommended fields list (non-required fields are recommended)
                    if (!metadata.isRequired) {
                        recommendedFields.add(metadata.apiName);
                    }

                    // Build metadata map
                    Map<String, Object> fieldMetaMap = new Map<String, Object>();
                    fieldMetaMap.put('apiName', metadata.apiName);
                    fieldMetaMap.put('label', metadata.label);
                    fieldMetaMap.put('dataType', metadata.fieldType);
                    fieldMetaMap.put('required', metadata.isRequired);
                    if (String.isNotBlank(metadata.helpText)) {
                        fieldMetaMap.put('helpText', metadata.helpText);
                    }
                    if (String.isNotBlank(metadata.picklistValues)) {
                        fieldMetaMap.put('picklistValues', metadata.picklistValues);
                    }
                    metadataByApi.put(metadata.apiName, fieldMetaMap);
                }
            }

            // Convert to JSON
            output.fieldsJson = JSON.serializePretty(fieldMetadataList);
            output.requiredFieldApiNames = requiredFields;
            output.recommendedFieldApiNames = recommendedFields;
            output.fieldMetadataByApi = JSON.serialize(metadataByApi);
            output.isSuccess = true;

        } catch (Exception e) {
            output.isSuccess = false;
            output.errorMessage = e.getMessage();
        }

        outputs.add(output);
        return outputs;
    }
}
