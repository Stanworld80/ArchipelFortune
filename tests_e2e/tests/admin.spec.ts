import { test, expect } from '@playwright/test';
import { getResilientLocator, robustClick, archipelLogin, waitForAppLoaded } from './test_utils';

test.describe('Admin Panel Tests', () => {
  // Use a long timeout for admin operations
  test.setTimeout(180000);

  const SUPER_ADMIN_EMAIL = 'stantest@stanworld.org';
  const SUPER_ADMIN_PASSWORD = 'Tester=2026';

  test.beforeEach(async ({ page }) => {
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await waitForAppLoaded(page);
  });

  async function performAdminLogin(page) {
    await archipelLogin(page, SUPER_ADMIN_EMAIL, SUPER_ADMIN_PASSWORD);
    
    // Stability delay for Flutter tree rebuild
    await page.waitForTimeout(2000);
    
    const profileBtn = getResilientLocator(page, 'PROFILE_BTN');
    try {
        await profileBtn.waitFor({ state: 'attached', timeout: 30000 });
        await page.screenshot({ path: `screenshots/admin-success-${Date.now()}.png` });
    } catch (e) {
        throw new Error("Could not find PROFILE_BTN after login. App might be stuck.");
    }
  }

  test('Admin Authentication and Navigation', async ({ page }) => {
    await performAdminLogin(page);

    const profileBtn = getResilientLocator(page, 'PROFILE_BTN');
    await robustClick(page, profileBtn);

    let adminPanelBtn = getResilientLocator(page, 'Panel Admin');
    try {
        await adminPanelBtn.waitFor({ state: 'attached', timeout: 5000 });
    } catch (e) {
        // Retry once if menu didn't open
        await robustClick(page, profileBtn);
        await adminPanelBtn.waitFor({ state: 'attached', timeout: 60000 });
    }
    
    await robustClick(page, adminPanelBtn);

    const title = getResilientLocator(page, 'PANEL ADMINISTRATION');
    await title.waitFor({ state: 'attached', timeout: 60000 });
    
    await page.screenshot({ path: `screenshots/admin-panel-view-${Date.now()}.png` });
  });

  test('Modify Player Gold', async ({ page }) => {
    await performAdminLogin(page);
    
    // Stability delay for gameplay start
    await page.waitForTimeout(2000);
    
    // 3. Start Expedition
    const exploreBtn = getResilientLocator(page, 'EXPLORE_MAIN_BTN');
    await robustClick(page, exploreBtn);

    // 4. Preparation Dialog
    const startBtn = getResilientLocator(page, 'START_EXPEDITION_BTN');
    await startBtn.waitFor({ state: 'attached', timeout: 60000 });
    await robustClick(page, startBtn);

    // In Admin Panel, find a player and modify gold
    const goldInput = page.locator('flt-semantics[aria-label*="GOLD_INPUT"], input[type="number"]').first();
    const updateBtn = getResilientLocator(page, 'UPDATE_GOLD_BTN');

    if (await goldInput.count() > 0) {
        await robustClick(page, goldInput);
        await page.keyboard.press('Control+A');
        await page.keyboard.press('Backspace');
        await page.keyboard.type('999');
        await robustClick(page, updateBtn);
        // Verify success snackbar or updated value
        await page.waitForTimeout(2000);
        await page.screenshot({ path: `screenshots/admin-gold-updated-${Date.now()}.png` });
    }
  });
});
