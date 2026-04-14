import { test, expect } from '@playwright/test';

test.describe('Archipel Fortune Smoke Tests', () => {
  test.setTimeout(90000);

  test.beforeEach(async ({ page }) => {
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flutter-view', { timeout: 30000 });

    // Activation de l'accessibilité via plusieurs méthodes pour maximiser la réussite
    await page.evaluate(() => {
      const start = Date.now();
      const findAndClick = () => {
        // Flutter Web semantics tree activation
        const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
        const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility' || el.textContent?.includes('accessibility'));
        if (accessBtn instanceof HTMLElement) {
          accessBtn.click();
          console.log("Accessibility button found and clicked after " + (Date.now() - start) + "ms");
          return true;
        }
        return false;
      };
      
      if (!findAndClick()) {
        window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
        setTimeout(findAndClick, 1000);
      }
    });

    // Attente explicite que le contenu sémantique soit prêt
    await page.waitForTimeout(5000);
    
    // On vérifie s'il y a une erreur affichée (SnackBar)
    const errorText = page.locator('text=/Erreur|Error/i');
    if (await errorText.isVisible()) {
      console.error("Error detected on page load: " + await errorText.innerText());
    }

    // On s'assure que le bouton d'accessibilité n'est plus là (indique que les sémantiques sont chargées)
    const accessBtn = page.getByLabel('Enable accessibility');
    if (await accessBtn.isVisible()) {
      await accessBtn.click({ force: true }).catch(() => {});
    }
    // Vérification de sécurité pour s'assurer qu'on n'est pas bloqué sur l'écran d'accueil Flutter sans sémantique
    const canvas = page.locator('flutter-view');
    await expect(canvas).toBeVisible({ timeout: 10000 });
  });

  test('Page Title Verification', async ({ page }) => {
    await expect(page).toHaveTitle(/Archipel de la Fortune/i);
  });

  test('Landing Page Content', async ({ page }) => {
    // Locator robuste utilisant le label APP_TITLE ajouté dans HomeView
    const branding = page.getByLabel('APP_TITLE');
    await expect(branding.first()).toBeVisible({ timeout: 60000 });
  });

  test('Authentication UI Elements', async ({ page }) => {
    const submitBtn = page.getByLabel('AUTH_SUBMIT_BTN');
    await expect(submitBtn).toBeVisible({ timeout: 20000 });
  });

  test('Form Interaction', async ({ page }) => {
    const emailInput = page.getByLabel('AUTH_EMAIL_FIELD');
    await expect(emailInput).toBeVisible({ timeout: 20000 });
    // On tente un clic pour forcer le focus et l'activation sémantique si nécessaire
    await emailInput.click({ force: true });
    await emailInput.fill('test@example.com');
    await expect(emailInput).toHaveValue('test@example.com');
  });
});
