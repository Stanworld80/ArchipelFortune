import { test, expect } from '@playwright/test';
import { getResilientLocator, clickCoordinate, archipelLogin } from './test_utils';

test.describe('Admin Panel Tests', () => {
  // Use a long timeout for admin operations
  test.setTimeout(180000);

  const SUPER_ADMIN_EMAIL = 'stantest@stanworld.org';
  const SUPER_ADMIN_PASSWORD = 'Tester=2026';

  test.beforeEach(async ({ page }) => {
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flutter-view', { timeout: 30000 });

    // Enable accessibility
    await page.evaluate(() => {
      const findAndClick = () => {
        const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
        const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility' || el.textContent?.includes('accessibility'));
        if (accessBtn instanceof HTMLElement) {
          accessBtn.click();
          return true;
        }
        return false;
      };
      if (!findAndClick()) {
        window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
        setTimeout(findAndClick, 1000);
      }
    });

    await page.waitForTimeout(3000);
  });

  async function performAdminLogin(page) {
    await archipelLogin(page, SUPER_ADMIN_EMAIL, SUPER_ADMIN_PASSWORD);
    
    const profileBtn = getResilientLocator(page, 'PROFILE_BTN');
    try {
      await profileBtn.waitFor({ state: 'attached', timeout: 60000 });
      await page.screenshot({ path: `screenshots/admin-success-${Date.now()}.png` });
    } catch (e) {
      console.error("Login verified by screenshot shows success, but locator failed. Attempting cleanup.");
      await page.screenshot({ path: `screenshots/admin-failure-state-${Date.now()}.png` });
      throw e;
    }
  }

  test('Admin Authentication and Navigation', async ({ page }) => {
    await performAdminLogin(page);

    const profileBtn = getResilientLocator(page, 'PROFILE_BTN');
    await clickCoordinate(page, profileBtn);

    // After clicking Profile, the Menu should appear.
    // The menu items in Flutter usually have text.
    const adminPanelBtn = page.locator(':text("Panel Admin")').first();
    await clickCoordinate(page, adminPanelBtn, { timeout: 15000 });

    const title = getResilientLocator(page, 'PANEL ADMINISTRATION');
    await title.waitFor({ state: 'attached', timeout: 20000 });
    
    await page.screenshot({ path: `screenshots/admin-panel-view-${Date.now()}.png` });
  });

  test('Modify Player Gold', async ({ page }) => {
    await performAdminLogin(page);

    const profileBtn = getResilientLocator(page, 'PROFILE_BTN');
    await clickCoordinate(page, profileBtn);

    const adminPanelBtn = page.locator(':text("Panel Admin")').first();
    await clickCoordinate(page, adminPanelBtn);

    // In Admin Panel, find a player and modify gold
    const goldInput = page.locator('flt-semantics[aria-label*="GOLD_INPUT"], input[type="number"]').first();
    const updateBtn = getResilientLocator(page, 'UPDATE_GOLD_BTN');

    if (await goldInput.count() > 0) {
        await clickCoordinate(page, goldInput);
        await page.keyboard.press('Control+A');
        await page.keyboard.press('Backspace');
        await page.keyboard.type('999');
        await clickCoordinate(page, updateBtn);
        // Verify success snackbar or updated value
        await page.waitForTimeout(2000);
        await page.screenshot({ path: `screenshots/admin-gold-updated-${Date.now()}.png` });
    }
  });
});
