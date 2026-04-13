import { test, expect } from '@playwright/test';

test.describe('Archipel Fortune Visual & Button Tests', () => {
  test.setTimeout(90000);

  test.beforeEach(async ({ page }) => {
    // Naviguation vers la page et attente du chargement de Flutter
    await page.goto('/', { waitUntil: 'networkidle', timeout: 60000 });
    await page.waitForSelector('flutter-view', { timeout: 30000 });

    // Activation de l'accessibilité Flutter
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
        setTimeout(findAndClick, 500);
      }
    });

    // Attente du chargement des sémantiques
    await page.waitForTimeout(5000);
  });

  test('Visual Regression - Landing Page', async ({ page }) => {
    // Vérifie l'aspect visuel global de la page d'accueil
    // Note: La première exécution créera les snapshots de référence
    await expect(page).toHaveScreenshot('landing-page.png', {
      fullPage: true,
      maxDiffPixelRatio: 0.05,
      animations: 'disabled'
    });
  });

  test('Button Presence and States', async ({ page }) => {
    // Vérification du bouton principal de soumission
    const submitBtn = page.getByLabel('AUTH_SUBMIT_BTN');
    await expect(submitBtn).toBeVisible({ timeout: 20000 });
    await expect(submitBtn).toBeEnabled();
    
    // Vérification du bouton de toggle
    const toggleBtn = page.getByLabel('AUTH_TOGGLE_BTN');
    await expect(toggleBtn).toBeVisible();
    await expect(toggleBtn).toBeEnabled();

    // Vérification des champs de texte
    const emailField = page.getByLabel('AUTH_EMAIL_FIELD');
    const passwordField = page.getByLabel('AUTH_PASSWORD_FIELD');
    await expect(emailField).toBeVisible();
    await expect(passwordField).toBeVisible();
  });

  test('Authentication Mode Toggle', async ({ page }) => {
    const toggleBtn = page.getByLabel('AUTH_TOGGLE_BTN');
    const submitBtn = page.getByLabel('AUTH_SUBMIT_BTN');

    await expect(toggleBtn).toBeVisible();
    
    // On clique sur le toggle pour passer en mode Inscription
    await toggleBtn.click();
    await page.waitForTimeout(1000);

    // Vérification visuelle après toggle (changement de texte dans la carte)
    await expect(page).toHaveScreenshot('signup-mode.png', {
      maxDiffPixelRatio: 0.05,
      animations: 'disabled'
    });

    // On revient en mode Connexion
    await toggleBtn.click();
    await page.waitForTimeout(1000);
    await expect(submitBtn).toBeVisible();
  });

  test('Google Sign-In Button Presence', async ({ page }) => {
    // Le bouton Google n'a pas de label sémantique explicite dans le code Dart (juste du texte)
    // On le cherche par son texte ou par rôle si possible
    const googleBtn = page.getByRole('button', { name: /GOOGLE/i });
    await expect(googleBtn).toBeVisible({ timeout: 10000 });
  });
});
