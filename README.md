# Salesforce Test Data Factory + CI/CD Pipeline

A production-grade **Test Data Factory** pattern for Apex, wired to a **GitHub Actions**
pipeline that creates a scratch org, deploys the source, and runs every Apex test
with coverage on each push.

The point of this repo is to demonstrate two things most Salesforce teams still do
the hard way:

1. **Test data that scales.** No more building the same `Account` 47 different ways
   across 30 test classes. One factory, called in a line or two, at single-record or
   bulk scale.
2. **Deployment that isn't a human clicking buttons.** A push to `main` triggers a
   real org deploy and a real test run. A green check means it works in an org — not
   just on a laptop.

---

## Why a Test Data Factory

The anti-pattern it replaces: every test class hand-rolls its own records. When a
validation rule or required field changes, you edit dozens of test classes. Coverage
looks fine; maintenance is a tax you pay forever.

The factory centralises record creation behind a tiny, predictable API:

```apex
// One valid Account, inserted:
Account a = TestDataFactory.insertAccounts(1)[0];

// 200 Accounts for a bulk test, in memory (you insert when ready):
List<Account> accounts = TestDataFactory.createAccounts(200);

// Override only what your test cares about:
List<Account> hot = TestDataFactory.createAccounts(
    3,
    new Map<String, Object>{ 'Rating' => 'Hot', 'BillingState' => 'CA' }
);

// A full related graph in one call:
TestDataFactory.Hierarchy h = TestDataFactory.insertAccountWithChildren(2, 4);
// h.account, h.contacts (2), h.opportunities (4)
```

### Design decisions worth calling out

- **Bulk-first.** Every builder takes a count, so the same method seeds 1 or 200
  records. This is what makes writing real bulk tests (the 200-record case naked test
  classes always skip) a one-liner.
- **Caller owns DML.** `create*` methods return records *without* inserting; `insert*`
  methods commit. A test can stage records, tweak one field, then insert once —
  instead of insert-then-update churn.
- **Overrides fail loudly.** Overrides go through `SObject.put()`, so a typo in a field
  name throws in the test rather than silently doing nothing.
- **`@IsTest` on the factory.** It never counts against org code size and can only be
  called from test context.

---

## What's in here

```
force-app/main/default/classes/
  TestDataFactory.cls        # the factory
  TestDataFactoryTest.cls    # the factory is code, so it's tested too
  AccountService.cls         # a small, realistic service class...
  AccountServiceTest.cls     # ...tested for BEHAVIOUR using the factory
.github/workflows/ci.yml     # the pipeline
config/project-scratch-def.json
sfdx-project.json
```

`AccountServiceTest` is the part to read if you want to see the payoff: each test
sets up exactly the data it needs in one or two lines and asserts on the resulting
behaviour (the computed `Rating`), including a 200-record bulk case — not just lines
touched for the 75% requirement.

---

## The CI pipeline

`.github/workflows/ci.yml` runs on every push and pull request to `main`:

1. Install the Salesforce CLI
2. Authenticate to a Dev Hub (via the `SFDX_AUTH_URL` repo secret)
3. Create a fresh scratch org
4. Deploy the source
5. Run **all local Apex tests** with code coverage
6. Tear the scratch org down (always, even on failure)

### Setup (one time)

You need a Dev Hub org. Then:

```bash
# Authorise your Dev Hub locally and grab its auth URL:
sf org login web --set-default-dev-hub --alias devhub
sf org display --verbose --json -o devhub
# Copy the value of result.sfdxAuthUrl
```

Add that value as a GitHub repo secret named `SFDX_AUTH_URL`
(*Settings → Secrets and variables → Actions → New repository secret*). The pipeline
runs on the next push.

### Run it locally

```bash
sf org create scratch -f config/project-scratch-def.json -a scratch -d 1 -y 1 --set-default
sf project deploy start
sf apex run test --code-coverage --result-format human --test-level RunLocalTests
```

---

## A note on Copado

In my enterprise work at TCS, the deployment layer was **Copado** — branch-based
pipelines, environment promotion, and compliance gating across a multi-team org.
Copado is a commercial platform, so it can't be meaningfully demonstrated in a public
repo. This repo shows the same fundamentals — source-driven development, automated
deploy, automated test enforcement on every change — using the open-source toolchain
(SF CLI + GitHub Actions) that anyone can run. The Copado equivalent layers
promotion, approvals, and back-promotion on top of exactly this foundation.

---

## License

MIT — use it, fork it, adapt it for your own org.
