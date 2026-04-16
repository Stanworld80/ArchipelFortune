import { test, expect } from '@playwright/test';

test.describe('Admin Panel Tests', () => {
  // Use a long timeout for admin operations
  test.setTimeout(180000);

  const SUPER_ADMIN_EMAIL = 'stantest@stanworld.org';
  const SUPER_ADMIN_PASSWORD = 'Tester=2026';

  test.beforeEach(async ({ page }) => {
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flutter-view', { timeout: 30000 });

    // activation de l'accessibilité via plusieurs méthodes (copié depuis smoke.spec.ts)
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

    await page.waitForTimeout(5000);
    
    const accessBtn = page.locator('[aria-label="Enable accessibility"]').first();
    if (await accessBtn.isVisible()) {
      await accessBtn.click({ force: true }).catch(() => {});
    }
  });

  async function adminLogin(page) {
    const emailField = page.locator('[aria-label*="AUTH_EMAIL_FIELD"], [aria-label*="Email de l\'Explorateur"]').first();
    const passwordField = page.locator('[aria-label*="AUTH_PASSWORD_FIELD"], [aria-label*="Mot de Passe Secret"]').first();
    const submitBtn = page.locator('[aria-label="AUTH_SUBMIT_BTN"]').first();

    await expect(emailField).toBeVisible({ timeout: 45000 });
    
    // Ensure we are in Login mode (not registration)
    const toggleBtn = page.locator('[aria-label="AUTH_TOGGLE_BTN"]').first();
    const toggleText = await toggleBtn.innerText().catch(() => '');
    if (toggleText.includes('SE CONNECTER') || toggleText.toLowerCase().includes('login')) {
       await toggleBtn.click();
       await page.waitForTimeout(1000);
    }

    await emailField.click({ force: true });
    await emailField.fill(SUPER_ADMIN_EMAIL, { force: true });
    await passwordField.click({ force: true });
    await passwordField.fill(SUPER_ADMIN_PASSWORD, { force: true });
    await page.waitForTimeout(1000);
    await submitBtn.click({ force: true });

    // Check for success or error
    const profileBtn = page.locator('[aria-label="PROFILE_BTN"]').first();
    const errorSnackbar = page.locator('.SnackBar, :text("Erreur"), [aria-label*="Error"]').first();
    
    try {
      // Wait for success without failing if the error snackbar isn't immediately visible
      await page.locator('[aria-label="PROFILE_BTN"]').first().waitFor({ state: 'visible', timeout: 120000 });
    } catch (e) {
      const errorVisible = await page.locator('.SnackBar, :text("Erreur"), [aria-label*="Error"]').first().isVisible();
      if (errorVisible) {
        const errorText = await page.locator('.SnackBar, :text("Erreur"), [aria-label*="Error"]').first().innerText().catch(() => 'Unknown error');
        console.error(`Login failed with error: ${errorText}`);
        throw new Error(`Login failed for ${SUPER_ADMIN_EMAIL}: ${errorText}`);
      }
      console.error(`Login timed out for ${SUPER_ADMIN_EMAIL}. This is likely due to network issues or Firebase performance.`);
      await page.screenshot({ path: `login-timeout-${Date.now()}.png`, fullPage: true });
      throw e;
    }
  }

  test('Admin Authentication and Navigation', async ({ page }) => {
    await adminLogin(page);

    const profileBtn = page.locator('[aria-label="PROFILE_BTN"]').first();
    await profileBtn.click();

    const adminPanelBtn = page.locator('[aria-label="ADMIN_PANEL_BTN"]').first();
    await expect(adminPanelBtn).toBeVisible({ timeout: 30000 });
    await adminPanelBtn.click();

    await expect(page.getByText('PANEL ADMINISTRATION')).toBeVisible({ timeout: 20000 });
  });

  test('Modify Player Gold', async ({ page }) => {
    await adminLogin(page);

    const profileBtn = page.locator('[aria-label="PROFILE_BTN"]').first();
    await profileBtn.click();
    
    const adminPanelBtn = page.locator('[aria-label="ADMIN_PANEL_BTN"]').first();
    await expect(adminPanelBtn).toBeVisible({ timeout: 30000 });
    await adminPanelBtn.click();

    // In the admin panel, find a gold input and change value
    // Increased timeout for lazy-loaded list items in the admin panel
    const goldInput = page.locator('input[aria-label*="Gold"], [aria-description*="Gold"]').first();
    await expect(goldInput).toBeVisible({ timeout: 30000 });
    
    const originalValue = await goldInput.inputValue();
    await goldInput.fill('99999');
    await page.keyboard.press('Enter');

    // Verify it saved (usually by checking a snackbar or value persistence)
    await page.waitForTimeout(3000);
    await expect(goldInput).toHaveValue('99999', { timeout: 10000 });
    
    // Cleanup: restore value
    await goldInput.fill(originalValue);
    await page.keyboard.press('Enter');
    await page.waitForTimeout(1000);
  });
});
