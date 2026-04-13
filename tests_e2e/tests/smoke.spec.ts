import { test, expect } from '@playwright/test';

test.describe('Archipel Fortune Smoke Tests', () => {
  test.setTimeout(90000);

  test.beforeEach(async ({ page }) => {
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flutter-view', { timeout: 30000 });

    // Activation de l'accessibilité via plusieurs méthodes pour maximiser la réussite
    await page.evaluate(() => {
      // 1. Recherche directe dans tout le document
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
        // Envoi d'un événement clavier Tab pour forcer l'apparition du bouton
        window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
        setTimeout(findAndClick, 500);
      }
    });

    // 2. Si ça échoue, on tente le clic forcé via Playwright
    try {
      const pBtn = page.getByRole('button', { name: /Enable accessibility/i });
      if (await pBtn.isVisible({ timeout: 5000 })) {
        await pBtn.click({ force: true });
      }
    } catch (e) {
      // Ignore
    }

    // Attente de l'injection sémantique (réduit à 5s car 10s c'est long)
    await page.waitForTimeout(5000);
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
    const submitBtn = page.getByLabel('AUTH_SUBMIT_BTN');
    await expect(submitBtn).toBeVisible({ timeout: 20000 });
  });

  test('Form Interaction', async ({ page }) => {
    const emailInput = page.getByLabel('AUTH_EMAIL_FIELD');
    await emailInput.fill('test@example.com');
    await expect(emailInput).toHaveValue('test@example.com');
  });
});
