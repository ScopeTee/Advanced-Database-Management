# Portfolio 3: Transactions and Concurrency

## Expected Evidence

Transaction examples showing commit, rollback, isolation, concurrency issue or control mechanism, and screenshots/output evidence.

## Implementation

This portfolio enforces the business rules that Portfolio 1's CHECK constraints could not, and demonstrates transactions, concurrency control and isolation levels on the Crestfield University database.

| File | Purpose |
|---|---|
| `01_triggers.sql` | Five PL/pgSQL triggers for business rules that need logic across rows or tables |
| `02_transaction_demos.sql` | COMMIT, ROLLBACK, automatic rollback after an error, and tests of each trigger rule |
| `03_concurrency_demo.sql` | A two-session race condition, the row-locking fix, and a comparison of isolation levels |
| `screenshots/` | Output from running the demos in pgAdmin |

**Tools used:** PostgreSQL 18, pgAdmin 4. Two Query Tool tabs were used as two concurrent database sessions.

### Triggers

| Trigger | Rule enforced | Fixes Portfolio 1 limitation |
|---|---|---|
| `result_set_grade` | `grade_id` is always calculated from CA + exam using `grade_scale` | A grade could disagree with the score |
| `result_audit_change` | Only the lecturer assigned to the course may change a result. Every change is written to `grade_change_log` with old and new scores, user, time and reason | Audit log was not filled automatically |
| `registration_unit_limit` | A maximum of 24 credit units per student per semester. Uses `SELECT … FOR UPDATE` on the student's row to prevent race conditions | 24-unit rule not enforced |
| `registration_carry_over` | A second attempt is only allowed after a failed (F) first attempt | Attempt 2 possible without a failed attempt 1 |
| `student_level_check` | `current_level` cannot exceed the programme's `maximum_level` | Level not validated against the programme |

The application identifies the user for each transaction with `set_config('app.user_id', …, TRUE)`. The audit trigger reads this setting to check who is making the change.

## How to Run / Test

1. Make sure Portfolios 1 and 2 have been run on `crestfield_university`.
2. Run `01_triggers.sql` once (F5).
3. Open `02_transaction_demos.sql` and run **one block at a time**, using the helper query at the top to check the effect of each demo.
4. For `03_concurrency_demo.sql`, open **two Query Tool tabs** (Tab A and Tab B) and follow the labelled steps in order.
5. If a step fails inside a transaction, run `ROLLBACK;` in that tab before continuing.

## Results and Evidence

**Triggers and transactions**

| Screenshot | Demo | Result |
|---|---|---|
| `01-triggers-created.png` | Install triggers | All triggers created successfully |
| `02-demo1-commit.png` | Demo 1: COMMIT | Lecturer John Adeyemi (user 2) changed CA from 15 to 18. The change and its audit-log entry, with reason "CA re-marked after script review", were saved together |
| `04-demo2-after-rollback.png` | Demo 2: ROLLBACK | An exam score change from 20 to 40 was rolled back |
| `05-demo3-auto-rollback-error.png` | Demo 3: automatic rollback | The second insert (attempt 5) failed with `chk_attempt_number`, so the whole transaction was rolled back |
| `06-demo4a-wrong-lecturer.png` | Demo 4a | "Grade change rejected: user 4 is not the lecturer assigned to this course" |
| `07-demo4b-no-user.png` | Demo 4b | "Grade change rejected: no user identified" |
| `08-demo4c-carry-over-rule.png` | Demo 4c | "Registration rejected: a second attempt requires a failed (F) first attempt" |
| `09-demo4d-level-limit.png` | Demo 4d | "Level 500 exceeds the programme maximum of 400" |
| `10-demo5-grade-corrected.png` | Demo 5: setting grade A on a total of 38 | Accepted as `UPDATE 1`, but the trigger recalculated the grade |
| `10b-helper-after-demos.png` | Check after the demos | CA 18, exam 20, total 38, **F**, **1** audit entry. Demo 1 was saved, Demo 2's rollback also removed its audit entry, and Demo 5's grade A was corrected to F |

**Concurrency and isolation**

| Screenshot | Step | Result |
|---|---|---|
| `11-partA-race-27-units.png` *(to be added)* | Part A: no lock | Both sessions registered a 3-unit course while the student had 21 units, giving **27 units**: the 24-unit rule was broken |
| `12-partB-tabB-waiting.png` | Part B: with `FOR UPDATE` | Tab B's registration **waited** ("Waiting for the query to complete… 00:00:21") while Tab A held the lock on the student's row |
| `13-partB-tabB-rejected.png` | Part B: after Tab A commits | Tab B was rejected: "Registration rejected: 24 units already registered, adding 3 would exceed the 24-unit limit" |
| `13b-partB-24-units.png` | Part B: final check | 24 units, 8 courses: the rule held |
| `14-partC-read-committed.png` *(to be added)* | Part C: READ COMMITTED | Tab A read two different exam scores in one transaction (non-repeatable read) |
| `15-partC-repeatable-read.png` *(to be added)* | Part C: REPEATABLE READ | Tab A read the same score both times, despite Tab B's committed change |

## Notes / Analysis

> _To be completed._
