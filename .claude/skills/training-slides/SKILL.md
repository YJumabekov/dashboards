---
name: training-slides
description: >
  Convert narrator scripts (scenario tables) into corporate-style Canva presentation slides
  ready for HeyGen avatar video backgrounds. Accepts DOCX scenario tables or inline text.
  Parses scene blocks → maps to slide types (Title / Avatar-overlay / Content / Summary) →
  generates via Canva MCP → exports 1920×1080 PNG for HeyGen upload.
  Trigger: "создай слайды", "слайды для HeyGen", "подготовь шаблоны", "обучающие слайды",
  "training slides", "lesson slides", "/training-slides".
  NOT for generic marketing presentations — specifically for HeyGen training video backgrounds
  with a left avatar zone and right content zone.
metadata: { "tags": "canva, slides, training, heygen, corporate, design, education" }
---

# training-slides

Turn a narrator script (scenario table) into a complete set of corporate-style Canva slides,
exported as 1920×1080 PNG files ready to upload as HeyGen avatar video backgrounds.

---

## When to trigger

Invoke this skill when the user:
- Pastes or attaches a narrator script / scenario table (DOCX or inline text)
- Says "создай слайды", "сделай шаблоны", "слайды для HeyGen", "подготовь слайды"
- Says "training slides", "lesson slides", "slides for HeyGen"
- Types `/training-slides`

---

## Corporate design system

All slides use this fixed system — do not deviate without explicit user instruction.

### Canvas
- Size: **1920 × 1080 px** (16:9)
- Logo: top-right corner, 45px

### Colors
| Token | Hex | Usage |
|-------|-----|-------|
| bg-dark | `#2C3E50` | Title/summary/intro backgrounds |
| bg-light | `#F2F2F2` | Content block backgrounds |
| bg-criminal | `#1A0A0A` | Uголовная ответственность block |
| accent-green | `#6AAF3D` | Main brand accent, icons, underlines |
| text-white | `#FFFFFF` | On dark backgrounds |
| text-dark | `#2C3E50` | On light backgrounds |
| text-body | `#555555` | Body/example text on light bg |
| text-light-gray | `#CCCCCC` | Body text on dark bg |

### Category accent colors
| Category | Hex |
|----------|-----|
| Дисциплинарная | `#F39C12` (amber) |
| Административная | `#3498DB` (blue) |
| Гражданско-правовая | `#9B59B6` (purple) |
| Уголовная | `#E74C3C` (red) |
| Summary/General | `#6AAF3D` (green) |

### Typography
- **Headings**: Montserrat Bold
- **Body**: Plus Jakarta Sans

### Icons
Phosphor icon library. Common: gavel, user-gear, list, lightbulb, warning, handcuffs, scales, currency-dollar, money.

---

## Slide type catalog

### Type A — Title / Summary (dark background, centered)

**Use for**: Opening slide ("Заставка"), closing summary ("Итог")

Layout on `#2C3E50` background:
- Logo top-right (45px)
- Icon: accent-green, 52px, centered
- Module label: Plus Jakarta Sans 20pt, `#6AAF3D` (e.g. "Модуль 1 · Подтема 1.5")
- Main title: Montserrat Bold 38pt, white (e.g. "Ответственность руководителя")
- Subtitle: Montserrat Bold 28pt, white (e.g. "— четыре вида")

For **summary variant** (Итог):
- Icon + key 3-word phrase: Montserrat Bold 32pt white
- Horizontal line: `#6AAF3D` 80px × 3px
- Body summary text: Plus Jakarta Sans 19pt `#CCCCCC`, max-width 820px, line-height 1.8
- Navigation footer: "→ Далее: ..." Plus Jakarta Sans 16pt `#6AAF3D`

### Type B — Avatar overlay (dark bg, full-screen avatar area)

**Use for**: "Прямой старт" / intro blocks where avatar dominates

Layout on `#2C3E50` background:
- Avatar zone: full screen (HeyGen places avatar; slide is the background)
- Logo top-right
- Text box bottom-right (x=1470, y=740px): 
  - Background: `rgba(0,0,0,0.7)`
  - Border: `#E74C3C` 2px, border-radius 8px, padding 14px, width 420px
  - Text: Plus Jakarta Sans 17pt white — key sentence from narrator

### Type C — Content block (light bg, avatar left / content right)

**Use for**: All "Блок N — [Name]" segments

**This is the primary layout for HeyGen** — avatar appears on the left, slide content on the right.

Layout on `#F2F2F2` background (or `#1A0A0A` for criminal):
- **Avatar zone**: x=0–600px, full height — KEEP CLEAN, no text/graphics here
- **Color strip**: x=600–636px, full height — category accent color (solid)
- **Content zone**: x=640–1890px
  - Heading: category name — Montserrat Bold 22pt, `#2C3E50` (white on dark bg), y≈55px
  - Underline: accent color, 320px × 3px
  - **Row 1** (y≈130px): icon 30px + "Кто применяет:" Montserrat SemiBold 17pt + value Plus Jakarta Sans 16pt
  - **Row 2** (y≈235px): icon 30px + "Виды:" + value
  - **Row 3** (y≈340px): icon 30px + "Пример:" + example text Plus Jakarta Sans 16pt `#555`
  - Rows fade in staggered (+0.5s per row) in video

---

## Script parsing guide

### Input format: scenario table (from DOCX)

Each row has 4 columns:
1. **Тайм-код** — time range (e.g. "1:30–2:25")
2. **Блок / Хронометраж** — block name + duration
3. **Визуал / Слайд** — full visual specification
4. **Текст диктора** — narrator script

### Block → slide type mapping

| Block name pattern | Slide type |
|--------------------|-----------|
| Заставка | A — Title |
| Прямой старт | B — Avatar overlay |
| Блок N — [Name] | C — Content |
| Итог, Слой 3, Conclusion | A — Summary |

### Content extraction from visual spec

From "Визуал / Слайд" column, extract:
- **Background color** (Фон #XXXXXX)
- **Heading text** (Заголовок: «...»)
- **Row content** (Строка 1/2/3: icon + label + value)
- **Category** (determines accent color)

From "Текст диктора" column, extract:
- **Key sentence** (for Type B text box overlay)
- **Summary text** (for Type A closing slide)

---

## Canva MCP workflow

### Step 1 — Check brand kit

```
list-brand-kits(user_intent="Check for corporate brand kit with #2C3E50 and #6AAF3D colors")
```

- If brand kit found with matching colors: use its `id` as `brand_kit_id` in Step 3
- If not found: proceed without — include full color/font specs in slide descriptions

### Step 2 — Build outline and request review

Parse all scene blocks into a `presentation_outlines` array. Then:

```
request-outline-review(
  topic: "[Module name]",
  audience: "...",
  style: "Corporate dark navy, Montserrat Bold, 1920×1080 HeyGen backgrounds",
  length: "[N] slides covering [topic]",
  design_type: "presentation",
  presentation_outlines: [ ... ]   ← see format below
)
```

**Wait for user to approve the outline in the widget before proceeding.**

### Step 3 — Generate presentation

After outline approval:

```
generate-design-structured(
  topic: "[Module name]",
  audience: "[target audience]",
  style: "Corporate dark navy (#2C3E50) background, green accent (#6AAF3D), Montserrat Bold headings, Plus Jakarta Sans body, 1920×1080 HeyGen avatar video background",
  length: "[N] slides",
  design_type: "presentation",
  presentation_outlines: [ ... same array ],
  brand_kit_id: "[id if found]",
  user_intent: "Create HeyGen training video background slides"
)
```

### Step 4 — Confirm export formats

```
get-export-formats(design_id: "[returned id]", user_intent="Check PNG export support")
```

### Step 5 — Export as PNG

```
export-design(
  design_id: "[id]",
  format: {
    type: "png",
    width: 1920,
    height: 1080,
    export_quality: "pro"
  },
  user_intent: "Export all slides as 1920×1080 PNG for HeyGen"
)
```

Deliver all download URLs to user.

---

## Slide description format for presentation_outlines

Each slide object must include a detailed `description` so Canva AI generates the right layout:

### Type A — Title slide
```json
{
  "title": "Ответственность руководителя — четыре вида",
  "description": "TYPE-A TITLE SLIDE. Dark navy background #2C3E50. Centered layout. Logo top-right 45px. Green gavel icon #6AAF3D 52px centered. Module label 'Модуль 1 · Подтема 1.5' Plus Jakarta Sans 20pt #6AAF3D. Main title 'Ответственность руководителя' Montserrat Bold 38pt white. Subtitle '— четыре вида' Montserrat Bold 28pt white. Clean professional corporate look. 1920×1080px."
}
```

### Type B — Avatar overlay slide
```json
{
  "title": "Прямой старт — введение",
  "description": "TYPE-B AVATAR OVERLAY. Dark navy background #2C3E50 full screen — this is a HeyGen avatar background, keep mostly clean. Logo top-right. Text box bottom-right corner (420px wide): semi-transparent dark background rgba(0,0,0,0.7), red border #E74C3C 2px rounded, padding 14px. Text inside: 'Четыре вида ответственности. Могут наступить одновременно.' Plus Jakarta Sans 17pt white."
}
```

### Type C — Content block slide
```json
{
  "title": "Дисциплинарная ответственность",
  "description": "TYPE-C CONTENT SLIDE. Light background #F2F2F2. LEFT 600px (31% of width) = CLEAN AVATAR ZONE — NO TEXT OR GRAPHICS HERE, solid #F2F2F2 only. Narrow vertical accent strip at x=600 (36px wide), full height, color #F39C12 (amber). RIGHT content zone from x=640: Heading 'Дисциплинарная ответственность' Montserrat Bold 22pt #2C3E50. Amber underline 320px. Row 1: person icon #F39C12 + 'Кто применяет:' SemiBold 17pt + 'Работодатель — директор, вышестоящий руководитель' 16pt. Row 2: list icon + 'Виды:' + 'Замечание · Выговор · Расторжение трудового договора'. Row 3: lightbulb icon + 'Пример:' + 'Руководитель участка регулярно допускал работников без инструктажа. Директор объявил выговор.' Plus Jakarta Sans 16pt #555."
}
```

### Type A — Summary slide
```json
{
  "title": "Итог — Четыре вида. Одновременно. Лично.",
  "description": "TYPE-A SUMMARY SLIDE. Dark navy background #2C3E50. Centered layout. Logo top-right. Green gavel icon #6AAF3D 52px. Key phrase 'Четыре вида. Одновременно. Лично.' Montserrat Bold 32pt white. Green horizontal line #6AAF3D 80px × 3px. Summary body text 'Дисциплинарная, административная, гражданско-правовая, уголовная. Каждая — из разного источника. Каждая — независимо от других.' Plus Jakarta Sans 19pt #CCCCCC, max-width 820px, line-height 1.8. Footer navigation '→ Далее: Практическое задание · Итоговый тест Модуля 1' Plus Jakarta Sans 16pt #6AAF3D."
}
```

---

## Hard rules

1. **Never put text or graphics in the avatar zone (left 600px of Type C slides).** HeyGen places the avatar there — any content will be hidden.
2. **Always export at 1920×1080.** HeyGen requires 16:9 full HD.
3. **Do not call `generate-design-structured` before the user approves the outline** via the `request-outline-review` widget.
4. **Keep slide count equal to scene block count.** One slide per HeyGen scene.
5. **Use exact hex colors from the design system** — do not approximate.

---

## Worked example: Module 1.5 "Ответственность руководителя — четыре вида"

8 slides from the scenario table:

| Slide | Block | Type | Accent |
|-------|-------|------|--------|
| 1 | Заставка | A — Title | #6AAF3D |
| 2 | Прямой старт | B — Avatar overlay | #E74C3C |
| 3 | Блок 1 — Дисциплинарная | C — Content | #F39C12 |
| 4 | Блок 2 — Административная | C — Content | #3498DB |
| 5 | Блок 3 — Гражданско-правовая | C — Content | #9B59B6 |
| 6 | Блок 4 — Уголовная | C — Content (bg #1A0A0A) | #E74C3C |
| 7 | Блок 5 — Одновременно | C — Content | #6AAF3D |
| 8 | Итог + Слой 3 | A — Summary | #6AAF3D |
