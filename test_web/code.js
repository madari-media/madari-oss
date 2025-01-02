import puppeteer from 'puppeteer';

(async () => {
  const browser = await puppeteer.launch({
    devtools: true,
    headless: false,
    defaultViewport: null,
    args: ['--start-maximized'],
  });
  const page = await browser.newPage();
  await page.goto('https://madari-dev.pages.dev');
  await page.bringToFront();
  await page.waitForTimeout(10000000);
  await browser.close();
})();
