# Version helpers shared by the release actions. Dot-source it.
#
# Every BroadcastLabs app keeps its version in a few files (CMakeLists.txt,
# a branding header, the Windows .rc resource, VERSION.txt). The workflow
# names them in VERSION_FILES, first one being the source of truth.
# A .NET project (*.csproj) keeps it in <Version>x.y.z</Version>; only that
# element is touched (PackageReference Version="..." attributes are not).

function Get-AppVersion([string[]] $Files) {
    $f = $Files[0]
    $text = Get-Content -Raw -LiteralPath $f
    if ((Split-Path $f -Leaf) -eq 'VERSION.txt') { return $text.Trim() }
    if ((Split-Path $f -Leaf) -eq 'CMakeLists.txt') {
        $m = [regex]::Match($text, '(?s)project\s*\([^)]*?\bVERSION\s+(\d+\.\d+\.\d+)')
        if ($m.Success) { return $m.Groups[1].Value }
    }
    if ($f -like '*.csproj') {
        $m = [regex]::Match($text, '<Version>\s*(\d+\.\d+\.\d+)(\.\d+)?\s*</Version>')
        if ($m.Success) { return $m.Groups[1].Value }
        throw "No <Version> found in $f"
    }
    foreach ($line in ($text -split "`n")) {
        if ($line -match '(?i)version') {
            $m = [regex]::Match($line, '"(\d+\.\d+\.\d+)(\.\d+)?"')
            if ($m.Success) { return $m.Groups[1].Value }
        }
    }
    throw "No version found in $f"
}

function Set-AppVersion([string[]] $Files, [string] $Version) {
    $p = $Version.Split('.')
    $commas = "$($p[0]),$($p[1]),$($p[2]),0"
    foreach ($f in $Files) {
        $text = Get-Content -Raw -LiteralPath $f
        $leaf = Split-Path $f -Leaf
        if ($leaf -eq 'VERSION.txt') {
            $new = "$Version`n"
        } elseif ($leaf -like '*.csproj') {
            $new = [regex]::Replace($text, '<Version>\s*\d+\.\d+\.\d+(\.\d+)?\s*</Version>', "<Version>$Version</Version>")
        } elseif ($leaf -eq 'CMakeLists.txt') {
            $new = [regex]::Replace($text, '(?s)(project\s*\([^)]*?\bVERSION\s+)\d+\.\d+\.\d+', { param($m) $m.Groups[1].Value + $Version }, 1)
        } else {
            # Only lines that talk about a version: quoted dotted numbers and
            # the comma-separated FILEVERSION form.
            $lines = $text -split "(?<=`n)"
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -notmatch '(?i)version') { continue }
                $lines[$i] = [regex]::Replace($lines[$i], '"\d+\.\d+\.\d+(\.\d+)?"', {
                    param($m) if ($m.Groups[1].Success) { "`"$Version.0`"" } else { "`"$Version`"" } })
                $lines[$i] = [regex]::Replace($lines[$i], '\b\d+,\s*\d+,\s*\d+,\s*\d+\b', $commas)
            }
            $new = -join $lines
        }
        if ($new -ne $text) {
            [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $f), $new)
            Write-Host "  $f -> $Version"
        }
    }
    $check = Get-AppVersion $Files
    if ($check -ne $Version) { throw "Version bump did not take: $($Files[0]) still says $check" }
}
