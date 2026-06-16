#requires -version 5
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$assets  = $PSScriptRoot
$root    = Split-Path -Parent $assets
$trimmed = "$assets\trimmed"
$build   = "$assets\docx-build"
$outFile = "$root\Sental_Dashboard_Formulas.docx"

if (Test-Path $build) { Remove-Item $build -Recurse -Force }
New-Item -ItemType Directory -Path "$build\_rels" -Force | Out-Null
New-Item -ItemType Directory -Path "$build\docProps" -Force | Out-Null
New-Item -ItemType Directory -Path "$build\word\_rels" -Force | Out-Null
New-Item -ItemType Directory -Path "$build\word\media" -Force | Out-Null

# ===================== XML HELPERS =====================
function Esc([string]$s) {
  if ($null -eq $s) { return '' }
  $s = $s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
  return $s
}

function Run([string]$text, [bool]$bold=$false, [string]$color=$null, [int]$sz=20) {
  $rpr = "<w:rPr><w:rFonts w:ascii=`"Arial`" w:hAnsi=`"Arial`"/><w:sz w:val=`"$sz`"/>"
  if ($bold) { $rpr += "<w:b/>" }
  if ($color) { $rpr += "<w:color w:val=`"$color`"/>" }
  $rpr += "</w:rPr>"
  return "<w:r>$rpr<w:t xml:space=`"preserve`">$(Esc $text)</w:t></w:r>"
}

function Para([string]$text, [bool]$bold=$false, [string]$color=$null, [int]$sz=20, [int]$spaceAfter=120) {
  return "<w:p><w:pPr><w:spacing w:after=`"$spaceAfter`"/></w:pPr>$(Run $text $bold $color $sz)</w:p>"
}

function H1([string]$text, [string]$bookmark) {
  $bm = ""
  if ($bookmark) { $bm = "<w:bookmarkStart w:id=`"$($script:bmId)`" w:name=`"$bookmark`"/><w:bookmarkEnd w:id=`"$($script:bmId)`"/>"; $script:bmId++ }
  return "<w:p><w:pPr><w:pStyle w:val=`"Heading1`"/></w:pPr>$bm<w:r><w:t xml:space=`"preserve`">$(Esc $text)</w:t></w:r></w:p>"
}

function H2([string]$text) {
  return "<w:p><w:pPr><w:pStyle w:val=`"Heading2`"/></w:pPr><w:r><w:t xml:space=`"preserve`">$(Esc $text)</w:t></w:r></w:p>"
}

function PageBreak() { return "<w:p><w:r><w:br w:type=`"page`"/></w:r></w:p>" }

function ImageParagraph([string]$relId, [long]$wEmu, [long]$hEmu, [string]$name, [int]$docPrId) {
  return @"
<w:p><w:pPr><w:spacing w:after="160"/></w:pPr><w:r><w:drawing>
<wp:inline distT="0" distB="0" distL="0" distR="0" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">
<wp:extent cx="$wEmu" cy="$hEmu"/>
<wp:effectExtent l="0" t="0" r="0" b="0"/>
<wp:docPr id="$docPrId" name="$(Esc $name)" descr="$(Esc $name)"/>
<wp:cNvGraphicFramePr><a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/></wp:cNvGraphicFramePr>
<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
<pic:nvPicPr><pic:cNvPr id="$docPrId" name="$(Esc $name)"/><pic:cNvPicPr/></pic:nvPicPr>
<pic:blipFill><a:blip r:embed="$relId" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>
<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$wEmu" cy="$hEmu"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>
</pic:pic>
</a:graphicData>
</a:graphic>
</wp:inline>
</w:drawing></w:r></w:p>
"@
}

function TableXml([string[]]$headers, [object[][]]$rows, [int[]]$colWidthsDxa) {
  $tableW = ($colWidthsDxa | Measure-Object -Sum).Sum
  $grid = ($colWidthsDxa | ForEach-Object { "<w:gridCol w:w=`"$_`"/>" }) -join ''
  $border = "<w:top w:val=`"single`" w:sz=`"4`" w:color=`"CCCCCC`"/><w:left w:val=`"single`" w:sz=`"4`" w:color=`"CCCCCC`"/><w:bottom w:val=`"single`" w:sz=`"4`" w:color=`"CCCCCC`"/><w:right w:val=`"single`" w:sz=`"4`" w:color=`"CCCCCC`"/>"

  $headerCells = ""
  for ($i = 0; $i -lt $headers.Length; $i++) {
    $headerCells += "<w:tc><w:tcPr><w:tcW w:w=`"$($colWidthsDxa[$i])`" w:type=`"dxa`"/><w:tcBorders>$border</w:tcBorders><w:shd w:val=`"clear`" w:fill=`"1F4E79`"/><w:vAlign w:val=`"center`"/></w:tcPr><w:p><w:pPr><w:spacing w:after=`"0`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Arial`" w:hAnsi=`"Arial`"/><w:b/><w:color w:val=`"FFFFFF`"/><w:sz w:val=`"18`"/></w:rPr><w:t xml:space=`"preserve`">$(Esc $headers[$i])</w:t></w:r></w:p></w:tc>"
  }
  $headerRow = "<w:tr><w:trPr><w:tblHeader/></w:trPr>$headerCells</w:tr>"

  $bodyRows = ""
  foreach ($row in $rows) {
    $cells = ""
    for ($i = 0; $i -lt $row.Length; $i++) {
      $cells += "<w:tc><w:tcPr><w:tcW w:w=`"$($colWidthsDxa[$i])`" w:type=`"dxa`"/><w:tcBorders>$border</w:tcBorders><w:vAlign w:val=`"center`"/></w:tcPr><w:p><w:pPr><w:spacing w:after=`"0`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Arial`" w:hAnsi=`"Arial`"/><w:sz w:val=`"17`"/></w:rPr><w:t xml:space=`"preserve`">$(Esc $row[$i])</w:t></w:r></w:p></w:tc>"
    }
    $bodyRows += "<w:tr>$cells</w:tr>"
  }

  return @"
<w:tbl>
<w:tblPr><w:tblW w:w="$tableW" w:type="dxa"/><w:tblBorders>$border</w:tblBorders><w:tblCellMar><w:top w:w="60"/><w:left w:w="100"/><w:bottom w:w="60"/><w:right w:w="100"/></w:tblCellMar><w:tblLook w:val="04A0"/></w:tblPr>
<w:tblGrid>$grid</w:tblGrid>
$headerRow
$bodyRows
</w:tbl>
<w:p><w:pPr><w:spacing w:after="200"/></w:pPr></w:p>
"@
}

function InternalLink([string]$anchor, [string]$text) {
  return "<w:p><w:pPr><w:spacing w:after=`"80`"/></w:pPr><w:hyperlink w:anchor=`"$anchor`"><w:r><w:rPr><w:rFonts w:ascii=`"Arial`" w:hAnsi=`"Arial`"/><w:color w:val=`"1155CC`"/><w:u w:val=`"single`"/><w:sz w:val=`"22`"/></w:rPr><w:t xml:space=`"preserve`">$(Esc $text)</w:t></w:r></w:hyperlink></w:p>"
}

Write-Host "Helpers loaded."

# ===================== IMAGE DIMS (px) =====================
$imgDims = @{
  '01_kpi_default'=@{w=1440;h=521}; '02_kpi_drill_comp'=@{w=1440;h=447}; '03_kpi_drill_eds'=@{w=1440;h=515};
  '04_kpi_drill_server'=@{w=1440;h=529}; '05_overview'=@{w=1440;h=1061}; '06_compliance'=@{w=1440;h=1327};
  '07_turnover'=@{w=1440;h=645}; '08_training'=@{w=1440;h=933}; '09_proctoring'=@{w=1440;h=693};
  '10_forecast'=@{w=1440;h=1037}; '11_server'=@{w=1440;h=1241}; '12_reports_empty'=@{w=1440;h=997};
  '13_reports_loaded'=@{w=1440;h=997}
}
$EMU_PER_IN = 914400
$displayWidthEmu = [long](6.3 * $EMU_PER_IN)

function ImgEmuHeight([string]$key) {
  $d = $imgDims[$key]
  return [long]($displayWidthEmu * ($d.h / $d.w))
}

Write-Host "Image dims loaded: $($imgDims.Count) entries"

# ===================== CONTENT DATA =====================
$tabs = @()

# ---- TAB 1: KPI STRIP ----
$tabs += @{
  title='1. KPI Strip'; anchor='tab_kpi'
  intro='Six top-line KPI cards visible on every login, plus three dedicated drill-down panels with unique formulas not shown elsewhere.'
  blocks=@(
    @{ h2='KPI Strip - Six Summary Cards'; image='01_kpi_default'
       headers=@('Element','Example Value','Formula','Data Source / Filter','Threshold & Color Rule')
       rows=@(
         @('Total active users','1,247','Count of active users (deleted=0, suspended=0)','mdl_user WHERE deleted=0 AND suspended=0','Grouped by IOMAD tenant. No individual names shown at this level.'),
         @('Overall compliance','78%','valid_docs / active_users * 100','sental_document_versions WHERE expiry_date > NOW() AND is_current=1','GREEN >=80% Compliant; AMBER 70-79% At risk; RED <70% Non-compliant'),
         @('Expiring <30 days','171','COUNT where 0 < days_to_expiry <= 30','sental_document_versions WHERE expiry_date BETWEEN NOW() AND NOW()+30d','Click number -> full employee list'),
         @('Expired now','74','COUNT where expiry_date < NOW()','sental_document_versions WHERE expiry_date < NOW()','Click number -> full employee list'),
         @('EDS queue','17 (3 critical)','COUNT of documents awaiting electronic signature','sental_eds_log','OK <2 days; Urgent 2-5 days; Critical >5 days (days waiting)'),
         @('Server disk','82%','used_GB / total_GB * 100','sental_server_metrics (latest collected_at per metric)','Amber at 70%, Red at 90% (thresholds adjustable in Server tab)')
       )
       note='The "Total active users" card opens a drill table (shown in this screenshot) listing Active Users and Compliance % per company, with the same formulas as above applied per-company, plus a RAG status: GREEN >=80%, AMBER 70-79%, RED <70%, BLUE = onboarding in progress. The "Expiring <30 days" and "Expired now" cards open named-employee drill lists using the identical filters listed above (no separate formula) - not screenshotted separately.'
     },
    @{ h2='Overall Compliance - Drill-Down (colour-coded by threshold)'; image='02_kpi_drill_comp'
       headers=@('Element','Formula','Data Source / Filter','Notes')
       rows=@(
         @('Compliance % per company','users with valid docs / total active users * 100','Valid = sental_document_versions WHERE expiry_date > NOW() AND is_current=1','Sorted ascending (worst first). Reference line drawn at 80% target.')
       )
     },
    @{ h2='EDS Queue - Pending Document Records'; image='03_kpi_drill_eds'
       headers=@('Element','Formula','Data Source / Filter','Notes')
       rows=@(
         @('Days waiting','Days elapsed since document was sent for signature','sental_eds_log','OK: <2 days; Urgent: 2-5 days; Critical: >5 days. "Notify all signatories" sends a reminder to every pending signer.')
       )
     },
    @{ h2='Server Disk - Inline Capacity Gauges (Drill-Down)'; image='04_kpi_drill_server'
       headers=@('Element','Formula','Data Source / Filter','Threshold & Color Rule')
       rows=@(
         @('Disk / RAM / CPU / Database / Concurrent users (%)','used / total * 100 for each metric','sental_server_metrics - latest collected_at row per metric','Amber >=70%, Red >=90% (both adjustable via slider). Identical gauges also appear on the full Server tab.')
       )
     }
  )
}

# ---- TAB 2: OVERVIEW ----
$tabs += @{
  title='2. Overview'; anchor='tab_overview'
  intro='Platform-wide summary combining engagement metrics, registration growth, and a per-company health roll-up.'
  blocks=@(
    @{ h2='Platform KPI Strip - Four Cards'; image='05_overview'
       headers=@('Element','Example Value','Formula','Data Source / Filter')
       rows=@(
         @('Total users','1,247 (+63 this month, +5.3%)','Count of active users, platform-wide','Same filter as KPI Strip "Total active users"'),
         @('Platform uptime','99.7%','(total_minutes - downtime_minutes) / total_minutes * 100','Server monitoring logs, last 30 days (21 min downtime in example)'),
         @('Avg compliance','75% (Below target)','AVERAGE(compliance % across all companies)','Same compliance formula as KPI Strip, averaged across companies'),
         @('Active companies','3 / 4','COUNT(companies with status != onboarding) / COUNT(all companies)','Company registry (KazMunayGas onboarding in example)')
       )
     },
    @{ h2='Platform Registration Growth (chart)'; image=$null
       headers=@('Element','Formula','Data Source / Filter')
       rows=@(
         @('Monthly new-registration bar','COUNT(mdl_user WHERE timecreated falls in that month)','mdl_user.timecreated, grouped by month and by company (stacked/grouped bar). Period selector: 3 months / 1 year / 2 years / All time.')
       )
     },
    @{ h2='Platform Activity Snapshot (DAU / MAU)'; image=$null
       headers=@('Element','Example Value','Formula','Data Source / Filter')
       rows=@(
         @('DAU (Daily Active Users)','147 (+12 vs yesterday)','COUNT(DISTINCT user who logged in today)','Login/session logs'),
         @('MAU (Monthly Active Users)','834 (66.9% of total)','COUNT(DISTINCT user who logged in within last 30 days)','Login/session logs'),
         @('Completion rate','62% (-4% vs last month)','completed_enrolments / total_enrolments * 100','Course completion logs, last 30 days'),
         @('Avg session','24 min (+3m vs last month)','AVERAGE(session_duration)','Session logs'),
         @('Top 3 active courses','Fire Safety L1 84%, Electrical Safety 71%, Working at Heights 52%','Engagement % per course this month','Course activity logs')
       )
       note='DAU/MAU ratio above 20% indicates healthy daily engagement (per in-app tooltip).'
     },
    @{ h2='Company Health Summary Table'; image=$null
       headers=@('Column','Formula Reference')
       rows=@(
         @('Users','See KPI Strip "Total active users"'),
         @('Compliance %','See Compliance tab formula (valid_docs / active_users * 100)'),
         @('Turnover','See Staff Turnover tab formula (Deactivated / Average active * 100)'),
         @('Trust score','See Proctoring tab (average Quilgo trust score per company)'),
         @('Completion','See Training Quality tab (completed_enrolments / total_enrolments * 100)'),
         @('Status badge','Derived: Healthy / At risk / Critical / Onboarding, based primarily on the Compliance % threshold')
       )
     },
    @{ h2='Priority Actions (3 alert cards)'; image=$null
       headers=@('Element','Formula')
       rows=@(
         @('Priority action cards','No new formula - these surface the single worst value already computed elsewhere (lowest compliance company, highest expired-document count, highest server metric) to flag what needs attention first.')
       )
     }
  )
}

# ---- TAB 3: COMPLIANCE ----
$tabs += @{
  title='3. Compliance'; anchor='tab_compliance'
  intro='All compliance-rate views share one core formula (valid documents over active users), sliced by different dimensions.'
  blocks=@(
    @{ h2='Compliance by Company - 12-Month Trend / Snapshot / Heatmap / Expired vs Expiring / Non-Compliance by Course / Violations Table'; image='06_compliance'
       headers=@('Element','Formula','Data Source / Filter','Threshold & Color Rule')
       rows=@(
         @('12-month trend line (per company)','valid_docs / active_users * 100, recomputed monthly','sental_document_versions, snapshotted monthly','Dashed reference line at 80% target. A line dropping below it flags the need for HR intervention.'),
         @('Snapshot bar (current)','Same formula, current point in time','Same source','GREEN >=80; AMBER 70-79; RED <70. Sorted ascending (worst first).'),
         @('Heatmap cell (dept x location)','valid_docs / active_users * 100, filtered to that department AND location','sental_document_versions joined to mdl_user department/location fields','RED <70%; AMBER 70-79%; GREEN >=80%. Per-company filter tabs available above the heatmap.'),
         @('Expired bar (red)','COUNT WHERE expiry_date < NOW()','sental_document_versions','Immediate action required'),
         @('Expiring bar (amber)','COUNT WHERE 0 < days_to_expiry <= 30','sental_document_versions','Schedule training now'),
         @('Non-compliance by course %','enrolled_without_valid_doc / total_enrolled * 100, per course','mdl_user enrolments cross-referenced with sental_document_versions','Sorted descending (worst first)'),
         @('Violations table row','Status = Expired if expiry_date < NOW(), else Expiring if within 30 days','sental_document_versions JOIN mdl_user','RED badge = Expired; AMBER badge = Expiring. Filterable by status/doc type, searchable by name or course.')
       )
     }
  )
}

# ---- TAB 4: STAFF TURNOVER ----
$tabs += @{
  title='4. Staff Turnover'; anchor='tab_turnover'
  intro='Covers headcount change over time and the turnover-rate formula the user originally asked about.'
  blocks=@(
    @{ h2='Staff Dynamics, Turnover Rate % by Company, and New-Staff-Without-Certs Risk Panel'; image='07_turnover'
       headers=@('Element','Example Value','Formula','Data Source / Filter','Threshold & Color Rule')
       rows=@(
         @('New staff (blue bar)','varies by month','COUNT(mdl_user WHERE timecreated falls within that month)','mdl_user.timecreated','Tall blue + short red = team growth'),
         @('Deactivated (red bar)','varies by month','COUNT(mdl_user newly suspended=1 OR deleted=1 within that month)','mdl_user.suspended / deleted + timemodified','Tall red = high churn'),
         @('Net trend (dashed green line)','New staff minus Deactivated, cumulative','Derived from the two series above','-'),
         @('Turnover rate % by company','ArcelorMittal 18%, TOO MashStroy 12%, Kazatomprom 5%','Deactivated / Average active * 100','mdl_user deactivation count over rolling 12 months, divided by average active headcount for the same period','GREEN <5% Good; AMBER 5-10% Monitor; RED >10% High turnover. High turnover increases training costs for replacements.'),
         @('New staff without certs - at risk %','ArcelorMittal 35%, TOO MashStroy 15%, Kazatomprom 5%','COUNT(new hires with zero active documents) / COUNT(all new hires) * 100','mdl_user WHERE timecreated <= NOW()-30d AND no matching sental_document_versions','Above 20% = critical risk for access to hazardous work')
       )
     }
  )
}

# ---- TAB 5: TRAINING QUALITY ----
$tabs += @{
  title='5. Training Quality'; anchor='tab_training'
  intro='Measures exam performance, engagement, subjective course feedback, and completion trend.'
  blocks=@(
    @{ h2='Pass Rate, Engagement Ratio, Ratings & Feedback, Completion Trend'; image='08_training'
       headers=@('Element','Formula','Data Source / Filter','Threshold & Color Rule')
       rows=@(
         @('First-attempt pass rate %','passed_on_first_attempt / total_first_attempts * 100, per course','Quiz/exam attempt logs','Reference line at 60%. Below 60% triggers a recommendation to review course content. Sorted ascending.'),
         @('Engagement ratio %','actual_active_time / total_session_time * 100, per course','Session activity logs','RED <30% (likely skipped content); AMBER 30-60%; GREEN >60%'),
         @('Course rating','AVERAGE(post-completion survey score), 1-5 stars','Post-course employee evaluations','Below 3.0 stars flags the course for content review'),
         @('NPS (Net Promoter Score)','%Promoters - %Detractors from the same survey','Post-course employee evaluations','Range -100 to +100; negative NPS is a strong warning sign'),
         @('Relevance %','% of respondents rating content as relevant to their job','Post-course employee evaluations','Used alongside rating/NPS to flag content mismatch'),
         @('Completion rate trend (per company)','completed_enrolments / total_enrolments * 100, monthly','Course completion logs','Dashed reference line at 80% target. A falling line is a warning sign.')
       )
     }
  )
}

# ---- TAB 6: PROCTORING ----
$tabs += @{
  title='6. Proctoring'; anchor='tab_proctoring'
  intro='Quilgo AI proctoring trust scores, by distribution, by company, and cross-referenced with completion rate.'
  blocks=@(
    @{ h2='Trust Score Distribution, Average by Company, and Trust-vs-Completion Scatter'; image='09_proctoring'
       headers=@('Element','Example Value','Formula','Data Source / Filter','Threshold & Color Rule')
       rows=@(
         @('Trust score band %','Trusted 55%, Review 25%, Suspicious 15%, Flagged 5% (of 2,841 attempts)','COUNT(attempts in band) / total_attempts * 100','Quilgo AI proctoring scores','90-100 Trusted; 70-89 Review recommended; 50-69 Suspicious; 0-49 Flagged'),
         @('Average trust score per company','ArcelorMittal 72, TOO MashStroy 79, Kazatomprom 88','AVERAGE(trust_score) grouped by company','Quilgo scores','Dashed line = platform average. Below-average score combined with high completion % signals possible mass falsification risk.'),
         @('Scatter point (one per course)','X = completion %, Y = average trust score','Course completion % cross-referenced with average Quilgo trust score for that course','Quilgo scores + completion logs','Bottom-right quadrant (high completion / low trust) = most suspicious; top-right (high completion / high trust) = healthy')
       )
     }
  )
}

# ---- TAB 7: FORECAST ----
$tabs += @{
  title='7. Forecast'; anchor='tab_forecast'
  intro='Forward-looking document-expiry and training-load projections used for staffing decisions.'
  blocks=@(
    @{ h2='30/60/90-Day Mini-Cards, 13-Week Histogram, and 12-Month Training Load Forecast'; image='10_forecast'
       headers=@('Element','Example Value','Formula','Data Source / Filter','Threshold & Color Rule')
       rows=@(
         @('Expiring in 30/60/90 days','42 / 71 / 104','COUNT WHERE 0 < days_to_expiry <= {30,60,90}','sental_document_versions','RED (30d) / AMBER (60d) / BLUE (90d) tiles'),
         @('13-week expiry histogram (per week)','varies, e.g. W3=14, W8=13','COUNT(documents expiring in week N)','sental_document_versions grouped by ISO week','Bar turns RED if count >= peak threshold (default 10, adjustable via slider). Plan retraining 2-3 weeks before a peak.'),
         @('12-month training load (stacked monthly total)','e.g. Feb 2026 = 470 sessions (MAX)','SUM(retraining_online + retraining_offline + new_staff + doc_renewals + EDS) for that month','Combines sental_document_versions (renewals), mdl_user (new staff projections), and course enrolment forecasts','A month is flagged as a "peak period" when its total spikes well above the trailing baseline; example flags 3 peaks with recommended staffing actions (CEO-only view).')
       )
     }
  )
}

# ---- TAB 8: SERVER ----
$tabs += @{
  title='8. Server'; anchor='tab_server'
  intro='Infrastructure health: live capacity gauges, a forward forecast, error counts, and a config status panel.'
  blocks=@(
    @{ h2='Capacity Gauges, 90-Day Disk Forecast, Error Log, and System Settings'; image='11_server'
       headers=@('Element','Example Value','Formula','Data Source / Filter','Threshold & Color Rule')
       rows=@(
         @('Disk / RAM / CPU / Database / Concurrent users (%)','Disk 82%, RAM 58%, CPU 28%, DB 67%, Users 49%','used / total * 100 for each metric','sental_server_metrics, latest reading per metric','Warning >=70% (adjustable), Critical >=90% (adjustable). Click a gauge for its 7-day sparkline.'),
         @('90-day disk forecast','~5 weeks to critical at current rate','Linear regression on the trailing 30-day disk-usage history','sental_server_metrics history','Critical threshold line at 90% (adjustable); growth rate shown as %/week (example: +0.6%/week)'),
         @('Error log count (per category, 7 days)','QR generation failures: 14; Email delivery failures: 7; EDS signature rejections: 3; Cron overruns: 2; Quilgo API timeouts: 0; File storage errors: 0','COUNT(errors in that category within the last 7 days)','sental_qr_log / SMTP send logs / sental_eds_log / mdl_task_log / Quilgo API logs / file storage logs','This is a status read-out, not a calculated KPI - no color threshold, just a raw count with a "last occurred" timestamp.'),
         @('System settings row','e.g. Moodle 4.3.2, PHP 8.1.27, Cron running 8 min ago, SMTP 7 failures, log retention unlimited','Direct read of current configuration value vs. a recommended value','Moodle/PHP/Cron/Cache/SMTP/log-retention settings','Not a calculated formula - a current-vs-recommended config check (example: 6 OK / 2 Warning / 1 Check).')
       )
     }
  )
}

# ---- TAB 9: REPORTS ----
$tabs += @{
  title='9. Reports (Act of Completed Works)'; anchor='tab_reports'
  intro='The only tab where the dashboard already implements an automatic pull from system data: clicking "Load from LMS" populates every service quantity from actual training completions for the selected company and month, which the user can then review (and optionally override) before generating the official Excel Act.'
  blocks=@(
    @{ h2='Report Configuration - Empty State (before Load from LMS)'; image='12_reports_empty'
       headers=@('Element','Formula','Data Source / Filter')
       rows=@(
         @('LMS Count column (per service row)','COUNT(sental_completions WHERE status = completed AND company = ? AND course = ? AND month = ? AND year = ?)','sental_completions table, one query per of the 13 service/course line items'),
         @('Act Qty column (per service row)','Defaults to the LMS Count once loaded; remains user-editable afterward','Same source, then optional manual override before generating the Excel file')
       )
       note='The 13 service/course line items are: Industrial Safety at Hazardous Facilities (offline/online), Fire Safety Minimum (offline/online), Occupational Health and Safety (offline/online), Electrical Safety (offline/online), Floor-Operated Crane Operator (offline), Rigger (offline), Working at Heights Safety (offline/online), and Training Coordinator Services. Each gets its own COUNT query with the formula above, filtered to that specific course.'
     },
    @{ h2='Report Configuration - Loaded State (after Load from LMS) and Derived Stats'; image='13_reports_loaded'
       headers=@('Element','Formula')
       rows=@(
         @('Act Total','SUM(all Act Qty values across the 13 rows)'),
         @('LMS Total','SUM(all LMS Count values across the 13 rows)'),
         @('Difference (vs LMS)','Act Total minus LMS Total. Shown in GREEN if 0, AMBER if not zero.'),
         @('Modified row count','COUNT(rows where Act Qty does not equal the LMS Count) - flags manual overrides for the reviewer before download'),
         @('Downloaded Excel file','Generated client-side from the final Act Qty values; produces the official multi-language Act of Completed Works document with company, period, contract number, and a service/quantity table matching the on-screen data exactly.')
       )
     }
  )
}

Write-Host "Content data loaded: $($tabs.Count) tabs"

# ===================== BUILD document.xml BODY =====================
$script:bmId = 1
$docPrCounter = 100
$imgRelMap = @{}   # imageKey -> rId
$nextImgRelId = 10

$body = ""

# ---- Title page / front matter ----
$body += "<w:p><w:pPr><w:jc w:val=`"center`"/><w:spacing w:after=`"80`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Arial`" w:hAnsi=`"Arial`"/><w:b/><w:sz w:val=`"56`"/><w:color w:val=`"1F4E79`"/></w:rPr><w:t>Sental LMS Analytics</w:t></w:r></w:p>"
$body += "<w:p><w:pPr><w:jc w:val=`"center`"/><w:spacing w:after=`"600`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Arial`" w:hAnsi=`"Arial`"/><w:sz w:val=`"32`"/><w:color w:val=`"44546A`"/></w:rPr><w:t>Dashboard Calculation Formulas - Developer Reference</w:t></w:r></w:p>"
$body += Para "This document is a screenshot-to-formula reference for every chart, KPI card, and table in the Company Owner Dashboard wireframe (company_owner_dashboard_wireframe.html). The wireframe uses mock data throughout; screenshots show the visual layout only. Every Formula and Data Source / Filter cell below is transcribed verbatim from the wireframe's own tooltip and drill-down text, so it can be implemented directly against a real database." $false $null 20 120
$body += Para "Each section pairs one dashboard screenshot with a table covering every element visible in it. Where a block has no real calculation (e.g. the Server tab's config status panel), the Formula column says so explicitly rather than inventing one." $false $null 20 300

$body += Para "Contents" $true $null 24 160
foreach ($tab in $tabs) {
  $body += InternalLink $tab.anchor $tab.title
}
$body += PageBreak

# ---- Tabs ----
$firstTab = $true
foreach ($tab in $tabs) {
  if (-not $firstTab) { $body += PageBreak }
  $firstTab = $false
  $body += H1 $tab.title $tab.anchor
  if ($tab.intro) { $body += Para $tab.intro $false "595959" 20 200 }

  foreach ($blk in $tab.blocks) {
    $body += H2 $blk.h2

    if ($blk.image) {
      if (-not $imgRelMap.ContainsKey($blk.image)) {
        $imgRelMap[$blk.image] = "rId$nextImgRelId"
        $nextImgRelId++
      }
      $relId = $imgRelMap[$blk.image]
      $hEmu = ImgEmuHeight $blk.image
      $docPrCounter++
      $body += ImageParagraph $relId $displayWidthEmu $hEmu $blk.image $docPrCounter
    }

    # column widths: first column narrower, rest share remainder evenly (table width = 9 * 700 = 9 inches max; use 6.3in content width = 9072 dxa)
    $tableWidthDxa = [int](6.3 * 1440)
    $nCols = $blk.headers.Length
    if ($nCols -eq 4) { $colWidths = @(2200,2300,2300,2272) }
    elseif ($nCols -eq 5) { $colWidths = @(1800,1700,1900,1900,1772) }
    elseif ($nCols -eq 6) { $colWidths = @(1500,1300,1700,1700,1372,1500) }
    elseif ($nCols -eq 2) { $colWidths = @(3500,5572) }
    else { $colWidths = @(1..$nCols | ForEach-Object { [int]($tableWidthDxa / $nCols) }) }
    # adjust last to make exact sum
    $sum = ($colWidths | Measure-Object -Sum).Sum
    $colWidths[-1] += ($tableWidthDxa - $sum)

    $body += TableXml $blk.headers $blk.rows $colWidths

    if ($blk.note) { $body += Para $blk.note $false "595959" 18 200 }
  }
}

Write-Host "Body XML generated: $($body.Length) chars, $($imgRelMap.Count) images referenced"
