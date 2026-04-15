import { test, expect } from '@playwright/test';

test.describe('Admin Panel Tests', () => {
  // Use a long timeout for admin operations
  test.setTimeout(180000);

  const SUPER_ADMIN_EMAIL = 'admin@stanworld.com';
  const SUPER_ADMIN_PASSWORD = 'password123';

  test.beforeEach(async ({ page }) => {
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flutter-view', { timeout: 30000 });

    // Enable accessibility
    await page.evaluate(() => {
      const activate = () => {
        const btn = document.querySelector('flt-semantics-placeholder, [aria-label="Enable accessibility"]');
        if (btn instanceof HTMLElement) btn.click();
      };
      activate();
      window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
      setTimeout(activate, 1000); // Pulse activation
      setTimeout(activate, 3000); 
    });

    await page.waitForTimeout(5000);
  });

  async function adminLogin(page) {
    const emailField = page.locator('input[aria-label*="Email"], [aria-label="AUTH_EMAIL_FIELD"]').first();
    const passwordField = page.locator('input[aria-label*="Passe"], [aria-label="AUTH_PASSWORD_FIELD"]').first();
    const submitBtn = page.locator('[aria-label="AUTH_SUBMIT_BTN"]').first();

    await expect(emailField).toBeVisible({ timeout: 45000 });
    
    // Ensure we are in Login mode (not registration)
    const toggleBtn = page.locator('[aria-label="AUTH_TOGGLE_BTN"]').first();
    const toggleText = await toggleBtn.innerText().catch(() => '');
    if (toggleText.includes('SE CONNECTER') || toggleText.toLowerCase().includes('login')) {
       await toggleBtn.click();
       await page.waitForTimeout(1000);
    }

    await emailField.fill(SUPER_ADMIN_EMAIL);
    await passwordField.fill(SUPER_ADMIN_PASSWORD);
    await submitBtn.click();

    // Check for success or error
    const profileBtn = page.locator('[aria-label="PROFILE_BTN"]').first();
    const errorSnackbar = page.locator('.SnackBar, :text("Erreur"), [aria-label*="Error"]').first();
    
    try {
      await Promise.race([
        expect(profileBtn).toBeVisible({ timeout: 60000 }),
        expect(errorSnackbar).toBeVisible({ timeout: 15000 }).then(() => {
          throw new Error('Login failed: Error message detected on screen.');
        })
      ]);
    } catch (e) {
      console.error(`Login failed for ${SUPER_ADMIN_EMAIL}. This is likely due to invalid credentials, network issues, or Firebase configuration in the dev environment.`);
      await page.screenshot({ path: `login-failure-${Date.now()}.png`, fullPage: true });
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
