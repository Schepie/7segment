# Versioning Rule

## Always bump the version when editing `index.html`

Whenever `index.html` is modified, you **must** increment the patch version number in **both** of these files before finishing:

1. **`index.html`** — update `CURRENT_APP_VERSION`:
   ```js
   const CURRENT_APP_VERSION = '1.x.y';
   ```

2. **`version.json`** — update `version` and `notes`:
   ```json
   {
     "version": "1.x.y",
     "buildTime": "<ISO timestamp of change>",
     "notes": "<short description of what changed>"
   }
   ```

### Version format
Use **semver patch bumps** (`1.4.7` -> `1.4.8`) for regular changes.  
Use a **minor bump** (`1.4.x` -> `1.5.0`) only for significant new features.

Both files must always be **in sync** -- the same version string in both.
