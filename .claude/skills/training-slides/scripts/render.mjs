/**
 * render.mjs — batch render HTML slides to 1920×1080 PNG
 *
 * Usage:
 *   bun run render.mjs <slides-dir> [output-dir]
 *
 * Requires puppeteer:
 *   bun add puppeteer
 *
 * Example:
 *   bun run render.mjs ./output/module-1-5/html ./output/module-1-5/png
 */

import puppeteer from 'puppeteer';
import { readdir, mkdir } from 'fs/promises';
import { resolve, join, basename } from 'path';

const slidesDir = resolve(process.argv[2] ?? './slides');
const outputDir = resolve(process.argv[3] ?? './output/png');

await mkdir(outputDir, { recursive: true });

const files = (await readdir(slidesDir))
  .filter(f => f.endsWith('.html'))
  .sort();

if (files.length === 0) {
  console.error(`No HTML files found in ${slidesDir}`);
  process.exit(1);
}

console.log(`Rendering ${files.length} slides to ${outputDir}…`);

const browser = await puppeteer.launch({
  headless: 'new',
  args: ['--no-sandbox', '--disable-setuid-sandbox'],
});

for (const file of files) {
  const filePath = join(slidesDir, file);
  const outPath = join(outputDir, file.replace('.html', '.png'));

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080, deviceScaleFactor: 1 });

  // networkidle0 waits for Google Fonts + Phosphor icons to load
  await page.goto(`file://${filePath}`, { waitUntil: 'networkidle0', timeout: 15000 });

  await page.screenshot({ path: outPath, type: 'png' });
  await page.close();

  console.log(`  ✓ ${basename(outPath)}`);
}

await browser.close();
console.log('Done.');
