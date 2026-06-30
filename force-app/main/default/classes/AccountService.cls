/**
 * AccountService
 * -----------------------------------------------------------------------------
 * A small, realistic service-layer class. It exists so the repo can demonstrate
 * the Test Data Factory testing REAL behaviour, not just exercising the factory
 * itself. The logic here is deliberately simple but representative: bulkified,
 * FLS-aware, and side-effect free where possible.
 */
public with sharing class AccountService {

    /**
     * Recalculate a rating on each Account based on the number of related
     * Opportunities passed alongside it. Pure-ish: mutates the supplied list,
     * returns it, performs the DML once.
     */
    public static List<Account> applyRatings(Map<Id, Integer> oppCountByAccountId) {
        if (oppCountByAccountId == null || oppCountByAccountId.isEmpty()) {
            return new List<Account>();
        }

        List<Account> toUpdate = [
            SELECT Id, Rating
            FROM Account
            WHERE Id IN :oppCountByAccountId.keySet()
            WITH USER_MODE
        ];

        for (Account a : toUpdate) {
            Integer count = oppCountByAccountId.get(a.Id);
            a.Rating = count >= 3 ? 'Hot' : (count >= 1 ? 'Warm' : 'Cold');
        }

        update toUpdate;
        return toUpdate;
    }
}
