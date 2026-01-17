param(
    [string]$CopyFile = "sitelink-copy.json",
    [string]$BaseFile = "public\\index.html"
)

if (!(Test-Path $CopyFile)) {
    Write-Error "Missing copy file: $CopyFile"
    exit 1
}
if (!(Test-Path $BaseFile)) {
    Write-Error "Missing base file: $BaseFile"
    exit 1
}

$pages = Get-Content -Raw $CopyFile | ConvertFrom-Json
$base = Get-Content -Raw $BaseFile

function Get-Section($content, $pattern) {
    $match = [regex]::Match($content, $pattern)
    if ($match.Success) { return $match.Value }
    return $null
}

$baseAccident = Get-Section $base '(?s)<section class="accident-types section-with-bg">.*?</section>'
$baseCase = Get-Section $base '(?s)<section id="your-case".*?</section>'
$baseTrust = Get-Section $base '(?s)<section class="core-trust.*?</section>'
$baseProcess = Get-Section $base '(?s)<section class="process-section.*?</section>'
$worthMatches = [regex]::Matches($base, '(?s)<section class="worth-section section-with-bg">.*?</section>')
$baseWorth = if ($worthMatches.Count -ge 1) { $worthMatches[$worthMatches.Count - 1].Value } else { $null }
$baseForm = Get-Section $base '(?s)<section id="case-evaluation".*?</section>'
$baseReviews = Get-Section $base '(?s)<section id="reviews".*?</section>'
$baseFinal = Get-Section $base '(?s)<section class="final-cta">.*?</section>'

function Build-AccidentGrid($items) {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('<div class="accident-grid">')
    foreach ($item in $items) {
        [void]$sb.AppendLine('                <div class="accident-item">')
        [void]$sb.AppendLine('                    <div class="accident-icon">&gt;</div>')
        [void]$sb.AppendLine(("                    <div class=""accident-item-text"">{0}</div>" -f $item))
        [void]$sb.AppendLine('                </div>')
    }
    [void]$sb.Append('            </div>')
    return $sb.ToString()
}

function Build-CaseGrid($titles, $bodies) {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 24px; margin-bottom: 48px;">')
    for ($i = 0; $i -lt $titles.Count; $i++) {
        $title = $titles[$i]
        $body = $bodies[$i]
        [void]$sb.AppendLine('                    <div style="background: var(--brand-white); padding: 32px; border-radius: 12px; border-left: 5px solid var(--brand-blue); box-shadow: 0 4px 12px rgba(0,0,0,0.08); transition: all 0.3s ease; cursor: pointer;">')
        [void]$sb.AppendLine('                        <div style="display: flex; align-items: start; gap: 20px;">')
        [void]$sb.AppendLine('                            <div style="width: 48px; height: 48px; min-width: 48px; background: linear-gradient(135deg, var(--brand-blue), var(--brand-navy)); border-radius: 50%; display: flex; align-items: center; justify-content: center; color: var(--brand-white); font-weight: 700; font-size: 24px; flex-shrink: 0; box-shadow: 0 4px 8px rgba(18, 62, 122, 0.3);">+</div>')
        [void]$sb.AppendLine('                            <div>')
        [void]$sb.AppendLine(("                                <h4 style=""margin-bottom: 12px; font-size: 20px; font-weight: 700; color: var(--brand-gray-900); line-height: 1.3;"">{0}</h4>" -f $title))
        [void]$sb.AppendLine(("                                <p style=""font-size: 16px; line-height: 1.7; color: var(--brand-gray-700); margin: 0;"">{0}</p>" -f $body))
        [void]$sb.AppendLine('                            </div>')
        [void]$sb.AppendLine('                        </div>')
        [void]$sb.AppendLine('                    </div>')
    }
    [void]$sb.Append('                </div>')
    return $sb.ToString()
}

function Build-TrustGrid($titles, $bodies) {
    $icons = @('LAW', 'FEE', 'RESULT')
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('<div class="trust-grid">')
    for ($i = 0; $i -lt $titles.Count; $i++) {
        $icon = $icons[$i]
        [void]$sb.AppendLine('                <div class="trust-card">')
        [void]$sb.AppendLine(("                    <div class=""trust-icon"">{0}</div>" -f $icon))
        [void]$sb.AppendLine(("                    <h3>{0}</h3>" -f $titles[$i]))
        [void]$sb.AppendLine(("                    <p>{0}</p>" -f $bodies[$i]))
        [void]$sb.AppendLine('                </div>')
    }
    [void]$sb.Append('            </div>')
    return $sb.ToString()
}

function Build-ProcessSteps($titles, $bodies) {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('<div class="process-steps">')
    for ($i = 0; $i -lt $titles.Count; $i++) {
        $step = $i + 1
        $imgIndex = if ($i -lt 3) { $i + 1 } else { 3 }
        [void]$sb.AppendLine('                <div class="process-step">')
        [void]$sb.AppendLine(("                    <div class=""process-step-number"">Step {0}</div>" -f $step))
        [void]$sb.AppendLine(("                    <h3>{0}</h3>" -f $titles[$i]))
        [void]$sb.AppendLine(("                    <img src=""images/la/process-step-{0}.webp"" alt=""{1}"" class=""process-step-img"">" -f $imgIndex, $titles[$i]))
        [void]$sb.AppendLine(("                    <p>{0}</p>" -f $bodies[$i]))
        [void]$sb.AppendLine('                </div>')
    }
    [void]$sb.Append('            </div>')
    return $sb.ToString()
}

foreach ($page in $pages) {
    $path = Join-Path ("public\\sitelinks\\{0}" -f $page.slug) "index.html"
    if (!(Test-Path $path)) {
        continue
    }

    $content = Get-Content -Raw -Path $path

    $content = [regex]::Replace($content, '<title>.*?</title>', "<title>$($page.title)</title>", 1)
    $metaTag = '<meta name="description" content="{0}">' -f $page.meta
    $content = [regex]::Replace($content, '<meta name="description" content="[^"]*">', $metaTag, 1)

    $content = [regex]::Replace($content, '(<h1>).*?(</h1>)', "`$1$($page.h1)`$2", 1)
    $content = [regex]::Replace($content, '(<p class="hero-subhead">).*?(</p>)', "`$1$($page.subhead)`$2", 1)

    if ($baseAccident) {
        $section = $baseAccident
        $section = [regex]::Replace($section, '<h2>.*?</h2>', "<h2>$($page.accidentHeading)</h2>", 1)
        $section = [regex]::Replace($section, '(<p class="lead-text"[^>]*>).*?(</p>)', "`$1$($page.accidentIntro)`$2", 1)
        $grid = Build-AccidentGrid $page.accidentItems
        $section = [regex]::Replace($section, '(?s)<div class="accident-grid">.*?</div>', $grid, 1)
        $content = $content -replace '(?s)<section class="accident-types section-with-bg">.*?</section>', $section
    }

    if ($baseCase) {
        $section = $baseCase
        $section = [regex]::Replace($section, '(<h2[^>]*>).*?(</h2>)', "`$1$($page.doHeading)`$2", 1)
        $section = [regex]::Replace($section, '(<p class="lead-text"[^>]*>).*?(</p>)', "`$1$($page.doIntro)`$2", 1)
        $grid = Build-CaseGrid $page.caseTitles $page.caseBodies
        $section = [regex]::Replace($section, '(?s)<div style="display: grid;.*?</div>', $grid, 1)
        $content = [regex]::Replace($content, '(?s)<section id="your-case".*?</section>', $section, 1)
    }

    if ($baseTrust) {
        $section = $baseTrust
        $section = [regex]::Replace($section, '(<h2[^>]*>).*?(</h2>)', "`$1$($page.whyHeading)`$2", 1)
        $section = [regex]::Replace($section, '(<p style="text-align: center;[^>]*>).*?(</p>)', "`$1$($page.whyIntro)`$2", 1)
        $grid = Build-TrustGrid $page.trustTitles $page.trustBodies
        $section = [regex]::Replace($section, '(?s)<div class="trust-grid">.*?</div>', $grid, 1)
        $content = [regex]::Replace($content, '(?s)<section class="core-trust.*?</section>', $section, 1)
    }

    if ($baseProcess) {
        $section = $baseProcess
        $section = [regex]::Replace($section, '(<h2[^>]*>).*?(</h2>)', "`$1$($page.processHeading)`$2", 1)
        $steps = Build-ProcessSteps $page.stepTitles $page.stepBodies
        $section = [regex]::Replace($section, '(?s)<div class="process-steps">.*?</div>', $steps, 1)
        $content = [regex]::Replace($content, '(?s)<section class="process-section.*?</section>', $section, 1)
    }

    if ($baseWorth) {
        $section = $baseWorth
        $section = [regex]::Replace($section, '(<h2[^>]*>).*?(</h2>)', "`$1$($page.compHeading)`$2", 1)
        $section = [regex]::Replace($section, '(<p style="font-size: 20px;[^>]*>).*?(</p>)', "`$1$($page.compBody)`$2", 1)
        $content = [regex]::Replace($content, '(?s)<section class="worth-section section-with-bg">.*?</section>', $section, 1)
    }

    if ($baseForm) {
        $section = $baseForm
        $section = [regex]::Replace($section, '(<h2 class="cta-heading"[^>]*>).*?(</h2>)', "`$1$($page.formHeading)`$2", 1)
        $section = [regex]::Replace($section, '(<p style="text-align: center;[^>]*>).*?(</p>)', "`$1$($page.formBody)`$2", 1)
        $content = [regex]::Replace($content, '(?s)<section id="case-evaluation".*?</section>', $section, 1)
    }

    if ($baseReviews) {
        $section = $baseReviews
        $section = [regex]::Replace($section, '(<h2>).*?(</h2>)', "`$1$($page.reviewsHeading)`$2", 1)
        $section = [regex]::Replace($section, '(<p style="font-size: 18px;[^>]*>).*?(</p>)', "`$1$($page.reviewsSubhead)`$2", 1)
        $content = [regex]::Replace($content, '(?s)<section id="reviews".*?</section>', $section, 1)
    }

    if ($baseFinal) {
        $section = $baseFinal
        $section = [regex]::Replace($section, '(<h2>).*?(</h2>)', "`$1$($page.finalHeading)`$2", 1)
        $section = [regex]::Replace($section, '(<p>).*?(</p>)', "`$1$($page.finalBody)`$2", 1)
        $content = [regex]::Replace($content, '(?s)<section class="final-cta">.*?</section>', $section, 1)
    }

    Set-Content -Path $path -Value $content
}
