/* Generates: Инструкция_Видеостудия_ОТ_ТБ_ООС.docx */
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, BorderStyle, WidthType, ShadingType,
  PageNumber, PageBreak, LevelFormat
} = require('docx');
const fs = require('fs');

const OUT = __dirname + '/Инструкция_Видеостудия_ОТ_ТБ_ООС.docx';

// ── Colours ──────────────────────────────────────────────
const FONT   = 'Arial';
const NAVY   = '0D1B3E';
const BLUE   = '1A56DB';
const GR_D   = '166534';  // ОТ dark
const GR_L   = 'DCFCE7';  // ОТ light
const AM_D   = '9A3412';  // ТБ dark
const AM_L   = 'FEF3C7';  // ТБ light
const TL_D   = '134E4A';  // ООС dark
const TL_L   = 'CCFBF1';  // ООС light
const GY     = 'F8F9FA';  // neutral bg
const BD     = 'DEE2E6';  // border default

// ── Border helpers ────────────────────────────────────────
const NO_BORDER = { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' };
const nb = () => ({ top: NO_BORDER, bottom: NO_BORDER, left: NO_BORDER, right: NO_BORDER });
const sb = (c = BD) => ({ style: BorderStyle.SINGLE, size: 4, color: c });
const ab = (c = BD) => ({ top: sb(c), bottom: sb(c), left: sb(c), right: sb(c) });
const leftAccent = (c) => ({ top: sb(BD), bottom: sb(BD), left: { style: BorderStyle.SINGLE, size: 16, color: c }, right: sb(BD) });

// ── Paragraph helpers ─────────────────────────────────────
const run = (text, opts = {}) => new TextRun({
  text, font: FONT,
  size:    opts.size    || 22,
  bold:    opts.bold    || false,
  italics: opts.italic  || false,
  color:   opts.color   || NAVY,
});

const para = (text, opts = {}) => new Paragraph({
  children: [run(text, opts)],
  spacing:   { before: opts.before || 0, after: opts.after || 160 },
  alignment: opts.align,
  pageBreakBefore: opts.pageBreak || false,
});

const blank = (h = 160) => new Paragraph({ children: [], spacing: { after: h } });

const sectionHead = (text) => new Paragraph({
  children:  [run(text, { size: 40, bold: true, color: NAVY })],
  spacing:   { before: 0, after: 240 },
  border:    { bottom: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 4 } },
});

// ── Cell helper ───────────────────────────────────────────
const cell = (children, { bg, borders, width, va } = {}) => new TableCell({
  children: Array.isArray(children) ? children : [para(String(children))],
  borders:  borders || ab(),
  shading:  bg ? { fill: bg, type: ShadingType.CLEAR } : undefined,
  margins:  { top: 100, bottom: 100, left: 140, right: 140 },
  width:    width ? { size: width, type: WidthType.DXA } : undefined,
  verticalAlign: va,
});

// ── Step box ──────────────────────────────────────────────
// Widths: 900 + 8126 = 9026
const stepBox = (num, title, desc) => new Table({
  width: { size: 9026, type: WidthType.DXA },
  columnWidths: [900, 8126],
  rows: [new TableRow({
    children: [
      new TableCell({
        children: [new Paragraph({ children: [run(String(num), { size: 48, bold: true, color: 'FFFFFF' })], alignment: AlignmentType.CENTER })],
        borders: ab(BLUE),
        shading: { fill: BLUE, type: ShadingType.CLEAR },
        margins: { top: 120, bottom: 120, left: 100, right: 100 },
        width: { size: 900, type: WidthType.DXA },
        verticalAlign: 'center',
      }),
      new TableCell({
        children: [
          new Paragraph({ children: [run(title, { size: 24, bold: true, color: NAVY })], spacing: { after: 80 } }),
          new Paragraph({ children: [run(desc, { size: 20, color: '374151' })], spacing: { after: 0 } }),
        ],
        borders: ab(BD),
        shading: { fill: GY, type: ShadingType.CLEAR },
        margins: { top: 120, bottom: 120, left: 200, right: 140 },
        width: { size: 8126, type: WidthType.DXA },
      }),
    ],
  })],
});

// ── Category banner ───────────────────────────────────────
const catBanner = (text, dark) => new Table({
  width: { size: 9026, type: WidthType.DXA },
  columnWidths: [9026],
  rows: [new TableRow({
    children: [new TableCell({
      children: [new Paragraph({ children: [run(text, { size: 26, bold: true, color: 'FFFFFF' })], alignment: AlignmentType.CENTER })],
      borders: nb(),
      shading: { fill: dark, type: ShadingType.CLEAR },
      margins: { top: 140, bottom: 140, left: 200, right: 200 },
      width: { size: 9026, type: WidthType.DXA },
    })],
  })],
});

// ── Example table ─────────────────────────────────────────
// Widths: 2200 + 3926 + 2900 = 9026
const exampleTable = (rows, dark, light) => {
  const hRow = new TableRow({
    children: [
      ['Ситуация', 2200],
      ['Что написать Claude', 3926],
      ['Что вы получите', 2900],
    ].map(([t, w]) => new TableCell({
      children: [new Paragraph({ children: [run(t, { size: 20, bold: true, color: 'FFFFFF' })], alignment: AlignmentType.CENTER })],
      borders: ab(dark),
      shading: { fill: dark, type: ShadingType.CLEAR },
      margins: { top: 80, bottom: 80, left: 120, right: 120 },
      width: { size: w, type: WidthType.DXA },
    })),
  });

  const dataRows = rows.map(([sit, cmd, res]) => new TableRow({
    children: [
      new TableCell({
        children: [new Paragraph({ children: [run(sit, { size: 19, color: NAVY })], spacing: { after: 0 } })],
        borders: ab(BD), shading: { fill: 'FFFFFF', type: ShadingType.CLEAR },
        margins: { top: 100, bottom: 100, left: 120, right: 120 },
        width: { size: 2200, type: WidthType.DXA },
      }),
      new TableCell({
        children: [new Paragraph({ children: [run('«' + cmd + '»', { size: 19, color: '1A4DB5', italic: true })], spacing: { after: 0 } })],
        borders: ab(BD), shading: { fill: light, type: ShadingType.CLEAR },
        margins: { top: 100, bottom: 100, left: 120, right: 120 },
        width: { size: 3926, type: WidthType.DXA },
      }),
      new TableCell({
        children: [new Paragraph({ children: [run(res, { size: 19, color: NAVY })], spacing: { after: 0 } })],
        borders: ab(BD), shading: { fill: 'FFFFFF', type: ShadingType.CLEAR },
        margins: { top: 100, bottom: 100, left: 120, right: 120 },
        width: { size: 2900, type: WidthType.DXA },
      }),
    ],
  }));

  return new Table({
    width: { size: 9026, type: WidthType.DXA },
    columnWidths: [2200, 3926, 2900],
    rows: [hRow, ...dataRows],
  });
};

// ── Tip cell ─────────────────────────────────────────────
const tipCell = (title, body) => new TableCell({
  children: [
    new Paragraph({ children: [run(title, { size: 21, bold: true, color: NAVY })], spacing: { after: 80 } }),
    new Paragraph({ children: [run(body,  { size: 19, color: '374151' })], spacing: { after: 0 } }),
  ],
  borders: ab(BD),
  shading: { fill: GY, type: ShadingType.CLEAR },
  margins: { top: 160, bottom: 160, left: 200, right: 200 },
  width: { size: 4513, type: WidthType.DXA },
});

// ─────────────────────────────────────────────────────────
// Document
// ─────────────────────────────────────────────────────────
const doc = new Document({
  styles: {
    default: { document: { run: { font: FONT, size: 22 } } },
  },
  sections: [{
    properties: {
      page: {
        size: { width: 11906, height: 16838 },
        margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 },
      },
    },
    headers: {
      default: new Header({
        children: [new Paragraph({
          children: [run('Видеостудия для учебных материалов  |  ОТ • ТБ • ООС', { size: 18, color: '9CA3AF' })],
          border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: BD, space: 1 } },
        })],
      }),
    },
    footers: {
      default: new Footer({
        children: [new Paragraph({
          children: [
            run('Стр. ', { size: 18, color: '9CA3AF' }),
            new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 18, color: '9CA3AF' }),
            run(' из ', { size: 18, color: '9CA3AF' }),
            new TextRun({ children: [PageNumber.TOTAL_PAGES], font: FONT, size: 18, color: '9CA3AF' }),
          ],
          alignment: AlignmentType.RIGHT,
          border: { top: { style: BorderStyle.SINGLE, size: 4, color: BD, space: 1 } },
        })],
      }),
    },

    children: [

      // ════════════════════════════════════════════════════
      // ОБЛОЖКА
      // ════════════════════════════════════════════════════
      blank(2400),
      new Paragraph({
        children: [run('Видеостудия для учебных материалов', { size: 56, bold: true, color: NAVY })],
        alignment: AlignmentType.CENTER,
        spacing: { after: 200 },
      }),
      new Paragraph({
        children: [run('Охрана труда  •  Техника безопасности  •  Охрана окружающей среды', { size: 28, color: BLUE })],
        alignment: AlignmentType.CENTER,
        spacing: { after: 600 },
      }),
      new Paragraph({
        children: [run('Пошаговая инструкция — без знаний в программировании и ИИ', { size: 22, color: '6B7280', italic: true })],
        alignment: AlignmentType.CENTER,
        spacing: { after: 800 },
      }),
      // Colour strip: ОТ | ТБ | ООС  (3008 + 3010 + 3008 = 9026)
      new Table({
        width: { size: 9026, type: WidthType.DXA },
        columnWidths: [3008, 3010, 3008],
        rows: [new TableRow({
          children: [
            ['ОТ', GR_D, 3008],
            ['ТБ', AM_D, 3010],
            ['ООС', TL_D, 3008],
          ].map(([t, c, w]) => new TableCell({
            children: [new Paragraph({ children: [run(t, { size: 36, bold: true, color: 'FFFFFF' })], alignment: AlignmentType.CENTER })],
            borders: nb(),
            shading: { fill: c, type: ShadingType.CLEAR },
            margins: { top: 160, bottom: 160, left: 0, right: 0 },
            width: { size: w, type: WidthType.DXA },
          })),
        })],
      }),

      new Paragraph({ children: [new PageBreak()] }),

      // ════════════════════════════════════════════════════
      // РАЗДЕЛ 1: ЧТО ЭТО ТАКОЕ
      // ════════════════════════════════════════════════════
      sectionHead('Что это такое'),
      blank(120),
      para('Представьте, что у вас есть два помощника прямо внутри программы Claude Code:', { after: 200 }),

      // Two-box table: монтажёр | аниматор  (4513 + 4513 = 9026)
      new Table({
        width: { size: 9026, type: WidthType.DXA },
        columnWidths: [4513, 4513],
        rows: [new TableRow({
          children: [
            new TableCell({
              children: [
                new Paragraph({ children: [run('Помощник 1', { size: 20, bold: true, color: GR_D })], spacing: { after: 60 } }),
                new Paragraph({ children: [run('Монтажёр', { size: 32, bold: true, color: NAVY })], spacing: { after: 100 } }),
                new Paragraph({ children: [run('Слушает вашу запись, находит все «эм», «ну», паузы и оговорки — и аккуратно вырезает. Сам предлагает план, вы соглашаетесь — он делает.', { size: 20, color: '374151' })], spacing: { after: 0 } }),
              ],
              borders: ab(BD),
              shading: { fill: GR_L, type: ShadingType.CLEAR },
              margins: { top: 160, bottom: 160, left: 200, right: 200 },
              width: { size: 4513, type: WidthType.DXA },
            }),
            new TableCell({
              children: [
                new Paragraph({ children: [run('Помощник 2', { size: 20, bold: true, color: BLUE })], spacing: { after: 60 } }),
                new Paragraph({ children: [run('Дизайнер', { size: 32, bold: true, color: NAVY })], spacing: { after: 100 } }),
                new Paragraph({ children: [run('Берёт готовое видео и добавляет поверх красивую графику: заголовки, подписи, анимированные цифры, переходы между сценами.', { size: 20, color: '374151' })], spacing: { after: 0 } }),
              ],
              borders: ab(BD),
              shading: { fill: 'EEF2FF', type: ShadingType.CLEAR },
              margins: { top: 160, bottom: 160, left: 200, right: 200 },
              width: { size: 4513, type: WidthType.DXA },
            }),
          ],
        })],
      }),

      blank(200),
      // Highlighted note
      new Table({
        width: { size: 9026, type: WidthType.DXA },
        columnWidths: [9026],
        rows: [new TableRow({
          children: [new TableCell({
            children: [new Paragraph({ children: [run('Оба помощника — это Claude. Не нужно знать никаких команд или программирования. Пишите как обычному человеку — он понимает и делает.', { size: 22, bold: true, color: NAVY })], alignment: AlignmentType.CENTER, spacing: { after: 0 } })],
            borders: ab(BLUE),
            shading: { fill: 'EEF2FF', type: ShadingType.CLEAR },
            margins: { top: 160, bottom: 160, left: 240, right: 240 },
            width: { size: 9026, type: WidthType.DXA },
          })],
        })],
      }),

      blank(240),

      // ════════════════════════════════════════════════════
      // РАЗДЕЛ 2: ЧТО НУЖНО
      // ════════════════════════════════════════════════════
      sectionHead('Что нужно для начала'),
      blank(120),
      para('Список короткий. Больше ничего устанавливать не надо:', { after: 160 }),

      // Requirements table  (900 + 5626 + 2500 = 9026)
      new Table({
        width: { size: 9026, type: WidthType.DXA },
        columnWidths: [900, 5626, 2500],
        rows: [
          [
            '1', BLUE,
            [
              new Paragraph({ children: [run('Программа Claude Code', { size: 22, bold: true, color: NAVY })], spacing: { after: 40 } }),
              new Paragraph({ children: [run('Та самая программа, в которой вы читаете эту инструкцию', { size: 20, color: '6B7280' })], spacing: { after: 0 } }),
            ],
            '✓ Уже есть', GR_D, GR_L,
          ],
          [
            '2', BLUE,
            [
              new Paragraph({ children: [run('Видеофайл (если есть)', { size: 22, bold: true, color: NAVY })], spacing: { after: 40 } }),
              new Paragraph({ children: [run('Запись с телефона, камеры или экрана. Если видео нет — не беда, Claude создаст анимированный ролик из текста', { size: 20, color: '6B7280' })], spacing: { after: 0 } }),
            ],
            'Необязательно', AM_D, AM_L,
          ],
          [
            '3', BLUE,
            [
              new Paragraph({ children: [run('Папка с файлами', { size: 22, bold: true, color: NAVY })], spacing: { after: 40 } }),
              new Paragraph({ children: [run('Любая папка на компьютере — рабочий стол, Документы или сетевой диск. Положите видео туда и откройте Claude Code из этой папки', { size: 20, color: '6B7280' })], spacing: { after: 0 } }),
            ],
            'Любая папка', '6B7280', GY,
          ],
        ].map(([num, nc, descChildren, statusText, statusColor, statusBg]) => new TableRow({
          children: [
            new TableCell({
              children: [new Paragraph({ children: [run(num, { size: 32, bold: true, color: 'FFFFFF' })], alignment: AlignmentType.CENTER })],
              borders: ab(nc), shading: { fill: nc, type: ShadingType.CLEAR },
              margins: { top: 100, bottom: 100, left: 100, right: 100 },
              width: { size: 900, type: WidthType.DXA }, verticalAlign: 'center',
            }),
            new TableCell({
              children: descChildren,
              borders: ab(BD), shading: { fill: 'FFFFFF', type: ShadingType.CLEAR },
              margins: { top: 100, bottom: 100, left: 160, right: 120 },
              width: { size: 5626, type: WidthType.DXA },
            }),
            new TableCell({
              children: [new Paragraph({ children: [run(statusText, { size: 20, bold: true, color: statusColor })], alignment: AlignmentType.CENTER, spacing: { after: 0 } })],
              borders: ab(BD), shading: { fill: statusBg, type: ShadingType.CLEAR },
              margins: { top: 100, bottom: 100, left: 100, right: 100 },
              width: { size: 2500, type: WidthType.DXA }, verticalAlign: 'center',
            }),
          ],
        })),
      }),

      new Paragraph({ children: [new PageBreak()] }),

      // ════════════════════════════════════════════════════
      // РАЗДЕЛ 3: ПОШАГОВАЯ ИНСТРУКЦИЯ
      // ════════════════════════════════════════════════════
      sectionHead('Пошаговая инструкция'),
      blank(160),

      stepBox(1, 'Подготовьте видео',
        'Положите файл (или несколько) в отдельную папку. Подходят форматы .mp4, .mov, .avi, .mkv. Если видео нет — сразу переходите к шагу 2.'),
      blank(120),
      stepBox(2, 'Откройте Claude Code в этой папке',
        'В Claude Code откройте папку с вашими видео через меню «Открыть папку». Claude сразу увидит все видеофайлы внутри.'),
      blank(120),
      stepBox(3, 'Напишите что нужно — простыми словами',
        'Не нужно знать никаких команд. Пишите: «У меня есть запись инструктажа по ОТ, сделай из неё нормальное видео». Или: «Создай ролик о работе на высоте без видео».'),
      blank(120),
      stepBox(4, 'Прочитайте предложенный план',
        'Claude предложит что убрать, что добавить, как разбить видео. Если согласны — напишите «делай» или «ок». Если хотите изменить — скажите что именно.'),
      blank(120),
      stepBox(5, 'Заберите готовый файл',
        'Готовый ролик появится в папке edit/ рядом с вашими видео. Называется final.mp4. Исходники не трогаются. Файл готов для LMS, инструктажа или отправки коллегам.'),

      blank(240),
      // Warning box
      new Table({
        width: { size: 9026, type: WidthType.DXA },
        columnWidths: [9026],
        rows: [new TableRow({
          children: [new TableCell({
            children: [
              new Paragraph({ children: [run('Важно:', { size: 22, bold: true, color: AM_D })], spacing: { after: 80 } }),
              new Paragraph({ children: [run('Первый раз программа скачает модуль для распознавания речи (~145 МБ). Это займёт 1–2 минуты. Дальше всё работает быстро и без интернета. Ваши видео никуда не угодняют.', { size: 20, color: '374151' })], spacing: { after: 0 } }),
            ],
            borders: leftAccent(AM_D),
            shading: { fill: AM_L, type: ShadingType.CLEAR },
            margins: { top: 140, bottom: 140, left: 200, right: 200 },
            width: { size: 9026, type: WidthType.DXA },
          })],
        })],
      }),

      new Paragraph({ children: [new PageBreak()] }),

      // ════════════════════════════════════════════════════
      // РАЗДЕЛ 4: ПРИМЕРЫ ОТ
      // ════════════════════════════════════════════════════
      catBanner('ОХРАНА ТРУДА (ОТ) — Примеры запросов', GR_D),
      blank(160),
      exampleTable([
        [
          'Вводный инструктаж (30 мин, много пауз)',
          'У меня запись вводного инструктажа. Убери паузы и слова-паразиты. Раздели на темы: законодательная база, права работника, медосмотры, СИЗ. Добавь заголовок тем и субтитры',
          'Ролик с главами и субтитрами для LMS',
        ],
        [
          'Нужен ролик о СИЗ, записи нет',
          'Создай обучающее видео 90 секунд о средствах индивидуальной защиты: виды СИЗ, когда применять, как проверить. Без живого видео — анимация, текст и голос',
          'Готовый анимированный ролик с диктором',
        ],
        [
          '3 дубля одного инструктажа',
          'У меня 3 записи одного инструктажа. Выбери лучшие куски из каждой и смонтируй один финальный ролик',
          'Один чистый ролик из лучших моментов',
        ],
        [
          'Инструкция по несчастным случаям',
          'Создай ролик 2 минуты: что делать при несчастном случае, порядок оповещения, документы. Строгий стиль, субтитры',
          'Чёткая видеоинструкция',
        ],
      ], GR_D, GR_L),

      new Paragraph({ children: [new PageBreak()] }),

      // ════════════════════════════════════════════════════
      // РАЗДЕЛ 5: ПРИМЕРЫ ТБ
      // ════════════════════════════════════════════════════
      catBanner('ТЕХНИКА БЕЗОПАСНОСТИ (ТБ) — Примеры запросов', AM_D),
      blank(160),
      exampleTable([
        [
          'Инструктаж по пожарной безопасности с демонстрацией',
          'Есть видео с инструктажем и демонстрацией огнетушителя. Убери лишнее, добавь подписи на моменте с огнетушителем и схему эвакуации. Субтитры',
          'Ролик с графическими подсказками в нужных местах',
        ],
        [
          'Правила работы на высоте (текст регламента, записи нет)',
          'Создай ролик 2 минуты о правилах работы на высоте: проверка страховки, запрещённые действия, что делать при нарушении. Анимация, голос, субтитры',
          'Анимированный обучающий ролик',
        ],
        [
          'Заставка со статистикой несчастных случаев',
          'Создай 30-секундную заставку для инструктажа. Цифры: 4200 несчастных случаев в год, 78% из-за нарушений, 1 случай каждые 2 часа. Тёмный фон, анимированные цифры',
          'Короткий ударный ролик для старта инструктажа',
        ],
        [
          'Работа с химвеществами + предупреждения',
          'Есть видео с демонстрацией работы с кислотами. На моменте 3:20 добавь красную надпись «Обязательно СИЗ!». На 6:45 — подпись «Проветривание 15 минут»',
          'То же видео с предупреждающими подписями',
        ],
      ], AM_D, AM_L),

      new Paragraph({ children: [new PageBreak()] }),

      // ════════════════════════════════════════════════════
      // РАЗДЕЛ 6: ПРИМЕРЫ ООС
      // ════════════════════════════════════════════════════
      catBanner('ОХРАНА ОКРУЖАЮЩЕЙ СРЕДЫ (ООС) — Примеры запросов', TL_D),
      blank(160),
      exampleTable([
        [
          'Обращение с отходами (записи нет)',
          'Создай ролик 2 минуты об обращении с отходами: классы опасности 1–4, маркировка контейнеров, правила хранения, куда звонить при разливе. Строгий корпоративный стиль',
          'Ролик для обучения персонала',
        ],
        [
          'Запись экологического инструктажа (20 мин)',
          'Есть запись экологического инструктажа. Сделай профессиональный ролик: убери паузы, добавь заголовки разделов, нижние подписи с ключевыми фактами, субтитры',
          'Структурированный ролик с графикей',
        ],
        [
          'Инфографика по нормативам выбросов',
          'Создай 45-секундный ролик: ПДК для основных загрязнителей, санкции за превышение, план производственного контроля. Деловой стиль',
          'Короткий ролик с цифрами и графиками',
        ],
        [
          'Раздельный сбор отходов на предприятии',
          'Создай инструкционное видео: какой контейнер для чего, что нельзя смешивать, ответственность. Простой язык для рабочих',
          'Простая видеоинструкция понятным языком',
        ],
      ], TL_D, TL_L),

      new Paragraph({ children: [new PageBreak()] }),

      // ════════════════════════════════════════════════════
      // РАЗДЕЛ 7: СОВЕТЫ
      // ════════════════════════════════════════════════════
      sectionHead('Советы и подсказки'),
      blank(160),

      // Tips grid (3 rows × 2 cols), each row = 4513 + 4513 = 9026
      ...[
        [
          ['Говорите как человеку', 'Не нужно знать команд. Пишите: «Убери все паузы», «Добавь заголовок в начало», «Сделай субтитры покрупнее» — Claude всё поймёт.'],
          ['Можно присылать несколько дублей', 'Снимали несколько попыток? Кладите все файлы в папку. Claude выберет лучшие куски из каждого и смонтирует один финальный ролик.'],
        ],
        [
          ['Можно просить доработать', 'Посмотрели черновик — что-то не так? Напишите: «Убери этот кусок», «Переставь раздел в начало», «Сделай длиннее» — Claude переделает.'],
          ['Укажите язык если нужно', 'Если в видео говорят на русском, казахском или другом языке — скажите об этом. Claude правильно распознает речь.'],
        ],
        [
          ['Интернет не нужен для обработки', 'Распознавание речи работает локально, на вашем компьютере. Видео никуда не угодняется. Ваши записи остаются только у вас.'],
          ['Где найти готовый файл', 'Готовое видео всегда сохраняется в папке edit/ рядом с вашими видео. Файл называется final.mp4. Исходники не трогаются.'],
        ],
      ].map(([left, right]) => [
        new Table({
          width: { size: 9026, type: WidthType.DXA },
          columnWidths: [4513, 4513],
          rows: [new TableRow({
            children: [
              tipCell(left[0], left[1]),
              tipCell(right[0], right[1]),
            ],
          })],
        }),
        blank(120),
      ]).flat(),

      blank(240),
      // Final CTA
      new Table({
        width: { size: 9026, type: WidthType.DXA },
        columnWidths: [9026],
        rows: [new TableRow({
          children: [new TableCell({
            children: [
              new Paragraph({ children: [run('Готовы начать?', { size: 32, bold: true, color: 'FFFFFF' })], alignment: AlignmentType.CENTER, spacing: { after: 120 } }),
              new Paragraph({ children: [run('Откройте Claude Code, положите видео в папку и напишите:', { size: 22, color: 'FFFFFF' })], alignment: AlignmentType.CENTER, spacing: { after: 100 } }),
              new Paragraph({ children: [run('«У меня есть запись инструктажа, сделай из неё нормальное обучающее видео»', { size: 22, bold: true, color: 'FFFFFF', italic: true })], alignment: AlignmentType.CENTER, spacing: { after: 0 } }),
            ],
            borders: nb(),
            shading: { fill: NAVY, type: ShadingType.CLEAR },
            margins: { top: 280, bottom: 280, left: 240, right: 240 },
            width: { size: 9026, type: WidthType.DXA },
          })],
        })],
      }),

    ],
  }],
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync(OUT, buffer);
  console.log('OK: ' + OUT);
}).catch(err => {
  console.error('ERROR:', err.message);
  process.exit(1);
});
