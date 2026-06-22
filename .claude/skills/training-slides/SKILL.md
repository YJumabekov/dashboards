---
name: training-slides
description: >
  Convert narrator scripts (scenario tables) into corporate-style slides for HeyGen avatar
  video backgrounds. Two modes: (1) Canva mode — uses the "SENTAL training deck" brand template
  (ID: EAHNTmfyZ8o) via generate-design-structured, exports 1920×1080 PNG from Canva;
  (2) HTML mode — fills local pixel-exact templates, renders via scripts/render.mjs.
  Accepts DOCX scenario tables, inline text, or JSON slide data.
  Trigger: "создай слайды", "слайды для HeyGen", "подготовь шаблоны", "обучающие слайды",
  "training slides", "lesson slides", "/training-slides".
  NOT for generic marketing presentations — specifically for HeyGen training video backgrounds
  with a left avatar zone and right content zone.
metadata: { "tags": "slides, training, heygen, canva, html, design, corporate, education" }
---

# training-slides

Turn a narrator script into a complete set of corporate slides for HeyGen avatar video backgrounds.

## Two generation modes

| Mode | When to use | Output |
|------|-------------|--------|
| **Canva** (default) | User wants Canva file + export | Canva presentation → PNG export |
| **HTML** | User wants local files, full pixel control | HTML files → PNG via render.mjs |

**Default: Canva mode** using the "SENTAL training deck" brand template.

## Canva brand template

- **Name**: SENTAL training deck template.pptx
- **ID**: `EAHNTmfyZ8o`
- **Brand kit**: `kAGMmKcqsGA`
- **View**: https://www.canva.com/brand/brand-templates/EAHNTmfyZ8o
- **Autofill fields**: none — used as `source_document` style reference

---

## Quick start

1. User provides a narrator script (DOCX scenario table or inline text)
2. Claude parses scene blocks and extracts slide data
3. Claude generates HTML files by filling templates in `templates/`
4. User renders to PNG: `bun run scripts/render.mjs <html-dir> <png-dir>`
5. Upload PNGs to HeyGen as slide backgrounds

---

## Corporate design system

All values are fixed. Do not deviate without explicit user instruction.

### Canvas
**1920 × 1080 px** (16:9). All templates are pre-sized to this.

### Colors
| Name | Hex | Where |
|------|-----|-------|
| bg-dark | `#2C3E50` | Title, summary, intro backgrounds |
| bg-light | `#F2F2F2` | Content block backgrounds |
| bg-criminal | `#1A0A0A` | Criminal responsibility block |
| accent-green | `#6AAF3D` | Brand accent, icons, underlines |
| text-white | `#FFFFFF` | On dark backgrounds |
| text-dark | `#2C3E50` | Headings on light backgrounds |
| text-body-light | `#555555` | Body text on light background |
| text-body-dark | `#CCCCCC` | Body text on dark background |

### Category accent colors
| Category | Hex | Token |
|----------|-----|-------|
| Дисциплинарная | `#F39C12` | amber |
| Административная | `#3498DB` | blue |
| Гражданско-правовая | `#9B59B6` | purple |
| Уголовная | `#E74C3C` | red |
| Summary / General | `#6AAF3D` | green |

### Typography
- **Headings**: Montserrat Bold (700)
- **Labels**: Montserrat SemiBold (600)
- **Body / values**: Plus Jakarta Sans Regular (400)
- Both loaded via Google Fonts CDN in templates

### Icons
Phosphor Icons fill variant via CDN. Key names:
`gavel`, `user-gear`, `list`, `lightbulb`, `warning`, `handcuffs`, `scales`, `currency-dollar`

---

## Template catalog

All templates live in `templates/`. Each uses `{{PLACEHOLDER}}` variables.

### `slide-a-title.html` — Title / opening slide

**Slide type A · bg `#2C3E50` · centered layout**

| Placeholder | Example |
|-------------|---------|
| `{{MODULE_LABEL}}` | `Модуль 1 · Подтема 1.5` |
| `{{ICON}}` | `gavel` |
| `{{MAIN_TITLE}}` | `Ответственность руководителя` |
| `{{SUBTITLE}}` | `— четыре вида` |
| `{{LOGO_HTML}}` | `<img src="../logo.png" height="45">` or text |

**Use for**: Заставка, opening title of any module

---

### `slide-a-summary.html` — Summary / closing slide

**Slide type A (summary variant) · bg `#2C3E50` · centered layout**

| Placeholder | Example |
|-------------|---------|
| `{{ICON}}` | `gavel` |
| `{{KEY_PHRASE}}` | `Четыре вида. Одновременно. Лично.` |
| `{{BODY_TEXT}}` | Summary paragraph |
| `{{NAV_FOOTER}}` | `→ Далее: Практическое задание · Итоговый тест` |
| `{{LOGO_HTML}}` | logo HTML |

**Use for**: Итог, Слой 3, closing of any module

---

### `slide-b-overlay.html` — Avatar full-screen overlay

**Slide type B · bg `#2C3E50` · avatar fills full canvas**

| Placeholder | Example |
|-------------|---------|
| `{{TITLE}}` | slide name (for `<title>` only) |
| `{{KEY_TEXT}}` | `Четыре вида ответственности. Могут наступить одновременно.` |
| `{{LOGO_HTML}}` | logo HTML |

**Use for**: Прямой старт, any intro scene where avatar is full-screen.
The key-text box appears bottom-right with dark bg + red border.

---

### `slide-c-content.html` — Content block (THE MAIN TEMPLATE)

**Slide type C · configurable bg · avatar zone left 600px · content right**

This is the workhorse. One slide per "Блок N — [Name]" scene.

| Placeholder | Value options |
|-------------|--------------|
| `{{BG_COLOR}}` | `#F2F2F2` (light) or `#1A0A0A` (criminal dark) |
| `{{ACCENT_COLOR}}` | category color (e.g. `#F39C12`) |
| `{{HEADING_COLOR}}` | `#2C3E50` (light bg) or `#FFFFFF` (dark bg) |
| `{{TEXT_COLOR}}` | `#2C3E50` (light) or `#FFFFFF` (dark) |
| `{{BODY_COLOR}}` | `#555555` (light) or `#CCCCCC` (dark) |
| `{{HEADING}}` | `Дисциплинарная ответственность` |
| `{{ICON_1}}` | phosphor icon name, e.g. `user-gear` |
| `{{LABEL_1}}` | `Кто применяет:` |
| `{{VALUE_1}}` | `Работодатель — директор, вышестоящий руководитель` |
| `{{ICON_2}}` | `list` |
| `{{LABEL_2}}` | `Виды:` |
| `{{VALUE_2}}` | `Замечание · Выговор · Расторжение трудового договора` |
| `{{ICON_3}}` | `lightbulb` |
| `{{LABEL_3}}` | `Пример:` |
| `{{VALUE_3}}` | example text |
| `{{LOGO_HTML}}` | logo HTML |

**Dark bg variant** (for Уголовная):
- `BG_COLOR` = `#1A0A0A`
- `HEADING_COLOR` = `#FFFFFF`
- `TEXT_COLOR` = `#FFFFFF`
- `BODY_COLOR` = `#CCCCCC`

---

## Script parsing guide

### Scenario table format (DOCX)

Each row has 4 columns. Extract from columns 3 and 4:

**Column 3 — Визуал / Слайд**: contains layout spec
- `Фон #XXXXXX` → `BG_COLOR`
- `Заголовок: «...»` → `HEADING` / `MAIN_TITLE`
- `Строка N — иконка NAME + «Label:» + «Value»` → row data
- accent color appears as `Полоска-метка #XXXXXX` or repeated in row icons

**Column 4 — Текст диктора**: contains narrator script (for reference only; not on slides)

### Block → template mapping

| Pattern in block name | Template | Notes |
|----------------------|----------|-------|
| `Заставка` | `slide-a-title.html` | Opening title |
| `Прямой старт` | `slide-b-overlay.html` | Intro avatar scene |
| `Блок N — [Name]` | `slide-c-content.html` | One per content block |
| `Итог`, `Слой 3` | `slide-a-summary.html` | Closing summary |

### Default icon mapping

| Content type | Icon name |
|-------------|-----------|
| Кто применяет (работодатель) | `user-gear` |
| Кто применяет (государство) | `gavel` |
| Кто применяет (суд) | `scales` |
| Виды (перечень) | `list` |
| Виды (штраф, деньги) | `currency-dollar` |
| Виды (лишение свободы) | `handcuffs` |
| Пример / lightbulb | `lightbulb` |
| Когда наступает | `warning` |
| Важно | `warning` |

---

## Generation workflow

When the user provides a narrator script:

### Step 1 — Parse scenes

Extract each scene block. For each, build a slide data object:

```json
{
  "filename": "slide-03-disciplinary.html",
  "template": "slide-c-content.html",
  "vars": {
    "BG_COLOR": "#F2F2F2",
    "ACCENT_COLOR": "#F39C12",
    "HEADING_COLOR": "#2C3E50",
    "TEXT_COLOR": "#2C3E50",
    "BODY_COLOR": "#555555",
    "HEADING": "Дисциплинарная ответственность",
    "ICON_1": "user-gear",
    "LABEL_1": "Кто применяет:",
    "VALUE_1": "Работодатель — директор, вышестоящий руководитель",
    "ICON_2": "list",
    "LABEL_2": "Виды:",
    "VALUE_2": "Замечание · Выговор · Расторжение трудового договора",
    "ICON_3": "lightbulb",
    "LABEL_3": "Пример:",
    "VALUE_3": "Руководитель участка регулярно допускал работников без инструктажа. Директор объявил выговор.",
    "LOGO_HTML": "<!-- place logo here -->"
  }
}
```

### Step 2 — Read template + substitute

For each slide:
1. Read the corresponding template file from `templates/`
2. Replace every `{{KEY}}` with `vars[KEY]`
3. Write result to `<output-dir>/html/slide-NN-name.html`

Name files with zero-padded index: `slide-01-title.html`, `slide-02-intro.html`, etc.

### Step 3 — Render to PNG

```bash
# Install puppeteer once
bun add puppeteer

# Render all slides
bun run scripts/render.mjs ./output/module-X/html ./output/module-X/png
```

This produces `slide-01-title.png` … `slide-NN-name.png` at 1920×1080.

### Step 4 — Upload to HeyGen

Upload each PNG as a "background" slide in HeyGen. The avatar is layered on top.
For Type C slides, the avatar should be placed in the **left 600px zone** (clean area).

---

## Logo setup

Place your logo file at `training-slides/logo.png` (height 45px).

In each generated HTML, set `LOGO_HTML` to:
```html
<img src="PATH_TO_LOGO/logo.png" height="45" alt="Logo">
```

Or for text-only fallback:
```html
<span style="font-family:Montserrat,sans-serif;font-weight:700;font-size:13pt;color:#6AAF3D;">COMPANY</span>
```

---

## Hard rules

1. **Left 600px of Type C slides = CLEAN.** No text, no graphics. HeyGen avatar zone.
2. **Always output at 1920×1080.** Never scale or crop.
3. **Filename format**: `slide-NN-slug.html` with zero-padded index.
4. **One file per scene block.** Don't merge blocks.
5. **Use exact hex values** from the design system. Don't approximate.
6. **waitUntil: 'networkidle0'** in render.mjs — required for Google Fonts + Phosphor to load.

---

## Worked example — Module 1.5

8 slides from scenario table "Ответственность руководителя — четыре вида":

| File | Template | Accent |
|------|----------|--------|
| `slide-01-title.html` | `slide-a-title.html` | — |
| `slide-02-intro.html` | `slide-b-overlay.html` | — |
| `slide-03-disciplinary.html` | `slide-c-content.html` | `#F39C12` |
| `slide-04-administrative.html` | `slide-c-content.html` | `#3498DB` |
| `slide-05-civil.html` | `slide-c-content.html` | `#9B59B6` |
| `slide-06-criminal.html` | `slide-c-content.html` | `#E74C3C` bg `#1A0A0A` |
| `slide-07-concurrent.html` | `slide-c-content.html` | `#6AAF3D` |
| `slide-08-summary.html` | `slide-a-summary.html` | — |
