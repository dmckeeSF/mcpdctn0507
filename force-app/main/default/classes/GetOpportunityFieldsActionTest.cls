/**
 * @description Test class for GetOpportunityFieldsAction
 * @author Claude Code
 * @date 2026-05-12
 */
@IsTest
private class GetOpportunityFieldsActionTest {

    /**
     * @description Test successful retrieval of fields from Field Set
     */
    @IsTest
    static void testGetFieldsSuccess() {
        // Arrange
        GetOpportunityFieldsAction.GetFieldsInput input = new GetOpportunityFieldsAction.GetFieldsInput();
        input.configurationName = 'Default';
        List<GetOpportunityFieldsAction.GetFieldsInput> inputs = new List<GetOpportunityFieldsAction.GetFieldsInput>{input};

        // Act
        Test.startTest();
        List<GetOpportunityFieldsAction.GetFieldsOutput> outputs = GetOpportunityFieldsAction.getFields(inputs);
        Test.stopTest();

        // Assert
        System.assertEquals(1, outputs.size(), 'Should return one output');
        GetOpportunityFieldsAction.GetFieldsOutput output = outputs[0];
        System.assertEquals(true, output.isSuccess, 'Should be successful');
        System.assertEquals(null, output.errorMessage, 'Error message should be null');
        System.assertNotEquals(null, output.fieldsJson, 'Fields JSON should be set');

        // Parse JSON and verify structure
        List<Object> fields = (List<Object>) JSON.deserializeUntyped(output.fieldsJson);
        System.assert(fields.size() > 0, 'Should return at least one field');

        // Verify first field has expected properties
        Map<String, Object> firstField = (Map<String, Object>) fields[0];
        System.assert(firstField.containsKey('apiName'), 'Should have apiName');
        System.assert(firstField.containsKey('label'), 'Should have label');
        System.assert(firstField.containsKey('fieldType'), 'Should have fieldType');
        System.assert(firstField.containsKey('isRequired'), 'Should have isRequired');
    }

    /**
     * @description Test that Name field is included
     */
    @IsTest
    static void testGetFieldsIncludesName() {
        // Arrange
        GetOpportunityFieldsAction.GetFieldsInput input = new GetOpportunityFieldsAction.GetFieldsInput();
        List<GetOpportunityFieldsAction.GetFieldsInput> inputs = new List<GetOpportunityFieldsAction.GetFieldsInput>{input};

        // Act
        Test.startTest();
        List<GetOpportunityFieldsAction.GetFieldsOutput> outputs = GetOpportunityFieldsAction.getFields(inputs);
        Test.stopTest();

        // Assert
        GetOpportunityFieldsAction.GetFieldsOutput output = outputs[0];
        System.assertEquals(true, output.isSuccess, 'Should be successful');

        List<Object> fields = (List<Object>) JSON.deserializeUntyped(output.fieldsJson);
        Boolean foundName = false;

        for (Object fieldObj : fields) {
            Map<String, Object> field = (Map<String, Object>) fieldObj;
            if (field.get('apiName') == 'Name') {
                foundName = true;
                System.assertEquals(true, field.get('isRequired'), 'Name should be required');
                break;
            }
        }

        System.assert(foundName, 'Should include Name field');
    }

    /**
     * @description Test that StageName field includes picklist values
     */
    @IsTest
    static void testGetFieldsIncludesPicklistValues() {
        // Arrange
        GetOpportunityFieldsAction.GetFieldsInput input = new GetOpportunityFieldsAction.GetFieldsInput();
        List<GetOpportunityFieldsAction.GetFieldsInput> inputs = new List<GetOpportunityFieldsAction.GetFieldsInput>{input};

        // Act
        Test.startTest();
        List<GetOpportunityFieldsAction.GetFieldsOutput> outputs = GetOpportunityFieldsAction.getFields(inputs);
        Test.stopTest();

        // Assert
        GetOpportunityFieldsAction.GetFieldsOutput output = outputs[0];
        System.assertEquals(true, output.isSuccess, 'Should be successful');

        List<Object> fields = (List<Object>) JSON.deserializeUntyped(output.fieldsJson);
        Boolean foundStageName = false;

        for (Object fieldObj : fields) {
            Map<String, Object> field = (Map<String, Object>) fieldObj;
            if (field.get('apiName') == 'StageName') {
                foundStageName = true;
                System.assertEquals('PICKLIST', field.get('fieldType'), 'StageName should be PICKLIST type');
                System.assertNotEquals(null, field.get('picklistValues'), 'Should have picklist values');
                String picklistValues = (String) field.get('picklistValues');
                System.assert(picklistValues.length() > 0, 'Picklist values should not be empty');
                break;
            }
        }

        System.assert(foundStageName, 'Should include StageName field');
    }

    /**
     * @description Test field metadata includes required information
     */
    @IsTest
    static void testGetFieldsMetadata() {
        // Arrange
        GetOpportunityFieldsAction.GetFieldsInput input = new GetOpportunityFieldsAction.GetFieldsInput();
        List<GetOpportunityFieldsAction.GetFieldsInput> inputs = new List<GetOpportunityFieldsAction.GetFieldsInput>{input};

        // Act
        Test.startTest();
        List<GetOpportunityFieldsAction.GetFieldsOutput> outputs = GetOpportunityFieldsAction.getFields(inputs);
        Test.stopTest();

        // Assert
        GetOpportunityFieldsAction.GetFieldsOutput output = outputs[0];
        List<Object> fields = (List<Object>) JSON.deserializeUntyped(output.fieldsJson);

        for (Object fieldObj : fields) {
            Map<String, Object> field = (Map<String, Object>) fieldObj;

            // Verify required metadata is present
            System.assertNotEquals(null, field.get('apiName'), 'API name should not be null');
            System.assertNotEquals(null, field.get('label'), 'Label should not be null');
            System.assertNotEquals(null, field.get('fieldType'), 'Field type should not be null');
            System.assertNotEquals(null, field.get('isRequired'), 'Is required should not be null');
        }
    }
}
