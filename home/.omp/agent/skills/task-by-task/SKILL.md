---
name: task-by-task
description: Use when the user requests splitting implementation work into reviewable subtasks or JJ changes, implementing and reviewing one task at a time. Governs the agreed sequence and subsequent review fixes; do not impose it on every large request.
---

# Task by Task

## Agree on the breakdown

Before implementation, propose an ordered, numbered list of coherent, reviewable tasks. Include each task's scope, exclusions, targeted verification, and proposed `jj describe` title. Track the total task count.

- Put all planned documentation and changelog changes in a dedicated task before the final aggregate review. Do not include planned documentation changes in other tasks; documentation corrections required by review findings belong with those fixes.
- Put bulk testing in a dedicated task after the relevant behavior exists. Other implementation tasks get only minimal focused tests and smoke verification. Fix existing tests broken by a task in that same task rather than deferring them.
- Split by meaningful outcomes, not arbitrary file boundaries or scaffolding-only stages.
- Make the final numbered task a code review of the total changes in aggregate, not just the latest task's diff. Record the starting revision before implementation so the review covers the full task sequence. Follow the `code-review` skill, address all findings in the final task's change, and reverify affected behavior before declaring the task complete.
- Wait for agreement on the breakdown and authorization to begin. Agreement on a plan alone is not an instruction to implement it.
- If a discovery materially changes the breakdown, propose the adjustment before expanding scope. Update task numbering and the total explicitly when the plan changes.

## Complete one task

1. Implement only the current agreed task and perform its targeted verification.
2. Run `jj describe` on the current change with a description reflecting that task. Invoking this implementation workflow authorizes this command for task completion and review fixes; discussing the skill or planning alone does not.
3. Give the handoff below, then stop for user review. Do not start the next task automatically.

## Review and continuation

- Address review feedback in the same current change. Reverify affected behavior and update its description if the scope materially changes.
- The user decides when review is complete and authorizes continuation. Do not start the next task automatically or infer authorization merely from completion of review fixes.
- Before implementing the next task, inspect JJ state read-only and ensure the current change is different from the just-finished task's change and has an empty diff. Record the completed task's change ID at handoff so this comparison is explicit.
- If still on the just-finished task's change, run `jj new` to create an empty child change before proceeding. Authorization to continue to the next task authorizes this command; discussing the skill, planning, or addressing review feedback does not.
- If already on a different empty change, use it. If the different change is nonempty, stop and ask how to handle its existing work; do not mix it into the next task or move it automatically.
- Keep the agreed sequence and current task clear across review turns. Do not mark a task complete while required work or verification remains blocked.

## Per-task handoff

Use this short format after completing a task:

**Completed task N/T — Task title**
**Changed:** Brief description of what was implemented.
**Verification:** Checks performed and their results or limits.
**Unexpected:** Unexpected findings or deviations, or “None.”
**Next: Task M/T — Next task title.** Waiting for your review and authorization to continue.

Here, N is the completed task number, M is the next task number, and T is the total number of tasks. After the final task, replace the next-task line with:

**Next:** None — all T/T tasks complete. Waiting for your review.

For review fixes, identify the same task N/T and summarize the fixes and verification; do not imply advancement to another task. If blocked, label the handoff as blocked rather than completed and name the missing prerequisite.
