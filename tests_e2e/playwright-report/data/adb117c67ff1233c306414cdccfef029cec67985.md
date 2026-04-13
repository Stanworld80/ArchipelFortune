# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: gameplay.spec.ts >> Archipel Fortune Gameplay Loop >> Full Journey: Register -> Prepare -> Navigate
- Location: tests\gameplay.spec.ts:32:7

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: getByLabel('AUTH_TOGGLE_BTN')
Expected: visible
Timeout: 45000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" with timeout 45000ms
  - waiting for getByLabel('AUTH_TOGGLE_BTN')

```

# Page snapshot

```yaml
- generic [active] [ref=e4]:
  - generic:
    - generic:
      - generic:
        - generic:
          - generic:
            - img [ref=e5]
            - group:
              - generic:
                - generic: L'Archipel de la Fortune
              - generic:
                - generic: QUÊTE DE GLOIRE ET DE TRÉSORS
              - generic:
                - generic: AUTHENTIFICATION
              - textbox "Email de l'Explorateur" [ref=e7]
              - textbox "Mot de Passe Secret" [ref=e9]
              - button "LANCER L'AVENTURE" [ref=e10]
              - button "NOUVELLE RECRUE ? CRÉER UN PROFIL" [ref=e11]
              - generic:
                - generic: OU
              - button "CONTINUER AVEC GOOGLE" [ref=e12]
            - generic:
              - generic: "Version 0.1.3+11 • Mise à jour : 12/04/2026 16:56 • © 2026 Stanislas Selle Informatique"
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
  14 |       const findAndClick = () => {
  15 |         const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
  16 |         const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility' || el.textContent?.includes('accessibility'));
  17 |         if (accessBtn instanceof HTMLElement) {
  18 |           accessBtn.click();
  19 |           return true;
  20 |         }
  21 |         return false;
  22 |       };
  23 |       if (!findAndClick()) {
  24 |         window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
  25 |         setTimeout(findAndClick, 500);
  26 |       }
  27 |     });
  28 | 
  29 |     await page.waitForTimeout(5000);
  30 |   });
  31 | 
  32 |   test('Full Journey: Register -> Prepare -> Navigate', async ({ page }) => {
  33 |     // 1. Inscription
  34 |     const toggleBtn = page.getByLabel('AUTH_TOGGLE_BTN');
> 35 |     await expect(toggleBtn).toBeVisible({ timeout: 45000 });
     |                             ^ Error: expect(locator).toBeVisible() failed
  36 |     const toggleText = await toggleBtn.innerText();
  37 |     
  38 |     // Si on n'est pas déjà en mode inscription (bouton propose "SE CONNECTER" quand on est en inscription)
  39 |     if (!toggleText.includes('SE CONNECTER')) {
  40 |       await toggleBtn.click();
  41 |     }
  42 | 
  43 |     await page.getByLabel('AUTH_EMAIL_FIELD').fill(testEmail);
  44 |     await page.getByLabel('AUTH_PASSWORD_FIELD').fill(testPassword);
  45 |     
  46 |     const signupBtn = page.getByLabel('AUTH_SUBMIT_BTN');
  47 |     await signupBtn.click();
  48 | 
  49 |     // 2. Vérification HomeView
  50 |     // On cherche le bouton EXPLORER
  51 |     const exploreBtn = page.getByLabel('EXPLORE_MAIN_BTN', { exact: true });
  52 |     await expect(exploreBtn).toBeVisible({ timeout: 60000 });
  53 |     
  54 |     // Vérifier l'or initial (50 gold)
  55 |     await expect(page.getByText(/50 Pièces d'Or/i)).toBeVisible();
  56 | 
  57 |     // 3. Préparation du Navire
  58 |     await exploreBtn.click();
  59 |     await page.waitForTimeout(2000); // Animation du dialogue
  60 |     
  61 |     const embarkBtn = page.getByRole('button', { name: /Prendre la Mer/i });
  62 |     await expect(embarkBtn).toBeVisible({ timeout: 10000 });
  63 |     await embarkBtn.click();
  64 | 
  65 |     // 4. Navigation (Sea Map)
  66 |     await expect(page.getByText(/Navigation en Mer/i)).toBeVisible({ timeout: 45000 });
  67 |     
  68 |     // Vérifier la position initiale
  69 |     await expect(page.getByText(/POSITION: 18, 18/i)).toBeVisible();
  70 | 
  71 |     // 5. Mouvement
  72 |     const advanceBtn = page.getByLabel('MOVE_UP_BTN');
  73 |     await expect(advanceBtn).toBeVisible({ timeout: 10000 });
  74 |     await advanceBtn.click();
  75 | 
  76 |     // Attendre la mise à jour
  77 |     await expect(page.getByText(/POSITION: 18, 17/i)).toBeVisible({ timeout: 10000 });
  78 |     await expect(page.getByText(/19 🍎/i)).toBeVisible();
  79 |   });
  80 | });
  81 | 
```