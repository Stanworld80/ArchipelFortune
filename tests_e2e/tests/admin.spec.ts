import { test, expect } from '@playwright/test';
import { getResilientLocator, robustClick, archipelLogin, waitForAppLoaded, clickMenuItem, dumpSemanticTree } from './test_utils';


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
    await page.waitForTimeout(3000);
    
    const profileBtn = await getResilientLocator(page, 'PROFILE_BTN');
    try {
        await profileBtn.waitFor({ state: 'attached', timeout: 45000 });
        console.log("Login successful, PROFILE_BTN found.");
    } catch (e) {
        console.log("Could not find PROFILE_BTN after login. Dumping tree...");
        await dumpSemanticTree(page);
        await page.screenshot({ path: `screenshots/failed-login-${Date.now()}.png` });
        throw new Error("Could not find PROFILE_BTN after login. App might be stuck on login page or failed to authenticate.");
    }
  }

  test('Admin Authentication and Navigation', async ({ page }) => {
    await performAdminLogin(page);

    // Admin Panel should appear in the popup menu
    await clickMenuItem(page, 'PROFILE_BTN', 'ADMIN_PANEL_BTN');

    // Wait for the Administration title to confirm we are on the dashboard
    const title = await getResilientLocator(page, 'ADMINISTRATION');
    try {
        await title.waitFor({ state: 'visible', timeout: 60000 });
        console.log("Successfully navigated to Admin Panel.");
    } catch (e) {
        console.log("Admin title not found. Dumping tree...");
        await dumpSemanticTree(page);
        throw e;
    }
    
    await page.screenshot({ path: `screenshots/admin-panel-view-${Date.now()}.png` });
  });

  test('Modify Player Gold', async ({ page }) => {
    await performAdminLogin(page);
    
    // Stability delay
    await page.waitForTimeout(2000);
    
    // Use clickMenuItem to open admin panel
    await clickMenuItem(page, 'PROFILE_BTN', 'ADMIN_PANEL_BTN');


    // In Admin Panel, click a player to open dialog
    let playerItem = await getResilientLocator(page, 'player_item_');
    
    if (await playerItem.count() === 0) {
        console.log("No player_item_ found by getResilientLocator. Printing all labels:");
        const labels = await page.evaluate(() => {
            return Array.from(document.querySelectorAll('flt-semantics[aria-label]'))
                .map(n => n.getAttribute('aria-label'));
        });
        console.log(labels.filter(l => l && l.length > 0).join(', '));
        
        // Fallback to a broader selector
        playerItem = page.locator('[aria-label*="player_item_"]').first();
    }

    await playerItem.waitFor({ state: 'attached', timeout: 30000 });
    await robustClick(page, playerItem);

    // In Dialog, modify gold
    const goldInput = await getResilientLocator(page, 'GOLD_INPUT');
    const updateBtn = await getResilientLocator(page, 'SAVE_USER_BTN');

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
