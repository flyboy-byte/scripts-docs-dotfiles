# Audit — <board name>

## Hand-off (give this to each auditor with a read-only copy; not your conclusions)
- Board: <what it does>
- Commit and files: <hash>, <paths>
- Changed since last audit: <list>
- Check, in priority order: new circuits from first principles; power stages; layout of what moved;
  fab files against the board; silkscreen.
- Known and accepted (don't re-report): <list>
- Report format below.

## Report format
Verdict first: "Would I order these files as they are?"

| ID | Severity | Location | Evidence (numbers) | Smallest fix |
| --- | --- | --- | --- | --- |

Severity: BLOCKER = don't order; BUG = wrong but workable; RISK = could bite (state the condition);
NOTE. Then: what was checked and found correct, and what couldn't be checked.

## Rounds
### Round 1 — <YYYY-MM-DD>, <auditor>
<findings table, then fixes with commit>
