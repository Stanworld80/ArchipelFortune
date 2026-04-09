# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: gameplay.spec.ts >> Archipel Fortune Gameplay Loop >> Full Journey: Register -> Prepare -> Navigate
- Location: tests\gameplay.spec.ts:22:7

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: getByLabel('EXPLORE_MAIN_BTN', { exact: true })
Expected: visible
Timeout: 60000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" with timeout 60000ms
  - waiting for getByLabel('EXPLORE_MAIN_BTN', { exact: true })

```

# Page snapshot

```yaml
- generic [ref=e4] [cursor=pointer]:
  - generic:
    - generic:
      - generic:
        - generic:
          - generic:
            - group:
              - group "Inscription branding_title L'Archipel de la Fortune":
                - textbox "Email" [ref=e6]: capitaine.1775729038349@fortune.com
                - textbox "Mot de passe" [ref=e8]
                - button "Créer un compte" [active] [ref=e9]
                - button "Déjà un compte ? Se connecter" [ref=e10]
                - button "Continuer avec Google" [ref=e11]
```

# Test source

```ts
  1  | import { test, expect } from '@playwright/test';
  2  | 
  3  | test.describe('Archipel Fortune Gameplay Loop', () => {
  4  |   const testEmail = `capitaine.${Date.now()}@fortune.com`;
  5  |   const testPassword = 'Password123!';
  6  | 
  7  |   test.beforeEach(async ({ page }) => {
  8  |     test.setTimeout(180000); 
  9  |     await page.goto('/', { waitUntil: 'load', timeout: 60000 });
  10 |     await page.waitForSelector('flutter-view', { timeout: 45000 });
  11 | 
  12 |     // Activation de l'accessibilité
  13 |     await page.evaluate(() => {
  14 |       const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
  15 |       const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility' || el.textContent?.includes('accessibility'));
  16 |       if (accessBtn instanceof HTMLElement) accessBtn.click();
  17 |     });
  18 | 
  19 |     await page.waitForTimeout(10000);
  20 |   });
  21 | 
  22 |   test('Full Journey: Register -> Prepare -> Navigate', async ({ page }) => {
  23 |     // 1. Inscription
  24 |     const signupToggle = page.getByText(/S'inscrire/i);
  25 |     await expect(signupToggle.first()).toBeVisible({ timeout: 45000 });
  26 |     await signupToggle.first().click();
  27 | 
  28 |     await page.getByLabel('Email').fill(testEmail);
  29 |     await page.getByLabel('Mot de passe').fill(testPassword);
  30 |     
  31 |     const signupBtn = page.getByRole('button', { name: /Créer un compte/i });
  32 |     await signupBtn.click();
  33 | 
  34 |     // 2. Vérification HomeView
  35 |     // On cherche le bouton EXPLORER
  36 |     const exploreBtn = page.getByLabel('EXPLORE_MAIN_BTN', { exact: true });
> 37 |     await expect(exploreBtn).toBeVisible({ timeout: 60000 });
     |                              ^ Error: expect(locator).toBeVisible() failed
  38 |     
  39 |     // Vérifier l'or initial (50 gold)
  40 |     await expect(page.getByText(/50 Pièces d'Or/i)).toBeVisible();
  41 | 
  42 |     // 3. Préparation du Navire
  43 |     await exploreBtn.click();
  44 |     await page.waitForTimeout(2000); // Animation du dialogue
  45 |     
  46 |     const embarkBtn = page.getByRole('button', { name: /Prendre la Mer/i });
  47 |     await expect(embarkBtn).toBeVisible({ timeout: 10000 });
  48 |     await embarkBtn.click();
  49 | 
  50 |     // 4. Navigation (Sea Map)
  51 |     await expect(page.getByText(/Navigation en Mer/i)).toBeVisible({ timeout: 45000 });
  52 |     
  53 |     // Vérifier la position initiale
  54 |     await expect(page.getByText(/POSITION: 18, 18/i)).toBeVisible();
  55 | 
  56 |     // 5. Mouvement
  57 |     const advanceBtn = page.getByRole('button', { name: /AVANCER/i });
  58 |     await expect(advanceBtn).toBeVisible({ timeout: 10000 });
  59 |     await advanceBtn.click();
  60 | 
  61 |     // Attendre la mise à jour
  62 |     await expect(page.getByText(/POSITION: 18, 17/i)).toBeVisible({ timeout: 10000 });
  63 |     await expect(page.getByText(/19 🍎/i)).toBeVisible();
  64 |   });
  65 | });
  66 | 
```