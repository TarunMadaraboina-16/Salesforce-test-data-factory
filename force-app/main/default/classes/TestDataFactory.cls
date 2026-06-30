/**
 * TestDataFactory
 * -----------------------------------------------------------------------------
 * A single, reusable source of test records for an entire Salesforce org.
 *
 * Design principles:
 *   1. Bulk-first  — every builder returns a List and accepts a count, so the
 *                    same method seeds 1 record or 200 with no extra code.
 *   2. Caller owns DML — builders return records WITHOUT inserting by default
 *                    (the *create* methods). Use the *insert* variants when you
 *                    want them committed. This lets a test stage records, tweak
 *                    a field, then insert once — avoiding redundant DML.
 *   3. Sensible defaults, easy overrides — every record comes back valid and
 *                    required-field-complete. Override anything via the
 *                    overrides Map without rewriting the builder.
 *
 * Marked @IsTest so it never counts against org code size and can only be
 * referenced from test context.
 */
@IsTest
public class TestDataFactory {

    // ---------------------------------------------------------------------
    // ACCOUNTS
    // ---------------------------------------------------------------------

    /** Build N Accounts in memory (no DML). */
    public static List<Account> createAccounts(Integer count) {
        return createAccounts(count, new Map<String, Object>());
    }

    /** Build N Accounts in memory with field overrides applied to each. */
    public static List<Account> createAccounts(Integer count, Map<String, Object> overrides) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            Account a = new Account(
                Name = 'Test Account ' + i,
                BillingCity = 'Trenton',
                BillingState = 'NJ',
                BillingCountry = 'USA'
            );
            applyOverrides(a, overrides);
            accounts.add(a);
        }
        return accounts;
    }

    /** Build, insert, and return N Accounts. */
    public static List<Account> insertAccounts(Integer count) {
        return insertAccounts(count, new Map<String, Object>());
    }

    public static List<Account> insertAccounts(Integer count, Map<String, Object> overrides) {
        List<Account> accounts = createAccounts(count, overrides);
        insert accounts;
        return accounts;
    }

    // ---------------------------------------------------------------------
    // CONTACTS
    // ---------------------------------------------------------------------

    /** Build N Contacts in memory, optionally parented to an Account. */
    public static List<Contact> createContacts(Integer count, Id accountId) {
        return createContacts(count, accountId, new Map<String, Object>());
    }

    public static List<Contact> createContacts(Integer count, Id accountId, Map<String, Object> overrides) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            Contact c = new Contact(
                FirstName = 'Test',
                LastName  = 'Contact ' + i,
                Email     = 'test.contact' + i + '@example.invalid',
                AccountId = accountId
            );
            applyOverrides(c, overrides);
            contacts.add(c);
        }
        return contacts;
    }

    public static List<Contact> insertContacts(Integer count, Id accountId) {
        return insertContacts(count, accountId, new Map<String, Object>());
    }

    public static List<Contact> insertContacts(Integer count, Id accountId, Map<String, Object> overrides) {
        List<Contact> contacts = createContacts(count, accountId, overrides);
        insert contacts;
        return contacts;
    }

    // ---------------------------------------------------------------------
    // OPPORTUNITIES
    // ---------------------------------------------------------------------

    public static List<Opportunity> createOpportunities(Integer count, Id accountId) {
        return createOpportunities(count, accountId, new Map<String, Object>());
    }

    public static List<Opportunity> createOpportunities(Integer count, Id accountId, Map<String, Object> overrides) {
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < count; i++) {
            Opportunity o = new Opportunity(
                Name      = 'Test Opp ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount    = 1000,
                AccountId = accountId
            );
            applyOverrides(o, overrides);
            opps.add(o);
        }
        return opps;
    }

    public static List<Opportunity> insertOpportunities(Integer count, Id accountId) {
        return insertOpportunities(count, accountId, new Map<String, Object>());
    }

    public static List<Opportunity> insertOpportunities(Integer count, Id accountId, Map<String, Object> overrides) {
        List<Opportunity> opps = createOpportunities(count, accountId, overrides);
        insert opps;
        return opps;
    }

    // ---------------------------------------------------------------------
    // CONVENIENCE GRAPHS
    // ---------------------------------------------------------------------

    /**
     * Build a complete Account -> Contacts -> Opportunities graph in one call
     * and return it as a typed wrapper. Useful when a test needs a realistic,
     * related data set rather than isolated records.
     */
    public static Hierarchy insertAccountWithChildren(Integer contactCount, Integer oppCount) {
        Account acct = insertAccounts(1)[0];
        Hierarchy h = new Hierarchy();
        h.account = acct;
        h.contacts = insertContacts(contactCount, acct.Id);
        h.opportunities = insertOpportunities(oppCount, acct.Id);
        return h;
    }

    public class Hierarchy {
        public Account account;
        public List<Contact> contacts;
        public List<Opportunity> opportunities;
    }

    // ---------------------------------------------------------------------
    // INTERNAL
    // ---------------------------------------------------------------------

    /**
     * Apply a field-name -> value Map onto an SObject. Centralised so every
     * builder gets the same override behaviour and bad field names fail loudly
     * in the test rather than silently doing nothing.
     */
    private static void applyOverrides(SObject record, Map<String, Object> overrides) {
        if (overrides == null || overrides.isEmpty()) {
            return;
        }
        for (String field : overrides.keySet()) {
            record.put(field, overrides.get(field));
        }
    }
}
