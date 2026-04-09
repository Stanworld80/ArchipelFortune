import { test, expect } from '@playwright/test';

test.describe('Archipel Fortune Admin Panel', () => {
  test.setTimeout(120000);

  const SUPER_ADMIN_EMAIL = 'stanworld@gmail.com';
  const TEST_PASSWORD = 'Password123!';

  test.beforeEach(async ({ page }) => {
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flutter-view', { timeout: 30000 });

    // Enable accessibility
    await page.evaluate(() => {
      const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
      const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility');
      if (accessBtn instanceof HTMLElement) accessBtn.click();
    });

    await page.waitForTimeout(5000);
  });

  test('Access Admin Panel as Superadmin', async ({ page }) => {
    // 1. Ensure we are on the Login screen (not Sign-up)
    const isSignup = await page.getByText(/Inscription/i).isVisible();
    if (isSignup) {
      await page.getByText(/Se connecter/i).click();
      await expect(page.getByText(/Connexion/i, { exact: true })).toBeVisible();
    }

    // 2. Connection as Superadmin
    await page.getByLabel('Email').fill(SUPER_ADMIN_EMAIL);
    await page.getByLabel('Mot de passe').fill(TEST_PASSWORD);
    await page.getByRole('button', { name: /Se connecter/i }).click();

    // Wait for Login to complete
    await expect(page.getByText(/Bienvenue/i)).toBeVisible({ timeout: 30000 });

    // 2. Open User Menu
    const profileBtn = page.getByLabel('PROFILE_BTN');
    await expect(profileBtn).toBeVisible({ timeout: 20000 });
    await profileBtn.click();

    // 3. Click Panel Admin
    const adminLink = page.getByText(/Panel Admin/i);
    await expect(adminLink).toBeVisible({ timeout: 20000 });
    await adminLink.click();

    // 4. Verify Admin Panel Content
    await expect(page.getByText(/Pannel d'Administration/i)).toBeVisible();
    await expect(page.locator('[aria-label*="player_item"]')).toBeVisible();
  });

  test('Modify Player Gold', async ({ page }) => {
    // 1. Ensure we are on the Login screen (not Sign-up)
    const isSignup = await page.getByText(/Inscription/i).isVisible();
    if (isSignup) {
      await page.getByText(/Se connecter/i).click();
      await expect(page.getByText(/Connexion/i, { exact: true })).toBeVisible();
    }

    // 2. Connection and navigation
    await page.getByLabel('Email').fill(SUPER_ADMIN_EMAIL);
    await page.getByLabel('Mot de passe').fill(TEST_PASSWORD);
    await page.getByRole('button', { name: /Se connecter/i }).click();

    // Wait for Login to complete
    await expect(page.getByText(/Bienvenue/i)).toBeVisible({ timeout: 30000 });
    
    // Open Admin Panel
    const profileBtn = page.getByLabel('PROFILE_BTN');
    await expect(profileBtn).toBeVisible({ timeout: 20000 });
    await profileBtn.click();
    await page.getByText(/Panel Admin/i).click();

    // 1. Click on first player
    const playerItem = page.locator('[aria-label*="player_item"]').first();
    await playerItem.click();

    // 2. Modify gold
    const goldInput = page.getByLabel(/Pièces d'Or/i);
    await goldInput.fill('999');
    
    // 3. Save
    await page.locator('button', { hasText: /Sauvegarder/i }).click();

    // 4. Verify update
    await expect(page.getByText('999 🪙')).toBeVisible({ timeout: 10000 });
  });
});
