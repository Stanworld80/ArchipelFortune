# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: admin.spec.ts >> Admin Panel Tests >> Modify Player Gold
- Location: tests\admin.spec.ts:73:7

# Error details

```
TimeoutError: locator.waitFor: Timeout 20000ms exceeded.
Call log:
  - waiting for locator('[aria-label*="START_EXPEDITION_BTN"], flt-semantics:has-text("START_EXPEDITION_BTN")').first()

```

# Page snapshot

```yaml
- generic [active] [ref=e4]:
  - generic:
    - generic:
      - generic:
        - generic:
          - generic:
            - button "Show menu PROFILE_BTN" [ref=e5]
            - img [ref=e6]
            - group:
              - generic [ref=e7]:
                - generic: APP_TITLE L'Archipel de la Fortune
              - generic [ref=e8]:
                - generic: Capitaine
              - generic [ref=e9]:
                - generic: 🪙
              - generic [ref=e10]:
                - generic: 50 Pièces d'Or
              - generic [ref=e11]:
                - generic: SUPERADMIN
              - button "EXPLORE_MAIN_BTN" [ref=e12]
              - generic [ref=e13]:
                - generic: Une aventure d'exploration, de découvertes et de fortune vous attend...
              - generic [ref=e14]:
                - generic: "Version 0.1.3+11 • Mise à jour : 12/04/2026 16:56 • © 2026 SSI"
```

# Test source

```ts
  1   | import { test, expect } from '@playwright/test';
  2   | import { getResilientLocator, robustClick, archipelLogin } from './test_utils';
  3   | 
  4   | test.describe('Admin Panel Tests', () => {
  5   |   // Use a long timeout for admin operations
  6   |   test.setTimeout(180000);
  7   | 
  8   |   const SUPER_ADMIN_EMAIL = 'stantest@stanworld.org';
  9   |   const SUPER_ADMIN_PASSWORD = 'Tester=2026';
  10  | 
  11  |   test.beforeEach(async ({ page }) => {
  12  |     await page.goto('/', { waitUntil: 'load', timeout: 60000 });
  13  |     await page.waitForSelector('flutter-view', { timeout: 30000 });
  14  | 
  15  |     // Enable accessibility
  16  |     await page.evaluate(() => {
  17  |       const findAndClick = () => {
  18  |         const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
  19  |         const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility' || el.textContent?.includes('accessibility'));
  20  |         if (accessBtn instanceof HTMLElement) {
  21  |           accessBtn.click();
  22  |           return true;
  23  |         }
  24  |         return false;
  25  |       };
  26  |       if (!findAndClick()) {
  27  |         window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
  28  |         setTimeout(findAndClick, 1000);
  29  |       }
  30  |     });
  31  | 
  32  |     await page.waitForTimeout(3000);
  33  |   });
  34  | 
  35  |   async function performAdminLogin(page) {
  36  |     await archipelLogin(page, SUPER_ADMIN_EMAIL, SUPER_ADMIN_PASSWORD);
  37  |     
  38  |     // Stability delay for Flutter tree rebuild
  39  |     await page.waitForTimeout(2000);
  40  |     
  41  |     const profileBtn = getResilientLocator(page, 'PROFILE_BTN');
  42  |     try {
  43  |         await profileBtn.waitFor({ state: 'attached', timeout: 30000 });
  44  |         await page.screenshot({ path: `screenshots/admin-success-${Date.now()}.png` });
  45  |     } catch (e) {
  46  |         throw new Error("Could not find PROFILE_BTN after login. App might be stuck.");
  47  |     }
  48  |   }
  49  | 
  50  |   test('Admin Authentication and Navigation', async ({ page }) => {
  51  |     await performAdminLogin(page);
  52  | 
  53  |     const profileBtn = getResilientLocator(page, 'PROFILE_BTN');
  54  |     await robustClick(page, profileBtn);
  55  | 
  56  |     let adminPanelBtn = getResilientLocator(page, 'Panel Admin');
  57  |     try {
  58  |         await adminPanelBtn.waitFor({ state: 'attached', timeout: 5000 });
  59  |     } catch (e) {
  60  |         // Retry once if menu didn't open
  61  |         await robustClick(page, profileBtn);
  62  |         await adminPanelBtn.waitFor({ state: 'attached', timeout: 15000 });
  63  |     }
  64  |     
  65  |     await robustClick(page, adminPanelBtn);
  66  | 
  67  |     const title = getResilientLocator(page, 'PANEL ADMINISTRATION');
  68  |     await title.waitFor({ state: 'attached', timeout: 20000 });
  69  |     
  70  |     await page.screenshot({ path: `screenshots/admin-panel-view-${Date.now()}.png` });
  71  |   });
  72  | 
  73  |   test('Modify Player Gold', async ({ page }) => {
  74  |     await performAdminLogin(page);
  75  |     
  76  |     // Stability delay for gameplay start
  77  |     await page.waitForTimeout(2000);
  78  |     
  79  |     // 3. Start Expedition
  80  |     const exploreBtn = getResilientLocator(page, 'EXPLORE_MAIN_BTN');
  81  |     await robustClick(page, exploreBtn);
  82  | 
  83  |     // 4. Preparation Dialog
  84  |     const startBtn = getResilientLocator(page, 'START_EXPEDITION_BTN');
> 85  |     await startBtn.waitFor({ state: 'attached', timeout: 20000 });
      |                    ^ TimeoutError: locator.waitFor: Timeout 20000ms exceeded.
  86  |     await robustClick(page, startBtn);
  87  | 
  88  |     // In Admin Panel, find a player and modify gold
  89  |     const goldInput = page.locator('flt-semantics[aria-label*="GOLD_INPUT"], input[type="number"]').first();
  90  |     const updateBtn = getResilientLocator(page, 'UPDATE_GOLD_BTN');
  91  | 
  92  |     if (await goldInput.count() > 0) {
  93  |         await robustClick(page, goldInput);
  94  |         await page.keyboard.press('Control+A');
  95  |         await page.keyboard.press('Backspace');
  96  |         await page.keyboard.type('999');
  97  |         await robustClick(page, updateBtn);
  98  |         // Verify success snackbar or updated value
  99  |         await page.waitForTimeout(2000);
  100 |         await page.screenshot({ path: `screenshots/admin-gold-updated-${Date.now()}.png` });
  101 |     }
  102 |   });
  103 | });
  104 | 
```