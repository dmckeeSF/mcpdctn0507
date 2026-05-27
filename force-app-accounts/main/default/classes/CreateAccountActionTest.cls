@IsTest
private class CreateAccountActionTest {

    @IsTest
    static void testCreateAccountSuccess() {
        CreateAccountAction.CreateAccountInput input = new CreateAccountAction.CreateAccountInput();
        input.fieldValuesJson = '{"Name":"Acme Corp","Phone":"555-1234","BillingCity":"San Francisco","BillingState":"CA","BillingPostalCode":"94105","BillingCountry":"US"}';

        List<CreateAccountAction.CreateAccountInput> inputs = new List<CreateAccountAction.CreateAccountInput>{ input };

        Test.startTest();
        List<CreateAccountAction.CreateAccountOutput> outputs = CreateAccountAction.createAccount(inputs);
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        CreateAccountAction.CreateAccountOutput output = outputs[0];
        System.assertEquals(true, output.isSuccess, output.errorMessage);
        System.assertNotEquals(null, output.recordId);
        System.assertEquals('', output.errorMessage);

        Account acc = [SELECT Id, Name, Phone, BillingCity, BillingState, BillingPostalCode, BillingCountry FROM Account WHERE Id = :output.recordId];
        System.assertEquals('Acme Corp', acc.Name);
        System.assertEquals('555-1234', acc.Phone);
        System.assertEquals('San Francisco', acc.BillingCity);
        System.assertEquals('CA', acc.BillingState);
        System.assertEquals('94105', acc.BillingPostalCode);
        System.assertEquals('US', acc.BillingCountry);
    }

    @IsTest
    static void testCreateAccountNameOnly() {
        CreateAccountAction.CreateAccountInput input = new CreateAccountAction.CreateAccountInput();
        input.fieldValuesJson = '{"Name":"Simple Corp"}';

        List<CreateAccountAction.CreateAccountInput> inputs = new List<CreateAccountAction.CreateAccountInput>{ input };

        Test.startTest();
        List<CreateAccountAction.CreateAccountOutput> outputs = CreateAccountAction.createAccount(inputs);
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        CreateAccountAction.CreateAccountOutput output = outputs[0];
        System.assertEquals(true, output.isSuccess, output.errorMessage);
        System.assertNotEquals(null, output.recordId);
        System.assert(output.recordLink.contains(output.recordId));
    }

    @IsTest
    static void testCreateAccountMissingName() {
        CreateAccountAction.CreateAccountInput input = new CreateAccountAction.CreateAccountInput();
        input.fieldValuesJson = '{"Phone":"555-9999"}';

        List<CreateAccountAction.CreateAccountInput> inputs = new List<CreateAccountAction.CreateAccountInput>{ input };

        Test.startTest();
        List<CreateAccountAction.CreateAccountOutput> outputs = CreateAccountAction.createAccount(inputs);
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        CreateAccountAction.CreateAccountOutput output = outputs[0];
        System.assertEquals(false, output.isSuccess);
        System.assert(output.errorMessage.contains('required'), output.errorMessage);
    }

    @IsTest
    static void testCreateAccountDisallowedField() {
        CreateAccountAction.CreateAccountInput input = new CreateAccountAction.CreateAccountInput();
        input.fieldValuesJson = '{"Name":"Test Corp","AnnualRevenue":1000000}';

        List<CreateAccountAction.CreateAccountInput> inputs = new List<CreateAccountAction.CreateAccountInput>{ input };

        Test.startTest();
        List<CreateAccountAction.CreateAccountOutput> outputs = CreateAccountAction.createAccount(inputs);
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        CreateAccountAction.CreateAccountOutput output = outputs[0];
        System.assertEquals(false, output.isSuccess);
        System.assert(output.errorMessage.contains('not allowed'), output.errorMessage);
    }

    @IsTest
    static void testCreateAccountInvalidJson() {
        CreateAccountAction.CreateAccountInput input = new CreateAccountAction.CreateAccountInput();
        input.fieldValuesJson = 'not valid json';

        List<CreateAccountAction.CreateAccountInput> inputs = new List<CreateAccountAction.CreateAccountInput>{ input };

        Test.startTest();
        List<CreateAccountAction.CreateAccountOutput> outputs = CreateAccountAction.createAccount(inputs);
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        CreateAccountAction.CreateAccountOutput output = outputs[0];
        System.assertEquals(false, output.isSuccess);
        System.assert(output.errorMessage.contains('Invalid JSON'), output.errorMessage);
    }

    @IsTest
    static void testCreateAccountEmptyJson() {
        CreateAccountAction.CreateAccountInput input = new CreateAccountAction.CreateAccountInput();
        input.fieldValuesJson = '';

        List<CreateAccountAction.CreateAccountInput> inputs = new List<CreateAccountAction.CreateAccountInput>{ input };

        Test.startTest();
        List<CreateAccountAction.CreateAccountOutput> outputs = CreateAccountAction.createAccount(inputs);
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        CreateAccountAction.CreateAccountOutput output = outputs[0];
        System.assertEquals(false, output.isSuccess);
        System.assert(output.errorMessage.contains('required'), output.errorMessage);
    }

    @IsTest
    static void testCreateMultipleAccounts() {
        CreateAccountAction.CreateAccountInput input1 = new CreateAccountAction.CreateAccountInput();
        input1.fieldValuesJson = '{"Name":"Account Alpha"}';

        CreateAccountAction.CreateAccountInput input2 = new CreateAccountAction.CreateAccountInput();
        input2.fieldValuesJson = '{"Name":"Account Beta","BillingCity":"Austin","BillingState":"TX"}';

        List<CreateAccountAction.CreateAccountInput> inputs = new List<CreateAccountAction.CreateAccountInput>{ input1, input2 };

        Test.startTest();
        List<CreateAccountAction.CreateAccountOutput> outputs = CreateAccountAction.createAccount(inputs);
        Test.stopTest();

        System.assertEquals(2, outputs.size());
        for (CreateAccountAction.CreateAccountOutput output : outputs) {
            System.assertEquals(true, output.isSuccess, output.errorMessage);
            System.assertNotEquals(null, output.recordId);
        }
    }
}
