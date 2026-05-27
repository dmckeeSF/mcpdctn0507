@JsonAccess(serializable='always' deserializable='always')
global with sharing class CreateAccountAction {

    private static final Set<String> ALLOWED_FIELDS = new Set<String>{
        'name', 'phone', 'billingstreet', 'billingcity', 'billingstate',
        'billingpostalcode', 'billingcountry'
    };

    private static final Set<String> REQUIRED_FIELDS = new Set<String>{ 'name' };

    @JsonAccess(serializable='always' deserializable='always')
    global class CreateAccountInput {
        @InvocableVariable(
            label='Field Values (JSON)'
            description='JSON string with Account field values. Required: Name. Optional: Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry. Example: {"Name":"Acme Corp","Phone":"555-1234","BillingCity":"San Francisco","BillingState":"CA","BillingCountry":"US"}'
            required=true
        )
        global String fieldValuesJson;
    }

    @JsonAccess(serializable='always' deserializable='always')
    global class CreateAccountOutput {
        @InvocableVariable(label='Record Id' description='ID of the created Account')
        global String recordId;

        @InvocableVariable(label='Record Name' description='Name of the created Account')
        global String recordName;

        @InvocableVariable(label='Record Link' description='Rich text hyperlink to the created Account')
        global String recordLink;

        @InvocableVariable(label='Success' description='Whether the Account was created successfully')
        global Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if creation failed')
        global String errorMessage;
    }

    @InvocableMethod(
        label='Create Account'
        description='Creates an Account record with Name and optional billing address fields'
        category='Agentforce Actions'
    )
    global static List<CreateAccountOutput> createAccount(List<CreateAccountInput> inputs) {
        List<CreateAccountOutput> outputs = new List<CreateAccountOutput>();

        for (CreateAccountInput input : inputs) {
            CreateAccountOutput output = new CreateAccountOutput();
            output.isSuccess = false;

            try {
                if (String.isBlank(input.fieldValuesJson)) {
                    output.errorMessage = 'Field Values JSON is required';
                    outputs.add(output);
                    continue;
                }

                Map<String, Object> fieldValues;
                try {
                    fieldValues = (Map<String, Object>) JSON.deserializeUntyped(input.fieldValuesJson);
                } catch (Exception e) {
                    output.errorMessage = 'Invalid JSON format: ' + e.getMessage();
                    outputs.add(output);
                    continue;
                }

                // Validate required fields
                String missingError = validateRequiredFields(fieldValues);
                if (String.isNotBlank(missingError)) {
                    output.errorMessage = missingError;
                    outputs.add(output);
                    continue;
                }

                // Build and populate the Account record
                Account newAccount = new Account();
                Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Account.fields.getMap();
                Boolean hasError = false;

                for (String fieldName : fieldValues.keySet()) {
                    String fieldNameLower = fieldName.toLowerCase();

                    if (!ALLOWED_FIELDS.contains(fieldNameLower)) {
                        output.errorMessage = 'Field "' + fieldName + '" is not allowed. Allowed fields: Name, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry';
                        hasError = true;
                        break;
                    }

                    if (!fieldMap.containsKey(fieldNameLower)) {
                        output.errorMessage = 'Field not found on Account: ' + fieldName;
                        hasError = true;
                        break;
                    }

                    Object fieldValue = fieldValues.get(fieldName);
                    if (fieldValue == null) {
                        continue;
                    }

                    Schema.SObjectField fieldToken = fieldMap.get(fieldNameLower);
                    newAccount.put(fieldToken, String.valueOf(fieldValue));
                }

                if (hasError) {
                    outputs.add(output);
                    continue;
                }

                insert newAccount;

                output.recordId = newAccount.Id;
                output.recordName = newAccount.Name;
                output.recordLink = '<strong><a href="/lightning/r/Account/' + newAccount.Id + '/view">' + newAccount.Name + '</a></strong>';
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

    private static String validateRequiredFields(Map<String, Object> fieldValues) {
        List<String> missing = new List<String>();
        for (String required : REQUIRED_FIELDS) {
            Boolean found = false;
            for (String key : fieldValues.keySet()) {
                if (key.toLowerCase() == required) {
                    Object val = fieldValues.get(key);
                    if (val != null && String.isNotBlank(String.valueOf(val))) {
                        found = true;
                        break;
                    }
                }
            }
            if (!found) {
                missing.add(required.capitalize());
            }
        }
        if (!missing.isEmpty()) {
            return 'Missing required fields: ' + String.join(missing, ', ');
        }
        return null;
    }
}
