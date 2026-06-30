/**
 * AccountServiceTest
 * -----------------------------------------------------------------------------
 * Demonstrates the payoff of the factory: every test below sets up exactly the
 * data it needs in one or two lines, at single-record AND bulk scale, and
 * asserts on BEHAVIOUR (the resulting Rating) rather than just touching lines
 * for coverage.
 */
@IsTest
private class AccountServiceTest {

    @IsTest
    static void hotWhenThreeOrMoreOpps() {
        TestDataFactory.Hierarchy h = TestDataFactory.insertAccountWithChildren(0, 3);

        Test.startTest();
        List<Account> result = AccountService.applyRatings(
            new Map<Id, Integer>{ h.account.Id => 3 }
        );
        Test.stopTest();

        System.assertEquals(1, result.size(), 'One account should be processed');
        System.assertEquals('Hot', result[0].Rating, 'Three opps should rate Hot');
    }

    @IsTest
    static void warmWhenOneOrTwoOpps() {
        Account acct = TestDataFactory.insertAccounts(1)[0];

        Test.startTest();
        List<Account> result = AccountService.applyRatings(
            new Map<Id, Integer>{ acct.Id => 1 }
        );
        Test.stopTest();

        System.assertEquals('Warm', result[0].Rating, 'One opp should rate Warm');
    }

    @IsTest
    static void coldWhenNoOpps() {
        Account acct = TestDataFactory.insertAccounts(1)[0];

        Test.startTest();
        List<Account> result = AccountService.applyRatings(
            new Map<Id, Integer>{ acct.Id => 0 }
        );
        Test.stopTest();

        System.assertEquals('Cold', result[0].Rating, 'Zero opps should rate Cold');
    }

    /** The case naked test classes always skip: does it hold at bulk scale? */
    @IsTest
    static void bulkScaleTwoHundredAccounts() {
        List<Account> accounts = TestDataFactory.insertAccounts(200);
        Map<Id, Integer> counts = new Map<Id, Integer>();
        for (Integer i = 0; i < accounts.size(); i++) {
            counts.put(accounts[i].Id, Math.mod(i, 5)); // mix of Hot/Warm/Cold
        }

        Test.startTest();
        List<Account> result = AccountService.applyRatings(counts);
        Test.stopTest();

        System.assertEquals(200, result.size(), 'All 200 accounts should process in one transaction');
    }

    @IsTest
    static void emptyInputReturnsEmptyList() {
        Test.startTest();
        List<Account> result = AccountService.applyRatings(new Map<Id, Integer>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Empty input should short-circuit cleanly');
    }
}
