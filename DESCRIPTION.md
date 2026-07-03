This branch caches direct property-drawer lookups and property access within those drawers.

Before this change, hot paths repeatedly:

- searched a headline subtree for its direct property drawer
- searched that drawer again for each requested property

On a large Org file, that turns common operations like `org-todoist--get-prop` and `org-todoist--add-all-properties` into a large amount of repeated tree walking.

What changes:

- Adds a headline-to-drawer cache.
- Adds a drawer-to-property-map cache.
- Adds a sentinel for headlines with no direct property drawer, so misses are cached too.
- Rewrites property reads, writes, and removals to go through the cached property index.

Measured performance contribution:

- This was one of the major response-path wins on the live workload.
- In the later live trace set after the related lookup cleanup was in place, `org-todoist--get-prop` dropped to about `1.677s` on the profiled run.
- The property cache works especially well together with the default-section and AST-lookup improvements, because all of those hot paths rely on repeated property access.
