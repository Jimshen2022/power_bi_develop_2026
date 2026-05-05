# AGENTS.md

## Cursor Cloud specific instructions

### Codebase Overview

This is a **Power BI Projects (PBIP) repository** — not a traditional software application. It contains 10 Power BI report/dashboard projects for warehouse and distribution center analytics. There is no runnable application, no package manager, no build system, and no CI/CD pipeline.

**File types:**
- `.json` (898 files) — Report definitions, visual configs, themes, page layouts
- `.tmdl` (205 files) — Tabular Model Definition Language files (semantic models with DAX measures, M/Power Query expressions, table definitions)
- `.platform` (20 files) — Platform metadata (JSON format)
- `.pbip` (10 files) — Project entry-point files
- `.pbir` (10 files) — Report reference files
- `.pbism` (10 files) — Semantic model reference files
- `.sql` (4 files) — Standalone SQL query files
- `.dax` (2 files) — DAX expression files
- `.png` (3 files) — Image assets

### Projects

Each top-level directory is an independent Power BI project (9 directories, 10 `.pbip` files since `MIL_PickingLocationLast_Trx_Date/` contains 2 projects).

### Lint / Validation

Since there is no traditional build or test system, validation consists of:

1. **JSON validation** — verify all `.json` files parse correctly:
   ```bash
   python3 -c "
   import json, os, sys
   errors = []
   count = 0
   for root, dirs, files in os.walk('.'):
       if '/.git/' in root or root.endswith('/.git'):
           continue
       for f in files:
           if f.endswith('.json'):
               fp = os.path.join(root, f)
               count += 1
               try:
                   with open(fp, 'r', encoding='utf-8') as fh:
                       json.load(fh)
               except Exception as e:
                   errors.append((fp, str(e)))
   print(f'Validated {count} JSON files')
   if errors:
       print(f'ERRORS in {len(errors)} files:')
       for p, e in errors:
           print(f'  {p}: {e}')
       sys.exit(1)
   else:
       print('All JSON files are valid.')
   "
   ```

2. **PBIP structure check** — verify each `.pbip` project has its `.Report/`, `.SemanticModel/`, `.pbir`, and `.pbism` counterparts.

### Data Sources (External, Not Available in Cloud Agent)

Reports connect to enterprise-internal data sources that are not accessible from the cloud agent environment:
- Azure SQL Database (`ashley-edw.database.windows.net`)
- Power Platform Dataflows
- SharePoint Online (`masterashley.sharepoint.com`)
- IBM iSeries/AS400 (`MILPROD`) — accessed indirectly via Dataflows

These connections are defined in the `.tmdl` files and cannot be tested without corporate credentials and network access.

### Key Gotchas

- **No `npm`/`pip`/etc.** — There are no package managers or dependency files. The update script is a no-op.
- **Files with spaces and special characters** — Many file and directory names contain spaces, parentheses, and Unicode characters (e.g., `–`). Always quote paths in shell commands.
- **PBIP format requires Power BI Desktop** — The `.pbip` files can only be opened/rendered in Power BI Desktop (with Developer Mode enabled). They cannot be run or previewed in a headless/CLI environment.
- **Changes to review** — When reviewing changes to this repo, focus on JSON syntax validity, TMDL/DAX expression correctness, and ensuring PBIP project structure remains intact (every project needs its `.Report/` and `.SemanticModel/` directories with the appropriate metadata files).
