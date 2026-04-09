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

Locator: getByRole('button', { name: /EXPLORER/i })
Expected: visible
Timeout: 60000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" with timeout 60000ms
  - waiting for getByRole('button', { name: /EXPLORER/i })

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
                - textbox "Email" [ref=e6]: capitaine.1775727480459@fortune.com
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
  35 |     const exploreBtn = page.getByRole('button', { name: /EXPLORER/i });
> 36 |     await expect(exploreBtn).toBeVisible({ timeout: 60000 });
     |                              ^ Error: expect(locator).toBeVisible() failed
  37 |     
  38 |     // Vérifier l'or initial (50 gold)
  39 |     await expect(page.getByText(/50 Pièces d'Or/i)).toBeVisible();
  40 | 
  41 |     // 3. Préparation du Navire
  42 |     await exploreBtn.click();
  43 |     await page.waitForTimeout(2000); // Animation du dialogue
  44 |     
  45 |     const embarkBtn = page.getByRole('button', { name: /Prendre la Mer/i });
  46 |     await expect(embarkBtn).toBeVisible({ timeout: 10000 });
  47 |     await embarkBtn.click();
  48 | 
  49 |     // 4. Navigation (Sea Map)
  50 |     await expect(page.getByText(/Navigation en Mer/i)).toBeVisible({ timeout: 45000 });
  51 |     
  52 |     // Vérifier la position initiale
  53 |     await expect(page.getByText(/POSITION: 18, 18/i)).toBeVisible();
  54 | 
  55 |     // 5. Mouvement
  56 |     const advanceBtn = page.getByRole('button', { name: /AVANCER/i });
  57 |     await expect(advanceBtn).toBeVisible({ timeout: 10000 });
  58 |     await advanceBtn.click();
  59 | 
  60 |     // Attendre la mise à jour
  61 |     await expect(page.getByText(/POSITION: 18, 17/i)).toBeVisible({ timeout: 10000 });
  62 |     await expect(page.getByText(/19 🍎/i)).toBeVisible();
  63 |   });
  64 | });
  65 | 
```