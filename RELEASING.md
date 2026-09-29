# Releasing a BroadcastLabs app

Every Windows app in the suite (BroadcastMate, Logger, Sync, DeDuper, Trimmer,
Phone, SMS, VerifyAI and Drop) is built, tested, packaged and published by GitHub Actions. A
release is one button:

> **App repository > Actions > Build and release > Run workflow**
> enter the **version** (e.g. `1.0.1`), optional **release notes**, tick
> **critical** only for an update every station must install, then **Run workflow**.

About 10 to 15 minutes later:

1. The version is set in every file the app keeps it in, committed to `main`
   as *Release v1.0.1*, and tagged `v1.0.1`.
2. The app is built on Windows, its tests run, the installer is made (and
   signed, once code signing is set up), installed silently, started, and
   uninstalled again as a smoke test.
3. The installer is published:
   - as a release in the app's own (private) repository;
   - here, as `<App>-v1.0.1`, and in the permanent `<App>-latest` release that
     the website's download buttons point at.
4. The website is told, so its download shows 1.0.1 and the apps' **Check for
   Updates** starts offering it straight away.

Leave the version empty for a **test build**: the installer is kept on the
run's page (under *Artifacts*) and nothing is published.

Pushing a tag yourself (`git tag v1.0.1 && git push origin v1.0.1`) also
releases, but only if the source already says 1.0.1; otherwise the run stops
before building, because the app would report the old version and keep
offering itself as an update.

## One-time setup

Two secrets on each app repository make this work. GitHub's free plan
doesn't give organisation secrets to private repositories, so each repository
needs its own copy; `tools/Set-ReleaseSecrets.ps1` sets them all at once.

1. **Website key.** On the website: *Admin > Settings > Update service >
   Release notices > Generate a key*. Leave the page open; the key is shown once.
2. **Run the script** on your computer (it needs the GitHub CLI:
   `winget install --id GitHub.cli`):

   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\Set-ReleaseSecrets.ps1
   ```

   It opens GitHub's page for a new fine-grained token, already filled in as
   far as GitHub allows. Check:

   | Setting | Value |
   |---|---|
   | Resource owner | BroadcastLabsAU |
   | Expiration | 366 days |
   | Repository access | Only select repositories: BroadcastLabs-Releases |
   | Repository permissions | Contents: Read and write |

   Paste the token when asked, then the website key. The script checks the
   token can really publish here (it makes and deletes a draft release), then
   sets `RELEASES_TOKEN` and `RELEASE_WEBHOOK_SECRET` on every app repository.
   Nothing you paste is displayed or saved anywhere else.

If the organisation requires approval for fine-grained tokens, approve the
request under *BroadcastLabsAU > Settings > Personal access tokens > Pending
requests* before running a release.

## Keeping it working

- **The token expires** after a year. Every release run checks it first and
  warns 30 days ahead; after it expires releases stop with a clear message.
  Make a new token and run `Set-ReleaseSecrets.ps1 -SkipWebhook`.
- **New website key** (e.g. after it was shared by mistake): generate a new
  one on the website, then run `Set-ReleaseSecrets.ps1 -SkipToken`.
- **A new app**: add its repository to the list at the top of
  `Set-ReleaseSecrets.ps1` (or pass `-Repos NewApp`), give its workflow the two
  shared steps below, and add it to the website's software products.

## How the workflows use this repository

The shared steps live here, so fixing them once fixes every app:

| Step | What it does |
|---|---|
| `.github/actions/prepare` | Works out the version (test build, Run workflow, or tag), checks `RELEASES_TOKEN` before anything else, and for Run workflow sets the version (`tools/Version.ps1`), commits and tags. |
| `.github/actions/publish` | Publishes to the app repository and here (`<App>-vX.Y.Z` and `<App>-latest`), then sends the website a signed release notice. |

Each app's workflow names the files that hold its version in `VERSION_FILES`
(the first is the source of truth), for example
`CMakeLists.txt;resources/win/BroadcastPhone.rc`. A .NET project file
(`*.csproj`) is supported too: only its `<Version>` element is changed.

A repository that builds two apps (BroadcastDrop and BroadcastDrop Studio)
calls the publish step once per app, each with its own `dist` folder and
website product key; both share the one version and tag.

The website notice is a POST to `/api/releases`, signed with HMAC-SHA256 over
`<timestamp>.<body>` using the website key. The website refuses notices more
than 15 minutes old, for unknown products, for installers not hosted here, and
for a version older than the current release.

## When something goes wrong

| Message on the run | What to do |
|---|---|
| *RELEASES_TOKEN isn't set on this repository* | Run `Set-ReleaseSecrets.ps1`. |
| *GitHub refused RELEASES_TOKEN* / *expired* | Make a new token; `Set-ReleaseSecrets.ps1 -SkipWebhook`. |
| *v1.0.1 already exists* | That version is out. Release a higher one. |
| *Tag v…, but … says …* | Delete the tag, then release with Run workflow and that version. |
| *Couldn't create … on BroadcastLabs-Releases* | The token lacks *Contents: Read and write* on this repository, or awaits approval. |
| *the website didn't accept the release notice* | The installer is out; set the download's version in *Admin > Downloads*. Check the website key matches (generate a new one and run the script with `-SkipToken`). |
| *RELEASE_WEBHOOK_SECRET isn't set* | Same as above, or run the script to automate it. |
| Tests or the smoke test failed | Nothing was published. The failing lines are shown as annotations on the run. |
