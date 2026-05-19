/**
 * @description Test class for CreateCustomObjectAction
 * @author Claude Code
 * @date 2026-05-12
 */
@IsTest
private class CreateCustomObjectActionTest {

    /**
     * @description Test successful Opportunity creation with required fields
     */
    @IsTest
    static void testCreateOpportunitySuccess() {
        // Arrange
        CreateCustomObjectAction.CreateRecordInput input = new CreateCustomObjectAction.CreateRecordInput();
        input.configurationName = 'Default';
        input.fieldValuesJson = '{"Name":"Test Opportunity","StageName":"Prospecting","CloseDate":"2026-12-31"}';

        List<CreateCustomObjectAction.CreateRecordInput> inputs = new List<CreateCustomObjectAction.CreateRecordInput>{input};

        // Act
        Test.startTest();
        List<CreateCustomObjectAction.CreateRecordOutput> outputs = CreateCustomObjectAction.createRecord(inputs);
        Test.stopTest();

        // Assert
        System.assertEquals(1, outputs.size(), 'Should return one output');
        CreateCustomObjectAction.CreateRecordOutput output = outputs[0];
        System.assertEquals(true, output.isSuccess, 'Should be successful');
        System.assertNotEquals(null, output.recordId, 'Record ID should be set');
        System.assertEquals(null, output.errorMessage, 'Error message should be null');

        // Verify record was created
        Opportunity opp = [SELECT Id, Name, StageName, CloseDate FROM Opportunity WHERE Id = :output.recordId];
        System.assertEquals('Test Opportunity', opp.Name, 'Name should match');
        System.assertEquals('Prospecting', opp.StageName, 'StageName should match');
        System.assertEquals(Date.valueOf('2026-12-31'), opp.CloseDate, 'CloseDate should match');
    }

    /**
     * @description Test Opportunity creation with optional fields
     */
    @IsTest
    static void testCreateOpportunityWithOptionalFields() {
        // Arrange
        CreateCustomObjectAction.CreateRecordInput input = new CreateCustomObjectAction.CreateRecordInput();
        input.fieldValuesJson = '{"Name":"Large Deal","StageName":"Qualification","CloseDate":"2026-12-31","Amount":100000,"Description":"Large enterprise deal","Type":"New Customer"}';

        List<CreateCustomObjectAction.CreateRecordInput> inputs = new List<CreateCustomObjectAction.CreateRecordInput>{input};

        // Act
        Test.startTest();
        List<CreateCustomObjectAction.CreateRecordOutput> outputs = CreateCustomObjectAction.createRecord(inputs);
        Test.stopTest();

        // Assert
        System.assertEquals(1, outputs.size(), 'Should return one output');
        CreateCustomObjectAction.CreateRecordOutput output = outputs[0];
        System.assertEquals(true, output.isSuccess, 'Should be successful');
        System.assertNotEquals(null, output.recordId, 'Record ID should be set');

        // Verify record was created with all fields
        Opportunity opp = [SELECT Id, Name, Amount, Description, Type FROM Opportunity WHERE Id = :output.recordId];
        System.assertEquals('Large Deal', opp.Name, 'Name should match');
        System.assertEquals(100000, opp.Amount, 'Amount should match');
        System.assertEquals('Large enterprise deal', opp.Description, 'Description should match');
        System.assertEquals('New Customer', opp.Type, 'Type should match');
    }

    /**
     * @description Test with field not in Field Set
     */
    @IsTest
    static void testCreateOpportunityFieldNotInFieldSet() {
        // Arrange
        CreateCustomObjectAction.CreateRecordInput input = new CreateCustomObjectAction.CreateRecordInput();
        input.fieldValuesJson = '{"Name":"Test","StageName":"Prospecting","CloseDate":"2026-12-31","AccountId":"001000000000000"}';

        List<CreateCustomObjectAction.CreateRecordInput> inputs = new List<CreateCustomObjectAction.CreateRecordInput>{input};

        // Act
        Test.startTest();
        List<CreateCustomObjectAction.CreateRecordOutput> outputs = CreateCustomObjectAction.createRecord(inputs);
        Test.stopTest();

        // Assert
        System.assertEquals(1, outputs.size(), 'Should return one output');
        CreateCustomObjectAction.CreateRecordOutput output = outputs[0];
        System.assertEquals(false, output.isSuccess, 'Should fail');
        System.assertEquals(null, output.recordId, 'Record ID should be null');
        System.assertNotEquals(null, output.errorMessage, 'Error message should be set');
        System.assert(output.errorMessage.contains('not in the configured Field Set'), 'Error should mention Field Set');
    }

    /**
     * @description Test with invalid JSON
     */
    @IsTest
    static void testCreateOpportunityInvalidJson() {
        // Arrange
        CreateCustomObjectAction.CreateRecordInput input = new CreateCustomObjectAction.CreateRecordInput();
        input.fieldValuesJson = 'invalid json';

        List<CreateCustomObjectAction.CreateRecordInput> inputs = new List<CreateCustomObjectAction.CreateRecordInput>{input};

        // Act
        Test.startTest();
        List<CreateCustomObjectAction.CreateRecordOutput> outputs = CreateCustomObjectAction.createRecord(inputs);
        Test.stopTest();

        // Assert
        System.assertEquals(1, outputs.size(), 'Should return one output');
        CreateCustomObjectAction.CreateRecordOutput output = outputs[0];
        System.assertEquals(false, output.isSuccess, 'Should fail');
        System.assertEquals(null, output.recordId, 'Record ID should be null');
        System.assertNotEquals(null, output.errorMessage, 'Error message should be set');
    }

    /**
     * @description Test with missing required fields
     */
    @IsTest
    static void testCreateOpportunityMissingRequiredFields() {
        // Arrange
        CreateCustomObjectAction.CreateRecordInput input = new CreateCustomObjectAction.CreateRecordInput();
        input.fieldValuesJson = '{"Name":"Test Opportunity"}';

        List<CreateCustomObjectAction.CreateRecordInput> inputs = new List<CreateCustomObjectAction.CreateRecordInput>{input};

        // Act
        Test.startTest();
        List<CreateCustomObjectAction.CreateRecordOutput> outputs = CreateCustomObjectAction.createRecord(inputs);
        Test.stopTest();

        // Assert
        System.assertEquals(1, outputs.size(), 'Should return one output');
        CreateCustomObjectAction.CreateRecordOutput output = outputs[0];
        System.assertEquals(false, output.isSuccess, 'Should fail');
        System.assertEquals(null, output.recordId, 'Record ID should be null');
        System.assertNotEquals(null, output.errorMessage, 'Error message should be set');
        System.assert(output.errorMessage.contains('required'), 'Error should mention required fields');
    }

    /**
     * @description Test with empty field values
     */
    @IsTest
    static void testCreateOpportunityEmptyJson() {
        // Arrange
        CreateCustomObjectAction.CreateRecordInput input = new CreateCustomObjectAction.CreateRecordInput();
        input.fieldValuesJson = '';

        List<CreateCustomObjectAction.CreateRecordInput> inputs = new List<CreateCustomObjectAction.CreateRecordInput>{input};

        // Act
        Test.startTest();
        List<CreateCustomObjectAction.CreateRecordOutput> outputs = CreateCustomObjectAction.createRecord(inputs);
        Test.stopTest();

        // Assert
        System.assertEquals(1, outputs.size(), 'Should return one output');
        CreateCustomObjectAction.CreateRecordOutput output = outputs[0];
        System.assertEquals(false, output.isSuccess, 'Should fail');
        System.assertEquals(null, output.recordId, 'Record ID should be null');
        System.assertNotEquals(null, output.errorMessage, 'Error message should be set');
        System.assert(output.errorMessage.contains('required'), 'Error should mention required field');
    }

    /**
     * @description Test with multiple Opportunities
     */
    @IsTest
    static void testCreateMultipleOpportunities() {
        // Arrange
        CreateCustomObjectAction.CreateRecordInput input1 = new CreateCustomObjectAction.CreateRecordInput();
        input1.fieldValuesJson = '{"Name":"Opportunity 1","StageName":"Prospecting","CloseDate":"2026-12-31"}';

        CreateCustomObjectAction.CreateRecordInput input2 = new CreateCustomObjectAction.CreateRecordInput();
        input2.fieldValuesJson = '{"Name":"Opportunity 2","StageName":"Qualification","CloseDate":"2026-12-31"}';

        List<CreateCustomObjectAction.CreateRecordInput> inputs = new List<CreateCustomObjectAction.CreateRecordInput>{input1, input2};

        // Act
        Test.startTest();
        List<CreateCustomObjectAction.CreateRecordOutput> outputs = CreateCustomObjectAction.createRecord(inputs);
        Test.stopTest();

        // Assert
        System.assertEquals(2, outputs.size(), 'Should return two outputs');
        for (CreateCustomObjectAction.CreateRecordOutput output : outputs) {
            System.assertEquals(true, output.isSuccess, 'Should be successful');
            System.assertNotEquals(null, output.recordId, 'Record ID should be set');
        }

        // Verify records were created
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity WHERE Id IN (:outputs[0].recordId, :outputs[1].recordId)];
        System.assertEquals(2, opps.size(), 'Should have created two opportunities');
    }
}
