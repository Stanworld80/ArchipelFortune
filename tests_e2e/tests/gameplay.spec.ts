import { test, expect } from '@playwright/test';

test.describe('Archipel Fortune Gameplay Loop', () => {
  const testEmail = `capitaine.${Date.now()}@fortune.com`;
  const testPassword = 'Password123!';

  test.beforeEach(async ({ page }) => {
    test.setTimeout(180000); 
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flutter-view', { timeout: 45000 });

    // Activation de l'accessibilité
    await page.evaluate(() => {
      const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
      const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility' || el.textContent?.includes('accessibility'));
      if (accessBtn instanceof HTMLElement) accessBtn.click();
    });

    await page.waitForTimeout(10000);
  });

  test('Full Journey: Register -> Prepare -> Navigate', async ({ page }) => {
    // 1. Inscription
    const signupToggle = page.getByText(/S'inscrire/i);
    await expect(signupToggle.first()).toBeVisible({ timeout: 45000 });
    await signupToggle.first().click();

    await page.getByLabel('Email').fill(testEmail);
    await page.getByLabel('Mot de passe').fill(testPassword);
    
    const signupBtn = page.getByRole('button', { name: /Créer un compte/i });
    await signupBtn.click();

    // 2. Vérification HomeView
    // On cherche le bouton EXPLORER
    const exploreBtn = page.getByLabel('EXPLORE_MAIN_BTN', { exact: true });
    await expect(exploreBtn).toBeVisible({ timeout: 60000 });
    
    // Vérifier l'or initial (50 gold)
    await expect(page.getByText(/50 Pièces d'Or/i)).toBeVisible();

    // 3. Préparation du Navire
    await exploreBtn.click();
    await page.waitForTimeout(2000); // Animation du dialogue
    
    const embarkBtn = page.getByRole('button', { name: /Prendre la Mer/i });
    await expect(embarkBtn).toBeVisible({ timeout: 10000 });
    await embarkBtn.click();

    // 4. Navigation (Sea Map)
    await expect(page.getByText(/Navigation en Mer/i)).toBeVisible({ timeout: 45000 });
    
    // Vérifier la position initiale
    await expect(page.getByText(/POSITION: 18, 18/i)).toBeVisible();

    // 5. Mouvement
    const advanceBtn = page.getByRole('button', { name: /AVANCER/i });
    await expect(advanceBtn).toBeVisible({ timeout: 10000 });
    await advanceBtn.click();

    // Attendre la mise à jour
    await expect(page.getByText(/POSITION: 18, 17/i)).toBeVisible({ timeout: 10000 });
    await expect(page.getByText(/19 🍎/i)).toBeVisible();
  });
});
