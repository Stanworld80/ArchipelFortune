import { test, expect } from '@playwright/test';
import { waitForAppLoaded, getResilientLocator } from './test_utils';

test.describe('Archipel Fortune Visual & Button Tests', () => {
  test.setTimeout(90000);

  test.beforeEach(async ({ page }) => {
    // Naviguation vers la page et attente du chargement de Flutter
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await waitForAppLoaded(page);
  });

  test('Visual Regression - Landing Page', async ({ page }) => {
    // Note: This test is skipped in CI by playwright.config or env check if enabled
    test.skip(!!process.env.CI, 'Skip visual tests in CI until baselines are established');
    
    await expect(page).toHaveScreenshot('landing-page.png', {
      fullPage: true,
      maxDiffPixelRatio: 0.05,
      animations: 'disabled'
    });
  });

  test('Button Presence and States', async ({ page }) => {
    // Vérification du bouton principal de soumission
    const submitBtn = page.locator('[aria-label="AUTH_SUBMIT_BTN"]').first();
    await expect(submitBtn).toBeVisible({ timeout: 20000 });
    await expect(submitBtn).toBeEnabled();
    
    // Vérification du bouton de toggle
    const toggleBtn = page.locator('[aria-label="AUTH_TOGGLE_BTN"]').first();
    await expect(toggleBtn).toBeVisible();
    await expect(toggleBtn).toBeEnabled();

    // Vérification des champs de texte
    const emailField = page.locator('[aria-label*="AUTH_EMAIL_FIELD"], [aria-label*="Email"]').first();
    const passwordField = page.locator('[aria-label*="AUTH_PASSWORD_FIELD"], [aria-label*="Passe"]').first();
    await expect(emailField).toBeVisible();
    await expect(passwordField).toBeVisible();
  });

  test('Authentication Mode Toggle', async ({ page }) => {
    const toggleBtn = page.locator('[aria-label="AUTH_TOGGLE_BTN"]').first();
    const submitBtn = page.locator('[aria-label="AUTH_SUBMIT_BTN"]').first();

    await expect(toggleBtn).toBeVisible();
    
    // On clique sur le toggle pour passer en mode Inscription
    await toggleBtn.click();
    await page.waitForTimeout(1000);

    // On revient en mode Connexion
    await toggleBtn.click();
    await page.waitForTimeout(1000);
    await expect(submitBtn).toBeVisible();
  });

  test('Google Sign-In Button Presence', async ({ page }) => {
    // Le bouton Google a souvent le texte "CONTINUER AVEC GOOGLE"
    const googleBtn = page.getByText(/GOOGLE/i).first();
    await expect(googleBtn).toBeVisible({ timeout: 15000 });
  });
});
