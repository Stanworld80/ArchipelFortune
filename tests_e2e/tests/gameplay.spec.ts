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
        setTimeout(findAndClick, 1000);
      }
    });

    await page.waitForTimeout(10000);
    
    // On s'assure que le bouton d'accessibilité n'est plus là
    const accessBtn = page.getByLabel('Enable accessibility');
    if (await accessBtn.isVisible()) {
      await accessBtn.click({ force: true }).catch(() => {});
    }
  });

  test('Full Journey: Register -> Prepare -> Navigate', async ({ page }) => {
    // 1. Inscription
    const toggleBtn = page.getByLabel('AUTH_TOGGLE_BTN');
    await expect(toggleBtn).toBeVisible({ timeout: 45000 });
    const toggleText = await toggleBtn.innerText();
    
    // Si on n'est pas déjà en mode inscription (bouton propose "SE CONNECTER" quand on est en inscription)
    if (!toggleText.includes('SE CONNECTER')) {
      await toggleBtn.click();
    }

    const emailField = page.getByLabel('AUTH_EMAIL_FIELD');
    await expect(emailField).toBeVisible({ timeout: 20000 });
    // Flutter Web sometimes reports the field as disabled immediately after accessibility activation
    // We'll use force click to focus it regardless
    await emailField.click({ force: true });
    await emailField.fill(testEmail);
    
    await page.getByLabel('AUTH_PASSWORD_FIELD').fill(testPassword);
    
    const signupBtn = page.getByLabel('AUTH_SUBMIT_BTN');
    await signupBtn.click();

    // 2. Vérification HomeView
    // On cherche le bouton EXPLORER, avec un check d'erreur si timeout
    const exploreBtn = page.getByLabel('EXPLORE_MAIN_BTN', { exact: true });
    try {
      await expect(exploreBtn).toBeVisible({ timeout: 60000 });
    } catch (e) {
      const errorText = page.locator('text=/Erreur|Error/i');
      if (await errorText.isVisible()) {
        throw new Error(`Signup failed with error: ${await errorText.innerText()}`);
      }
      throw e;
    }
    
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
    const advanceBtn = page.getByLabel('MOVE_UP_BTN');
    await expect(advanceBtn).toBeVisible({ timeout: 10000 });
    await advanceBtn.click();

    // Attendre la mise à jour
    await expect(page.getByText(/POSITION: 18, 17/i)).toBeVisible({ timeout: 10000 });
    await expect(page.getByText(/19 🍎/i)).toBeVisible();
  });
});
