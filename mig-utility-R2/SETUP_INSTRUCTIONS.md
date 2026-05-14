# E2B R2 migration utility — environment setup

This guide covers preparing the **staging Oracle schema**, running **DDL (01 → 02 → 03)**, **deploying PL/SQL packages**, and **loading E2B(R2) XML** with Python. You can use **SQL\*Plus** and/or **SQL Developer** for the database steps.

Root folder for these steps: `mig-utility-R2/` (paths below are relative to that folder unless noted).

---

## 0. Prerequisites

- Oracle **SQL\*Plus** (Instant Client or full client) on your machine if you use the shell helpers or command-line flow.
- **SQL Developer** with JDBC connectivity to the same PDB/service.
- **Python 3** with the **`oracledb`** package (`python3 -m pip install oracledb`), **or** use the vendored driver by adding `mig-utility-R2/.pydeps` to `PYTHONPATH` when running the loader.
- A database account with **SYSDBA** (or equivalent) to create users and grant on `ARGUS_APP` / `ESM_OWNER` / related objects, as required by `db/run/create_staging_schema.sql`.

---

## 1. Verify `env/.env` database settings

Edit `env/.env` and confirm every value matches the database you intend to use. The loader and helper scripts expect:

| Variable | Purpose |
|----------|---------|
| `TARGET_DB_HOST` | Database host name or IP |
| `TARGET_DB_PORT` | Listener port (often `1521`) |
| `TARGET_DB_SERVICE_NAME` | PDB or service name |
| `TARGET_DB_USER` | **Staging schema** user name (same user created by schema script) |
| `TARGET_DB_PASSWORD` | Password for that staging user |

**Important:** `TARGET_DB_USER` and `TARGET_DB_PASSWORD` must match the user you create in step 2. The Python loader connects as `TARGET_DB_USER` using `host:port/service_name`.

Do not commit real passwords; keep `env/.env` local and out of version control if your policy requires it.

---

## 2. Schema creation (connect as SYSTEM or SYS)

The script `db/run/create_staging_schema.sql` creates the staging user and applies grants. It is written to be run as **SYS** (comments say SYS; a sufficiently privileged SYSTEM user may work in some environments, but follow your DBA standard).

### Option A — SQL\*Plus (recommended; matches repo scripts)

From `mig-utility-R2/db/run`:

```bash
cd mig-utility-R2/db/run
```

**If `env/.env` is populated**, the wrapper sources it and passes user/password into the SQL script:

```bash
./create_staging_schema.sh 'sys/your_sys_password@HOST:PORT/SERVICE as sysdba'
```

On a machine where OS authentication is configured for SYS:

```bash
./create_staging_schema.sh
```

(Second form defaults to `/ as sysdba`.)

**Manual SQL\*Plus** (equivalent to what the shell script does):

```bash
cd mig-utility-R2/db/run
set -a && source ../../env/.env && set +a
sqlplus -L 'sys/password@HOST:PORT/SERVICE as sysdba' @create_staging_schema.sql "${TARGET_DB_USER}" "${TARGET_DB_PASSWORD}"
```

Log output: `db/logs/sql/create_staging_schema.LOG`.

**If the user already exists**, Oracle returns `ORA-01920`. Drop the user (only if appropriate) or skip creation and run DDL/packages only.

### Option B — SQL Developer

1. Create a connection for **SYS as SYSDBA** (or your privileged account) to the correct PDB/host/service.
2. Set the script/working directory to **`mig-utility-R2/db/run`** (so `SPOOL ../logs/sql/...` and any relative paths resolve like SQL\*Plus).
3. In a worksheet attached to that connection, run **Run Script** (F5) with one of:
   - `@create_staging_schema.sql YOUR_STAGING_USER YOUR_STAGING_PASSWORD`  
     (same order as `env/.env`: username then password), **or**
   - `@create_staging_schema.sql` and enter values when prompted for **`&1`** (staging user) and **`&2`** (staging password).

Use **Run Script**, not **Run Statement**, so the anonymous PL/SQL grant blocks execute correctly.

Create `db/logs/sql` beforehand if spool fails due to a missing directory.

---

## 3. Connect as the new staging schema

Use the same credentials as in `env/.env`:

- **Connect string pattern:** `TARGET_DB_USER` / `TARGET_DB_PASSWORD` @ `TARGET_DB_HOST` : `TARGET_DB_PORT` / `TARGET_DB_SERVICE_NAME`

**SQL\*Plus:**

```bash
sqlplus TARGET_DB_USER/TARGET_DB_PASSWORD@TARGET_DB_HOST:TARGET_DB_PORT/TARGET_DB_SERVICE_NAME
```

**SQL Developer:** create a normal connection with username = staging user, password as set, hostname/port/service from `env/.env`.

---

## 4. Table creation — run scripts **01 → 02 → 03** in order

Scripts live in `db/ddl/`:

1. `01_create_config_tables.sql` — migration/control tables  
2. `02_create_target_tables.sql` — target-side tables  
3. `03_create_source_tables.sql` — E2B(R2) **S\_\*** source tables used by `load_e2b_r2_to_src.py`

### Option A — SQL\*Plus helper (runs all three in order)

From `mig-utility-R2/db/run`, with staging credentials:

```bash
./run_ddl_tables.sh 'TARGET_DB_USER/TARGET_DB_PASSWORD@HOST:PORT/SERVICE'
```

### Option B — SQL\*Plus manual

```bash
cd mig-utility-R2/db/run
sqlplus -L 'TARGET_DB_USER/TARGET_DB_PASSWORD@HOST:PORT/SERVICE' @../ddl/01_create_config_tables.sql
sqlplus -L 'TARGET_DB_USER/TARGET_DB_PASSWORD@HOST:PORT/SERVICE' @../ddl/02_create_target_tables.sql
sqlplus -L 'TARGET_DB_USER/TARGET_DB_PASSWORD@HOST:PORT/SERVICE' @../ddl/03_create_source_tables.sql
```

Start SQL\*Plus from **`db/run`** so spool paths in the scripts resolve to `db/logs/sql/`.

### Option C — SQL Developer

Connect as the **staging user**. Run **Run Script** (F5) **in sequence**:

1. `@db/ddl/01_create_config_tables.sql`  
2. `@db/ddl/02_create_target_tables.sql`  
3. `@db/ddl/03_create_source_tables.sql`  

Use **File → Open** with absolute paths if `@` relative paths are ambiguous; keep the SQL\*Plus default path in `db/run` if you use `@../ddl/...` as above.

Logs (when spooling succeeds): `db/logs/sql/01_create_config_tables.LOG`, `02_create_target_tables.LOG`, `03_create_source_tables.LOG`.

---

## 5. Deploy packages

Packages are deployed by `db/run/deploy_packages.sql` in this order: **CLEANUP → UTIL → BUSS → MIGRATION** (spec then body for each), using files under `db/packages/`.

### Option A — SQL\*Plus helper

```bash
cd mig-utility-R2/db/run
./deploy_packages.sh 'TARGET_DB_USER/TARGET_DB_PASSWORD@HOST:PORT/SERVICE'
```

### Option B — SQL\*Plus manual

```bash
cd mig-utility-R2/db/run
sqlplus -L 'TARGET_DB_USER/TARGET_DB_PASSWORD@HOST:PORT/SERVICE' @deploy_packages.sql
```

### Option C — SQL Developer

Connect as **staging user**, **Run Script** on `db/run/deploy_packages.sql` with working directory **`db/run`** so the `@@../packages/...` includes resolve.

Log: `db/logs/sql/deploy_packages.LOG`.

The script uses `WHENEVER SQLERROR EXIT SQL.SQLCODE`; any compile error stops the script—fix errors before reloading.

---

## 6. One-shot automation (SQL\*Plus only)

If you have SYSDBA access and `env/.env` filled in:

```bash
cd mig-utility-R2/db/run
export SYSDBA_SQLPLUS_CONNECT='sys/password@HOST:PORT/SERVICE as sysdba'
./run_full_staging_deploy.sh
```

This runs: create staging user → `01`/`02`/`03` DDL → deploy packages. It does **not** run the Python XML loader.

---

## 7. Place E2B(R2) XML files for loading

The loader’s default input directory is **`input/e2b_r2_xml`** (lowercase `input`; on Linux paths are case-sensitive).

Copy your `.xml` / `.XML` files into:

`mig-utility-R2/input/e2b_r2_xml/`

If you use another folder, pass `--input-dir` when running Python (see below).

---

## 8. Run the Python script to load XML into tables

From **`mig-utility-R2`**:

```bash
cd mig-utility-R2
python3 load_e2b_r2_to_src.py
```

Defaults:

- `--input-dir` → `input/e2b_r2_xml`
- `--ddl-file` → `db/ddl/03_create_source_tables.sql` (column list for inserts)
- `--env-file` → `env/.env`

**Dry run** (parse only, no insert):

```bash
python3 load_e2b_r2_to_src.py --dry-run
```

**Custom paths:**

```bash
python3 load_e2b_r2_to_src.py --input-dir input/e2b_r2_xml --env-file env/.env --ddl-file db/ddl/03_create_source_tables.sql
```

Ensure `oracledb` is importable (pip install or `PYTHONPATH` including `.pydeps`).

---

## Quick reference — important files

| Step | Artifact |
|------|-----------|
| Env | `env/.env` |
| Create user / grants | `db/run/create_staging_schema.sql`, `create_staging_schema.sh` |
| DDL 01–03 | `db/ddl/01_create_config_tables.sql`, `02_create_target_tables.sql`, `03_create_source_tables.sql` |
| Packages | `db/run/deploy_packages.sql`, `db/packages/*.SQL` |
| XML loader | `load_e2b_r2_to_src.py` |
| XML input (default) | `input/e2b_r2_xml/` |

For deeper mapping notes, see `E2B_R2_SRC_CONTEXT.md` in the same folder.
