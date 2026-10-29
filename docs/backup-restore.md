# Concern data backup and restore (Windows / XAMPP)

This repository includes a PowerShell backup script at
[`scripts/backup/Backup-ConcernManagement.ps1`](../scripts/backup/Backup-ConcernManagement.ps1).
It saves a complete MariaDB dump plus concern-upload files into a timestamped
folder. It does not back up profile photos, source code, or `.env` files. Keep
those separately if you need a full application recovery.

## What the backup contains

Each successful run creates a folder such as:

```text
E:\ConcernManagementBackups\concern-management_20261028_020000\
  concern_management.sql
  backup-info.txt
  uploads\concerns\...
```

The `uploads\concerns` directory shown here is a **backup copy** stored beside
the SQL dump. The original uploads remain in the app's configured uploads
directory. Do not set `BackupRoot` to the original concern uploads directory or
to a folder inside it; the script blocks this to avoid recursively copying old
backups into new backups.

The SQL dump includes all tables in the configured database, not just concerns.
That preserves the related users, organizations, comments, status history, and
attachment records needed to restore concern data. The uploads folder contains
the concern image files referenced by those records.

The script removes only its own timestamp-named backup folders older than the
configured retention period (14 days by default). Keep `BackupRoot` on a separate
drive or network backup location, not inside the application folder or on the
same VM disk. If using a network share, ensure the Windows Task Scheduler account
has access to it.

Backups include personal and operational data. Restrict access to the backup
location and use encrypted storage or an encrypted remote backup destination.
The script does not encrypt the dump itself.

## 1. Find the paths for this deployment

- Project root: the folder containing `package.json`.
- MariaDB dump executable: commonly `C:\xampp\mysql\bin\mysqldump.exe`.
- Database name: read `DB_NAME` from the deployment's `.env` (commonly
  `concern_management`).
- Concern images: `data\uploads\concerns` under the project root by default.
  If `.env` sets `CONCERN_UPLOAD_DIR` to another path, use that actual path
  instead.
- Backup root: choose an external drive or remote share, for example
  `E:\ConcernManagementBackups`. The script requires this path to be outside the
  project folder.

The upload directory can be passed explicitly with `-ConcernUploadsDirectory`.
Relative paths supplied for it are resolved from the project root. Other paths
in the Task Scheduler command should be absolute.

## 2. Create a protected MariaDB client options file

The script does not put the database password on the command line. Create a
private options file for the Windows account that will run the scheduled task,
for example:

`%APPDATA%\ConcernManagement\backup-client.cnf`

Create the `ConcernManagement` folder first. Put the MariaDB backup account and
connection details in the file using this format (replace the placeholders):

```ini
[client]
user=backup_user
password="replace-with-the-database-password"
host=127.0.0.1
port=3306
```

Do not commit this file or put it under the web application's `public` folder.
Restrict access to your Windows account and SYSTEM. In PowerShell, after creating
the file, run:

```powershell
icacls "$env:APPDATA\ConcernManagement\backup-client.cnf" /inheritance:r /grant:r "$($env:USERNAME):(R,W)" "SYSTEM:(F)"
```

Use a database account with only the permissions needed to dump this database;
avoid using the MariaDB `root` account for a recurring production task where
possible. The same Windows account must own/read this options file when the
scheduled task runs.

## 3. Run a manual test

Open PowerShell as the Windows account that will own the scheduled task. Adjust
all paths and the database name for the VM, then run:

```powershell
.\scripts\backup\Backup-ConcernManagement.ps1 `
  -BackupRoot 'E:\ConcernManagementBackups' `
  -ClientOptionsFile "$env:APPDATA\ConcernManagement\backup-client.cnf" `
  -DumpExecutable 'C:\xampp\mysql\bin\mysqldump.exe' `
  -DatabaseName 'concern_management' `
  -ConcernUploadsDirectory 'C:\path\to\app\data\uploads\concerns' `
  -RetentionDays 14
```

`-ConcernUploadsDirectory` is optional when the app uses the default
`data\uploads\concerns` directory and the script resides in the project. Omit
that line in that case. If the run succeeds, check that the dated folder contains
a non-empty `.sql` file, `backup-info.txt`, and the expected images. Run a backup
manually before scheduling it, and again before database migrations or app
upgrades.

## 4. Schedule it daily at 2:00 AM

In **Windows Task Scheduler**:

1. Choose **Create Task** (not just a one-time task), name it `Concern Management Backup`, and add a daily trigger for 2:00 AM or another low-usage time.
2. Set the task to run as the same Windows account used for the options file. If it writes to a network share, grant that account share and folder permissions.
3. Set the action's program to `powershell.exe`.
4. Set arguments to the following, changing paths to match this server:

```text
-NoProfile -ExecutionPolicy Bypass -File "C:\path\to\app\scripts\backup\Backup-ConcernManagement.ps1" -BackupRoot "E:\ConcernManagementBackups" -ClientOptionsFile "%APPDATA%\ConcernManagement\backup-client.cnf" -DumpExecutable "C:\xampp\mysql\bin\mysqldump.exe" -DatabaseName "concern_management" -RetentionDays 14
```

Task Scheduler does not reliably expand `%APPDATA%` inside every argument field.
For best results, replace it in the arguments with the full absolute path, such as
`C:\Users\backup-runner\AppData\Roaming\ConcernManagement\backup-client.cnf`.
If the upload directory is not the default, add
`-ConcernUploadsDirectory "D:\AppData\ConcernManagement\concerns"` to the
arguments.

5. Select **Run whether user is logged on or not** if appropriate for your
   environment, save the task, and enter the Windows account password directly
   into Task Scheduler when prompted. Never place that password in the script.
6. Right-click the task and choose **Run**. Confirm that a new timestamped backup
   folder appears and that **Last Run Result** is `0x0`.

Run the task as the same account used for the manual test. Keep an eye on the
backup drive's free space. Retention removes old local backup folders; it is not
a replacement for a second copy stored on a different device or protected remote
storage.

## 5. Restore and verify

A `.sql` dump is a recovery file; MariaDB does not query it directly. Keep the
matching `uploads\concerns` folder from the same timestamped backup.

1. Choose a backup and **restore into a new, empty test database first**. In
   phpMyAdmin, create an empty database (for example, `concern_management_restore`),
   open it, use **Import**, and select that backup's `.sql` file. Alternatively,
   use the MariaDB `mysql.exe` client and import the SQL into the empty database.
2. Point a test copy of the app to the restored database. Copy that backup's
   `uploads\concerns` contents to the test app's configured concern upload
   directory, or set `CONCERN_UPLOAD_DIR` to the restored files' location.
3. Verify that concerns, comments, history, and images can be opened. Check the
   server logs for missing-file or database errors.
4. Only after a successful test, plan production recovery. Stop app writes while
   restoring the database and matching uploads together, then verify the app
   before reopening it to users. Preserve the failed database and files until
   recovery is confirmed.

Do not test a restore over the live database. A database dump and file copy are
not a single atomic snapshot; schedule backups during low usage, and avoid
updates or migrations while the backup is running.
