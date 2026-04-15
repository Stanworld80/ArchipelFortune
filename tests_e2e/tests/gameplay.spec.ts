import { test, expect } from '@playwright/test';

test.describe('Archipel Fortune Gameplay Loop', () => {
  test.setTimeout(240000); // Gameplay takes time

  const testEmail = `player_${Math.floor(Math.random() * 10000)}@test.com`;
  const testPassword = 'Password123!';

  test.beforeEach(async ({ page }) => {
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flutter-view', { timeout: 30000 });

    await page.evaluate(() => {
      const activate = () => {
        const btn = document.querySelector('flt-semantics-placeholder, [aria-label="Enable accessibility"]');
        if (btn instanceof HTMLElement) btn.click();
      };
      activate();
      window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
      setTimeout(activate, 1000);
      setTimeout(activate, 3000);
    });

    await page.waitForTimeout(5000);
  });

  test('Full Journey: Register -> Prepare -> Navigate', async ({ page }) => {
    // 1. Ensure we are in registration mode
    const toggleBtn = page.locator('[aria-label="AUTH_TOGGLE_BTN"]').first();
    await expect(toggleBtn).toBeVisible({ timeout: 45000 });
    const toggleText = await toggleBtn.innerText();
    
    // We want registration mode.
    // If the button says "DÉJÀ MEMBRE ? SE CONNECTER", we are already in registration mode.
    // If it says "NOUVELLE RECRUE ? CRÉER UN PROFIL", we are in login mode, so click to switch.
    if (toggleText.includes('CRÉER UN PROFIL')) {
      await toggleBtn.click();
      await page.waitForTimeout(1000);
    }

    await page.locator('input[aria-label*="Email"], [aria-label="AUTH_EMAIL_FIELD"]').first().fill(testEmail);
    await page.locator('input[aria-label*="Passe"], [aria-label="AUTH_PASSWORD_FIELD"]').first().fill(testPassword);
    await page.locator('[aria-label="AUTH_SUBMIT_BTN"]').first().click();

    // 2. Wait for login to complete
    try {
      await page.locator('[aria-label="PROFILE_BTN"]').first().waitFor({ state: 'visible', timeout: 60000 });
    } catch (e) {
      const errorVisible = await page.locator('.SnackBar, :text("Erreur"), [aria-label*="Error"]').first().isVisible();
      if (errorVisible) {
        const errorText = await page.locator('.SnackBar, :text("Erreur"), [aria-label*="Error"]').first().innerText().catch(() => 'Unknown error');
        throw new Error(`Registration/Login failed for ${testEmail}: ${errorText}`);
      }
      await page.screenshot({ path: `gameplay-auth-timeout-${Date.now()}.png`, fullPage: true });
      throw new Error(`Timed out waiting for login to complete for ${testEmail}`);
    }

    // 3. HomeView check
    const exploreBtn = page.locator('[aria-label="EXPLORE_MAIN_BTN"]').first();
    await expect(exploreBtn).toBeVisible({ timeout: 45000 });
    await exploreBtn.click({ force: true });

    // 4. Preparation Dialog
    const startExpBtn = page.locator('[aria-label="START_EXPEDITION_BTN"]').first();
    await expect(startExpBtn).toBeVisible({ timeout: 20000 });
    await startExpBtn.click();

    // 5. Session View (Map)
    // The position text is a great way to confirm we are in the session
    await expect(page.getByText(/POSITION: 18, 18/i)).toBeVisible({ timeout: 45000 });

    // 6. Movement
    const advanceBtn = page.locator('[aria-label="MOVE_UP_BTN"]').first();
    await expect(advanceBtn).toBeVisible({ timeout: 10000 });
    await advanceBtn.click();

    // Position update verification
    await expect(page.getByText(/POSITION: 18, 17/i)).toBeVisible({ timeout: 15000 });
  });
});
