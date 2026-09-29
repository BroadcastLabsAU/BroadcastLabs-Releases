<#
.SYNOPSIS
    Puts the release secrets on every BroadcastLabs app repository, so the
    GitHub builds can publish installers and update the website by themselves.

.DESCRIPTION
    Run it on your own computer. Nothing you paste is shown on screen, written
    to disk or sent anywhere except GitHub's encrypted secret store.

      RELEASES_TOKEN          a fine-grained GitHub token that can write releases
                              to BroadcastLabs-Releases (the script opens the
                              page to make one, and checks it works)
      RELEASE_WEBHOOK_SECRET  the website's release key, from Admin > Settings >
                              Update service > Release notices

    GitHub's free plan doesn't give organisation secrets to private
    repositories, which is why each app repository gets its own copy.

    Needs the GitHub CLI: winget install --id GitHub.cli

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File Set-ReleaseSecrets.ps1
.EXAMPLE
    .\Set-ReleaseSecrets.ps1 -SkipToken          # only replace the website key
.EXAMPLE
    .\Set-ReleaseSecrets.ps1 -Repos BroadcastSMS  # just one repository
#>
param(
    [string[]] $Repos = @('BroadcastMate', 'BroadcastLogger', 'BroadcastSync', 'BroadcastDeDuper',
                          'BroadcastTrimmer', 'BroadcastPhone', 'BroadcastSMS'),
    [string]   $Org = 'BroadcastLabsAU',
    [string]   $ReleasesRepo = 'BroadcastLabs-Releases',
    [switch]   $SkipToken,
    [switch]   $SkipWebhook
)

$ErrorActionPreference = 'Stop'

function Read-Secret([string] $prompt) {
    $s = Read-Host -Prompt $prompt -AsSecureString
    $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b).Trim() }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }
}

function Section([string] $t) { Write-Host ''; Write-Host "== $t" -ForegroundColor Cyan }

# ---- GitHub CLI -----------------------------------------------------------
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host 'The GitHub CLI is needed. Install it with:' -ForegroundColor Yellow
    Write-Host '    winget install --id GitHub.cli'
    Write-Host 'then open a new PowerShell window and run this script again.'
    exit 1
}
gh auth status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Sign in to GitHub (a browser window opens).'
    gh auth login --hostname github.com --web --git-protocol https
    if ($LASTEXITCODE -ne 0) { throw 'GitHub sign-in failed.' }
}

# Every repository must exist and let you manage secrets.
foreach ($r in $Repos) {
    $admin = gh api "repos/$Org/$r" --jq '.permissions.admin' 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Can't see $Org/$r. Check the name and that you are signed in as an owner." }
    if ("$admin".Trim() -ne 'true') { throw "You need admin rights on $Org/$r to set its secrets." }
}

# ---- RELEASES_TOKEN -------------------------------------------------------
$token = $null
if (-not $SkipToken) {
    Section 'Step 1 of 2: a token that can publish to BroadcastLabs-Releases'
    Write-Host @"
A browser page opens to make a fine-grained personal access token. Set:
  Token name          BroadcastLabs release publishing
  Resource owner      $Org
  Expiration          366 days (the longest GitHub allows; builds warn you 30 days before)
  Repository access   Only select repositories -> $ReleasesRepo
  Permissions         Repository permissions -> Contents -> Read and write
Then Generate token, copy it, and paste it here.
If $Org requires approval for fine-grained tokens, approve it under
the organisation's Settings > Personal access tokens > Pending requests.
"@
    $url = "https://github.com/settings/personal-access-tokens/new?name=BroadcastLabs%20release%20publishing&description=Lets%20the%20app%20builds%20publish%20installers%20to%20$ReleasesRepo&target_name=$Org&expires_in=366&contents=write"
    Start-Process $url
    $token = Read-Secret 'Paste the token (hidden)'
    if (-not $token) { throw 'No token entered.' }

    # Check it can read AND write releases there: make and delete a draft.
    $h = @{ Authorization = "Bearer $token"; 'X-GitHub-Api-Version' = '2022-11-28'; Accept = 'application/vnd.github+json' }
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri "https://api.github.com/repos/$Org/$ReleasesRepo" -Headers $h
    } catch { throw "GitHub refused the token for $Org/$ReleasesRepo. Check its resource owner and repository access (and approval, if required)." }
    $exp = "$($r.Headers['github-authentication-token-expiration'])"
    try {
        $draft = Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/$Org/$ReleasesRepo/releases" -Headers $h `
                   -ContentType 'application/json' -Body (@{ tag_name = 'token-check'; name = 'token check'; draft = $true } | ConvertTo-Json)
        Invoke-RestMethod -Method Delete -Uri "https://api.github.com/repos/$Org/$ReleasesRepo/releases/$($draft.id)" -Headers $h | Out-Null
    } catch { throw "The token can read $ReleasesRepo but can't write releases. Give it Contents: Read and write." }
    Write-Host ("Token works" + $(if ($exp) { ", valid until $exp." } else { '.' })) -ForegroundColor Green
}

# ---- RELEASE_WEBHOOK_SECRET -----------------------------------------------
$hook = $null
if (-not $SkipWebhook) {
    Section 'Step 2 of 2: the website release key'
    Write-Host @"
On the website: Admin > Settings > Update service > Release notices > Generate a key.
Copy the key it shows and paste it here, or press Enter to skip (the website
then has to be updated by hand after each release).
"@
    $hook = Read-Secret 'Paste the website release key (hidden)'
    if ($hook -and $hook -notmatch '^[0-9a-f]{64}$') { throw "That doesn't look like a release key (64 hex characters)." }
}

# ---- set them -------------------------------------------------------------
Section 'Setting the secrets'
foreach ($r in $Repos) {
    if ($token) {
        gh secret set RELEASES_TOKEN --repo "$Org/$r" --body $token
        if ($LASTEXITCODE -ne 0) { throw "Couldn't set RELEASES_TOKEN on $Org/$r." }
    }
    if ($hook) {
        gh secret set RELEASE_WEBHOOK_SECRET --repo "$Org/$r" --body $hook
        if ($LASTEXITCODE -ne 0) { throw "Couldn't set RELEASE_WEBHOOK_SECRET on $Org/$r." }
    }
    Write-Host "  $Org/$r" -ForegroundColor Green
}
$token = $null; $hook = $null

Section 'Done'
Write-Host 'To release an app: its repository > Actions > Build and release > Run workflow,'
Write-Host 'enter the version (e.g. 1.0.1) and optional notes, then Run workflow.'
if ($exp) { Write-Host "Put a reminder in your calendar to replace the token before $exp." -ForegroundColor Yellow }
