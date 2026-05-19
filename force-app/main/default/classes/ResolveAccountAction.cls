/**
 * @description Invocable Apex action for resolving Account from user input (ID or name)
 * @author Claude Code
 * @date 2026-05-18
 */
@JsonAccess(serializable='always' deserializable='always')
global with sharing class ResolveAccountAction {

    /**
     * @description Input parameters for the invocable action
     */
    @JsonAccess(serializable='always' deserializable='always')
    global class ResolveAccountInput {
        @InvocableVariable(label='Account Input' description='User-provided Account ID (15/18 chars) or Account Name' required=true)
        global String accountInput;
    }

    /**
     * @description Output parameters for the invocable action
     */
    @JsonAccess(serializable='always' deserializable='always')
    global class ResolveAccountOutput {
        @InvocableVariable(label='Account Id' description='Resolved Account ID (if single match)')
        global String accountId;

        @InvocableVariable(label='Account Name' description='Resolved Account Name (if single match)')
        global String accountName;

        @InvocableVariable(label='Match Count' description='Number of matching accounts found')
        global Integer matchCount;

        @InvocableVariable(label='Disambiguation Options (JSON)' description='JSON array of account options if multiple matches')
        global String disambiguationOptionsJson;

        @InvocableVariable(label='Success' description='Whether resolution succeeded')
        global Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if resolution failed')
        global String errorMessage;
    }

    /**
     * @description Account option for disambiguation
     */
    global class AccountOption {
        global String Id;
        global String Name;
    }

    /**
     * @description Resolves Account from user input (ID or name)
     * @param inputs List of input parameters
     * @return List of output results
     */
    @InvocableMethod(
        label='Resolve Account'
        description='Resolves Account from user input (ID or name with fuzzy search and disambiguation)'
        category='Agentforce Actions'
    )
    global static List<ResolveAccountOutput> resolveAccount(List<ResolveAccountInput> inputs) {
        List<ResolveAccountOutput> outputs = new List<ResolveAccountOutput>();

        for (ResolveAccountInput input : inputs) {
            ResolveAccountOutput output = new ResolveAccountOutput();
            output.isSuccess = false;
            output.matchCount = 0;

            try {
                if (String.isBlank(input.accountInput)) {
                    throw new IllegalArgumentException('Account Input is required');
                }

                String normalizedInput = input.accountInput.trim();

                // Check if input looks like a Salesforce ID (15 or 18 chars, alphanumeric)
                if (isLikelySalesforceId(normalizedInput)) {
                    // Treat as ID lookup
                    List<Account> accounts = [
                        SELECT Id, Name
                        FROM Account
                        WHERE Id = :normalizedInput
                        LIMIT 1
                    ];

                    if (accounts.isEmpty()) {
                        output.errorMessage = 'No Account found with ID: ' + normalizedInput;
                        output.matchCount = 0;
                    } else {
                        output.accountId = accounts[0].Id;
                        output.accountName = accounts[0].Name;
                        output.matchCount = 1;
                        output.isSuccess = true;
                    }
                } else {
                    // Treat as name search - use SOSL for fuzzy matching
                    String searchQuery = 'FIND \'' + String.escapeSingleQuotes(normalizedInput) + '*\' IN NAME FIELDS RETURNING Account(Id, Name ORDER BY Name LIMIT 10)';
                    List<List<SObject>> searchResults = Search.query(searchQuery);
                    List<Account> accounts = (List<Account>) searchResults[0];

                    output.matchCount = accounts.size();

                    if (accounts.isEmpty()) {
                        output.errorMessage = 'No Account found matching: ' + normalizedInput;
                    } else if (accounts.size() == 1) {
                        // Single match - resolved
                        output.accountId = accounts[0].Id;
                        output.accountName = accounts[0].Name;
                        output.isSuccess = true;
                    } else {
                        // Multiple matches - return options for disambiguation
                        List<AccountOption> options = new List<AccountOption>();
                        for (Account acc : accounts) {
                            AccountOption option = new AccountOption();
                            option.Id = acc.Id;
                            option.Name = acc.Name;
                            options.add(option);
                        }
                        output.disambiguationOptionsJson = JSON.serialize(options);
                        output.isSuccess = true; // Success = found options, agent needs to handle disambiguation
                    }
                }

            } catch (Exception e) {
                output.isSuccess = false;
                output.errorMessage = e.getMessage();
            }

            outputs.add(output);
        }

        return outputs;
    }

    /**
     * @description Checks if input looks like a Salesforce ID
     * @param input The input string
     * @return True if it looks like a Salesforce ID
     */
    private static Boolean isLikelySalesforceId(String input) {
        if (String.isBlank(input)) {
            return false;
        }

        Integer len = input.length();
        if (len != 15 && len != 18) {
            return false;
        }

        // Check if all characters are alphanumeric
        return input.isAlphanumeric();
    }
}
