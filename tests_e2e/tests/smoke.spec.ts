import { test, expect } from '@playwright/test';

test.describe('Archipel Fortune Smoke Tests', () => {
  test.setTimeout(90000);

  test.beforeEach(async ({ page }) => {
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flutter-view', { timeout: 30000 });

    // Activation de l'accessibilité via plusieurs méthodes pour maximiser la réussite
    await page.evaluate(() => {
      // 1. Recherche directe dans tout le document
      const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
      const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility' || el.textContent?.includes('accessibility'));
      if (accessBtn instanceof HTMLElement) {
        accessBtn.click();
      }
    });

    // 2. Si ça échoue, on tente le clic forcé via Playwright
    try {
      const pBtn = page.getByRole('button', { name: /Enable accessibility/i });
      if (await pBtn.isVisible({ timeout: 2000 })) {
        await pBtn.click({ force: true });
      }
    } catch (e) {
      // Ignore
    }

    // Attente de l'injection sémantique
    await page.waitForTimeout(10000);
  });

  test('Page Title Verification', async ({ page }) => {
    await expect(page).toHaveTitle(/Archipel de la Fortune/i);
  });

  test('Landing Page Content', async ({ page }) => {
    // Locator très robuste utilisant un match partiel sur l'un des aria-labels
    const branding = page.locator('[aria-label*="Archipel"]');
    await expect(branding.first()).toBeVisible({ timeout: 60000 });
  });

  test('Authentication UI Elements', async ({ page }) => {
    const signupBtn = page.getByText(/S'inscrire/i);
    await expect(signupBtn.first()).toBeVisible({ timeout: 20000 });
  });

  test('Form Interaction', async ({ page }) => {
    const emailInput = page.getByLabel('Email');
    await emailInput.fill('test@example.com');
    await expect(emailInput).toHaveValue('test@example.com');
  });
});
