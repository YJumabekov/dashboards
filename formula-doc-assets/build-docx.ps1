#requires -version 5
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$assets  = Split-Path -Parent $PSScriptRoot -ErrorAction SilentlyContinue
if (-not $assets) { $assets = $PSScriptRoot }
$root    = Split-Path -Parent $assets
$assets  = "$root\formula-doc-assets"
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
