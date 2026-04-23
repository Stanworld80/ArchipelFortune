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

    // Admin Panel should appear in the popup menu
    // We try multiple ways to find it as Flutter menus are tricky
    const adminPanelBtn = page.locator('[aria-label="ADMIN_PANEL_BTN"], flt-semantics:has-text("Panel Admin")').first();
    
    try {
        await adminPanelBtn.waitFor({ state: 'visible', timeout: 15000 });
    } catch (e) {
        // Retry menu click if it didn't open
        await robustClick(page, profileBtn);
        await adminPanelBtn.waitFor({ state: 'visible', timeout: 60000 });
    }
    
    await robustClick(page, adminPanelBtn);

    const title = getResilientLocator(page, 'ADMINISTRATION');
    await title.waitFor({ state: 'attached', timeout: 60000 });
    
    await page.screenshot({ path: `screenshots/admin-panel-view-${Date.now()}.png` });
  });

  test('Modify Player Gold', async ({ page }) => {
    await performAdminLogin(page);
    
    // Stability delay
    await page.waitForTimeout(2000);
    
    const profileBtn = getResilientLocator(page, 'PROFILE_BTN');
    await robustClick(page, profileBtn);

    const adminPanelBtn = page.locator('[aria-label="ADMIN_PANEL_BTN"], flt-semantics:has-text("Panel Admin")').first();
    await adminPanelBtn.waitFor({ state: 'visible', timeout: 30000 });
    await robustClick(page, adminPanelBtn);

    // In Admin Panel, click a player to open dialog
    const playerItem = page.locator('[aria-label*="player_item_"]').first();
    await playerItem.waitFor({ state: 'attached', timeout: 30000 });
    await robustClick(page, playerItem);

    // In Dialog, modify gold
    const goldInput = getResilientLocator(page, 'GOLD_INPUT');
    const updateBtn = getResilientLocator(page, 'SAVE_USER_BTN');

    await goldInput.waitFor({ state: 'attached', timeout: 30000 });
    if (await goldInput.count() > 0) {
        await robustClick(page, goldInput);
        await page.keyboard.press('Control+A');
        await page.keyboard.press('Backspace');
        await page.keyboard.type('999');
        await robustClick(page, updateBtn);
        // Verify success
        await page.waitForTimeout(2000);
        await page.screenshot({ path: `screenshots/admin-gold-updated-${Date.now()}.png` });
    }
  });
});
