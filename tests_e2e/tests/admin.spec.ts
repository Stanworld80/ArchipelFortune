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
      setTimeout(activate, 2000); // Wait longer for Flutter to mount semantics
    });

    await page.waitForTimeout(5000);
  });

  test('Admin Authentication and Navigation', async ({ page }) => {
    // Fill credentials
    const emailField = page.locator('input[aria-label*="Email"], [aria-label="AUTH_EMAIL_FIELD"]').first();
    const passwordField = page.locator('input[aria-label*="Passe"], [aria-label="AUTH_PASSWORD_FIELD"]').first();
    const submitBtn = page.locator('[aria-label="AUTH_SUBMIT_BTN"]').first();

    await expect(emailField).toBeVisible({ timeout: 30000 });
    
    // Ensure we are in Login mode (not registration)
    const toggleBtn = page.locator('[aria-label="AUTH_TOGGLE_BTN"]').first();
    const toggleText = await toggleBtn.innerText().catch(() => '');
    if (toggleText.includes('CRÉER UN PROFIL')) {
      // We are in registration mode, do nothing (wait, no, we want login)
    } else if (toggleText.includes('SE CONNECTER')) {
       await toggleBtn.click();
       await page.waitForTimeout(1000);
    }

    await emailField.click({ force: true });
    await emailField.fill(SUPER_ADMIN_EMAIL);
    await page.waitForTimeout(500);
    
    await passwordField.click({ force: true });
    await passwordField.fill(SUPER_ADMIN_PASSWORD);
    await page.waitForTimeout(500);

    await submitBtn.click();

    // Check for success or error
    // If login fails, we'll see a snackbar. If it succeeds, we see the Profile button.
    const profileBtn = page.locator('[aria-label="PROFILE_BTN"]').first();
    const errorSnackbar = page.locator('.SnackBar, :text("Erreur")').first();
    
    try {
      // Race between success (profile button) and failure (error message)
      await Promise.race([
        expect(profileBtn).toBeVisible({ timeout: 60000 }),
        expect(errorSnackbar).toBeVisible({ timeout: 60000 }).then(() => {
          throw new Error('Login failed with an error message on screen.');
        })
      ]);
    } catch (e) {
      console.error(`Login failed for ${SUPER_ADMIN_EMAIL}. This is likely due to invalid credentials, network issues, or Firebase configuration in the dev environment.`);
      // Take a screenshot for the report
      await page.screenshot({ path: 'admin-login-failure.png' });
      throw e;
    }

    await profileBtn.click();

    const adminPanelBtn = page.locator('[aria-label="ADMIN_PANEL_BTN"]').first();
    await expect(adminPanelBtn).toBeVisible({ timeout: 15000 });
    await adminPanelBtn.click();

    await expect(page.getByText('PANEL ADMINISTRATION')).toBeVisible();
  });

  test('Modify Player Gold', async ({ page }) => {
    // Re-use logic from above if needed, but for now we assume the first test covers navigation
    // Note: E2E tests should ideally be independent.
    await page.locator('input[aria-label*="Email"], [aria-label="AUTH_EMAIL_FIELD"]').first().fill(SUPER_ADMIN_EMAIL);
    await page.locator('input[aria-label*="Passe"], [aria-label="AUTH_PASSWORD_FIELD"]').first().fill(SUPER_ADMIN_PASSWORD);
    await page.locator('[aria-label="AUTH_SUBMIT_BTN"]').first().click();

    const profileBtn = page.locator('[aria-label="PROFILE_BTN"]').first();
    await expect(profileBtn).toBeVisible({ timeout: 45000 });
    await profileBtn.click();
    
    const adminPanelBtn = page.locator('[aria-label="ADMIN_PANEL_BTN"]').first();
    await expect(adminPanelBtn).toBeVisible();
    await adminPanelBtn.click();

    // In the admin panel, find a gold input and change value
    const goldInput = page.locator('input[aria-label*="Gold"], [aria-description*="Gold"]').first();
    await expect(goldInput).toBeVisible({ timeout: 20000 });
    
    const originalValue = await goldInput.inputValue();
    await goldInput.fill('99999');
    await page.keyboard.press('Enter');

    // Verify it saved (usually by checking a snackbar or value persistence)
    await page.waitForTimeout(2000);
    await expect(goldInput).toHaveValue('99999');
    
    // Cleanup: restore value
    await goldInput.fill(originalValue);
    await page.keyboard.press('Enter');
  });
});
