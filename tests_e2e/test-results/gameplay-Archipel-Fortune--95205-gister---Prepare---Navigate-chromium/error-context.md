# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: gameplay.spec.ts >> Archipel Fortune Gameplay Loop >> Full Journey: Register -> Prepare -> Navigate
- Location: tests\gameplay.spec.ts:35:7

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
            - img [ref=e5]
            - group:
              - heading "L'Archipel de la Fortune L'Archipel de la Fortune" [level=2] [ref=e6]
              - generic [ref=e7]:
                - generic: QUÊTE DE GLOIRE ET DE TRÉSORS
              - generic [ref=e8]:
                - generic: REJOINDRE L'ÉQUIPAGE
              - generic [ref=e9]:
                - textbox "AUTH_EMAIL_FIELD" [ref=e10]: capitaine.1776089440323@fortune.com
                - textbox "Email de l'Explorateur" [ref=e12]
              - generic [ref=e13]:
                - textbox "AUTH_PASSWORD_FIELD" [ref=e14]: Password123!
                - textbox "Mot de Passe Secret" [ref=e16]
              - button "AUTH_SUBMIT_BTN" [ref=e17]:
                - button "SIGNER LE CONTRAT" [active] [ref=e18]
              - button "AUTH_TOGGLE_BTN" [ref=e19]:
                - button "DÉJÀ MEMBRE ? SE CONNECTER" [ref=e20]
              - generic [ref=e21]:
                - generic: OU
              - button "CONTINUER AVEC GOOGLE" [ref=e22]
            - generic [ref=e23]:
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
  30 |     await expect(page.getByLabel('Enable accessibility')).not.toBeVisible({ timeout: 10000 });
  31 |     const canvas = page.locator('flutter-view');
  32 |     await expect(canvas).toBeVisible({ timeout: 10000 });
  33 |   });
  34 | 
  35 |   test('Full Journey: Register -> Prepare -> Navigate', async ({ page }) => {
  36 |     // 1. Inscription
  37 |     const toggleBtn = page.getByLabel('AUTH_TOGGLE_BTN');
  38 |     await expect(toggleBtn).toBeVisible({ timeout: 45000 });
  39 |     const toggleText = await toggleBtn.innerText();
  40 |     
  41 |     // Si on n'est pas déjà en mode inscription (bouton propose "SE CONNECTER" quand on est en inscription)
  42 |     if (!toggleText.includes('SE CONNECTER')) {
  43 |       await toggleBtn.click();
  44 |     }
  45 | 
  46 |     const emailField = page.getByLabel('AUTH_EMAIL_FIELD');
  47 |     await expect(emailField).toBeVisible({ timeout: 20000 });
  48 |     // Flutter Web sometimes reports the field as disabled immediately after accessibility activation
  49 |     // We'll use force click to focus it regardless
  50 |     await emailField.click({ force: true });
  51 |     await emailField.fill(testEmail);
  52 |     
  53 |     await page.getByLabel('AUTH_PASSWORD_FIELD').fill(testPassword);
  54 |     
  55 |     const signupBtn = page.getByLabel('AUTH_SUBMIT_BTN');
  56 |     await signupBtn.click();
  57 | 
  58 |     // 2. Vérification HomeView
  59 |     // On cherche le bouton EXPLORER
  60 |     const exploreBtn = page.getByLabel('EXPLORE_MAIN_BTN', { exact: true });
> 61 |     await expect(exploreBtn).toBeVisible({ timeout: 60000 });
     |                              ^ Error: expect(locator).toBeVisible() failed
  62 |     
  63 |     // Vérifier l'or initial (50 gold)
  64 |     await expect(page.getByText(/50 Pièces d'Or/i)).toBeVisible();
  65 | 
  66 |     // 3. Préparation du Navire
  67 |     await exploreBtn.click();
  68 |     await page.waitForTimeout(2000); // Animation du dialogue
  69 |     
  70 |     const embarkBtn = page.getByRole('button', { name: /Prendre la Mer/i });
  71 |     await expect(embarkBtn).toBeVisible({ timeout: 10000 });
  72 |     await embarkBtn.click();
  73 | 
  74 |     // 4. Navigation (Sea Map)
  75 |     await expect(page.getByText(/Navigation en Mer/i)).toBeVisible({ timeout: 45000 });
  76 |     
  77 |     // Vérifier la position initiale
  78 |     await expect(page.getByText(/POSITION: 18, 18/i)).toBeVisible();
  79 | 
  80 |     // 5. Mouvement
  81 |     const advanceBtn = page.getByLabel('MOVE_UP_BTN');
  82 |     await expect(advanceBtn).toBeVisible({ timeout: 10000 });
  83 |     await advanceBtn.click();
  84 | 
  85 |     // Attendre la mise à jour
  86 |     await expect(page.getByText(/POSITION: 18, 17/i)).toBeVisible({ timeout: 10000 });
  87 |     await expect(page.getByText(/19 🍎/i)).toBeVisible();
  88 |   });
  89 | });
  90 | 
```