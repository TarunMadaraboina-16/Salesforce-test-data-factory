/**
 * TestDataFactoryTest
 * -----------------------------------------------------------------------------
 * The factory is code, so it gets tested too. These tests verify the builders
 * produce valid, insertable records and that overrides actually take effect.
 */
@IsTest
private class TestDataFactoryTest {

    @IsTest
    static void buildersReturnRequestedCount() {
        List<Account> accounts = TestDataFactory.createAccounts(5);
        System.assertEquals(5, accounts.size(), 'Should build exactly 5 accounts');
        System.assertEquals(null, accounts[0].Id, 'create* must not insert');
    }

    @IsTest
    static void insertVariantsCommitRecords() {
        List<Account> accounts = TestDataFactory.insertAccounts(3);
        for (Account a : accounts) {
            System.assertNotEquals(null, a.Id, 'insert* must commit and populate Id');
        }
    }

    @IsTest
    static void overridesAreApplied() {
        List<Account> accounts = TestDataFactory.createAccounts(
            1,
            new Map<String, Object>{ 'Name' => 'Custom Name', 'BillingState' => 'CA' }
        );
        System.assertEquals('Custom Name', accounts[0].Name);
        System.assertEquals('CA', accounts[0].BillingState);
    }

    @IsTest
    static void hierarchyWiresParentToChildren() {
        TestDataFactory.Hierarchy h = TestDataFactory.insertAccountWithChildren(2, 4);
        System.assertEquals(2, h.contacts.size());
        System.assertEquals(4, h.opportunities.size());
        System.assertEquals(h.account.Id, h.contacts[0].AccountId, 'Child should point at parent');
    }

    @IsTest
    static void contactsCanBeOrphans() {
        List<Contact> contacts = TestDataFactory.createContacts(2, null);
        System.assertEquals(2, contacts.size());
        System.assertEquals(null, contacts[0].AccountId, 'Null accountId should be allowed');
    }
}
