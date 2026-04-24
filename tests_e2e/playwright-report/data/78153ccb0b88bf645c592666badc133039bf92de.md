# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: admin.spec.ts >> Admin Panel Tests >> Modify Player Gold
- Location: tests\admin.spec.ts:58:7

# Error details

```
TimeoutError: locator.waitFor: Timeout 30000ms exceeded.
Call log:
  - waiting for locator('flt-semantics, [role="menuitem"], [role="button"]').filter({ hasText: /Panel Admin/i }).first() to be visible

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
              - generic:
                - generic: APP_TITLE L'Archipel de la Fortune
              - generic:
                - generic: Capitaine
              - generic:
                - generic: 🪙
              - generic:
                - generic: 5000 Pièces d'Or
              - generic:
                - generic: SUPERADMIN
              - button "EXPLORE_MAIN_BTN" [ref=e7]:
                - button [ref=e8]
              - generic:
                - generic: Une aventure d'exploration, de découvertes et de fortune vous attend...
              - generic:
                - generic: "Version 0.1.3+11 • Mise à jour : 12/04/2026 16:56 • © 2026 SSI"
```

# Test source

```ts
  1  | import { test, expect } from '@playwright/test';
  2  | import { getResilientLocator, robustClick, archipelLogin, waitForAppLoaded } from './test_utils';
  3  | 
  4  | test.describe('Admin Panel Tests', () => {
  5  |   // Use a long timeout for admin operations
  6  |   test.setTimeout(180000);
  7  | 
  8  |   const SUPER_ADMIN_EMAIL = 'stantest@stanworld.org';
  9  |   const SUPER_ADMIN_PASSWORD = 'Tester=2026';
  10 | 
  11 |   test.beforeEach(async ({ page }) => {
  12 |     await page.goto('/', { waitUntil: 'load', timeout: 60000 });
  13 |     await waitForAppLoaded(page);
  14 |   });
  15 | 
  16 |   async function performAdminLogin(page) {
  17 |     await archipelLogin(page, SUPER_ADMIN_EMAIL, SUPER_ADMIN_PASSWORD);
  18 |     
  19 |     // Stability delay for Flutter tree rebuild
  20 |     await page.waitForTimeout(2000);
  21 |     
  22 |     const profileBtn = getResilientLocator(page, 'PROFILE_BTN');
  23 |     try {
  24 |         await profileBtn.waitFor({ state: 'attached', timeout: 30000 });
  25 |         await page.screenshot({ path: `screenshots/admin-success-${Date.now()}.png` });
  26 |     } catch (e) {
  27 |         throw new Error("Could not find PROFILE_BTN after login. App might be stuck.");
  28 |     }
  29 |   }
  30 | 
  31 |   test('Admin Authentication and Navigation', async ({ page }) => {
  32 |     await performAdminLogin(page);
  33 | 
  34 |     const profileBtn = getResilientLocator(page, 'PROFILE_BTN');
  35 |     await robustClick(page, profileBtn);
  36 | 
  37 |     // Admin Panel should appear in the popup menu
  38 |     // We try multiple ways to find it as Flutter menus are tricky
  39 |     const adminPanelBtn = page.locator('flt-semantics, [role="menuitem"], [role="button"]').filter({ hasText: /Panel Admin/i }).first();
  40 |     
  41 |     try {
  42 |         await adminPanelBtn.waitFor({ state: 'visible', timeout: 15000 });
  43 |     } catch (e) {
  44 |         // Retry menu click if it didn't open - use a simpler click this time
  45 |         await profileBtn.click({ force: true });
  46 |         await page.waitForTimeout(1000);
  47 |         await adminPanelBtn.waitFor({ state: 'visible', timeout: 60000 });
  48 |     }
  49 |     
  50 |     await robustClick(page, adminPanelBtn);
  51 | 
  52 |     const title = getResilientLocator(page, 'ADMINISTRATION');
  53 |     await title.waitFor({ state: 'attached', timeout: 60000 });
  54 |     
  55 |     await page.screenshot({ path: `screenshots/admin-panel-view-${Date.now()}.png` });
  56 |   });
  57 | 
  58 |   test('Modify Player Gold', async ({ page }) => {
  59 |     await performAdminLogin(page);
  60 |     
  61 |     // Stability delay
  62 |     await page.waitForTimeout(2000);
  63 |     
  64 |     const profileBtn = getResilientLocator(page, 'PROFILE_BTN');
  65 |     await robustClick(page, profileBtn);
  66 | 
  67 |     const adminPanelBtn = page.locator('flt-semantics, [role="menuitem"], [role="button"]').filter({ hasText: /Panel Admin/i }).first();
> 68 |     await adminPanelBtn.waitFor({ state: 'visible', timeout: 30000 });
     |                         ^ TimeoutError: locator.waitFor: Timeout 30000ms exceeded.
  69 |     await robustClick(page, adminPanelBtn);
  70 | 
  71 |     // In Admin Panel, click a player to open dialog
  72 |     const playerItem = page.locator('[aria-label*="player_item_"]').first();
  73 |     await playerItem.waitFor({ state: 'attached', timeout: 30000 });
  74 |     await robustClick(page, playerItem);
  75 | 
  76 |     // In Dialog, modify gold
  77 |     const goldInput = getResilientLocator(page, 'GOLD_INPUT');
  78 |     const updateBtn = getResilientLocator(page, 'SAVE_USER_BTN');
  79 | 
  80 |     await goldInput.waitFor({ state: 'attached', timeout: 30000 });
  81 |     if (await goldInput.count() > 0) {
  82 |         await robustClick(page, goldInput);
  83 |         await page.keyboard.press('Control+A');
  84 |         await page.keyboard.press('Backspace');
  85 |         await page.keyboard.type('999');
  86 |         await robustClick(page, updateBtn);
  87 |         // Verify success
  88 |         await page.waitForTimeout(2000);
  89 |         await page.screenshot({ path: `screenshots/admin-gold-updated-${Date.now()}.png` });
  90 |     }
  91 |   });
  92 | });
  93 | 
```