# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: smoke.spec.ts >> Archipel Fortune Smoke Tests >> Landing Page Content
- Location: tests\smoke.spec.ts:45:7

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: locator('[aria-label*="Archipel"]').first()
Expected: visible
Timeout: 60000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" with timeout 60000ms
  - waiting for locator('[aria-label*="Archipel"]').first()

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
              - heading "L'Archipel de la Fortune L'Archipel de la Fortune" [level=2] [ref=e6]
              - generic [ref=e7]:
                - generic: QUÊTE DE GLOIRE ET DE TRÉSORS
              - generic [ref=e8]:
                - generic: AUTHENTIFICATION
              - generic [ref=e9]:
                - textbox "AUTH_EMAIL_FIELD" [ref=e10]
                - textbox "Email de l'Explorateur" [ref=e12]
              - generic [ref=e13]:
                - textbox "AUTH_PASSWORD_FIELD" [ref=e14]
                - textbox "Mot de Passe Secret" [ref=e16]
              - button "AUTH_SUBMIT_BTN" [ref=e17]:
                - button "LANCER L'AVENTURE" [ref=e18]
              - button "AUTH_TOGGLE_BTN" [ref=e19]:
                - button "NOUVELLE RECRUE ? CRÉER UN PROFIL" [ref=e20]
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
  3  | test.describe('Archipel Fortune Smoke Tests', () => {
  4  |   test.setTimeout(90000);
  5  | 
  6  |   test.beforeEach(async ({ page }) => {
  7  |     await page.goto('/', { waitUntil: 'load', timeout: 60000 });
  8  |     await page.waitForSelector('flutter-view', { timeout: 30000 });
  9  | 
  10 |     // Activation de l'accessibilité via plusieurs méthodes pour maximiser la réussite
  11 |     await page.evaluate(() => {
  12 |       const start = Date.now();
  13 |       const findAndClick = () => {
  14 |         // Flutter Web semantics tree activation
  15 |         const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
  16 |         const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility' || el.textContent?.includes('accessibility'));
  17 |         if (accessBtn instanceof HTMLElement) {
  18 |           accessBtn.click();
  19 |           return true;
  20 |         }
  21 |         return false;
  22 |       };
  23 |       
  24 |       if (!findAndClick()) {
  25 |         window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
  26 |         setTimeout(findAndClick, 500);
  27 |       }
  28 |     });
  29 | 
  30 |     // Attente explicite que le bouton disparaisse ou que le contenu sémantique apparaisse
  31 |     await page.waitForTimeout(5000);
  32 |     
  33 |     // On s'assure que le bouton d'accessibilité n'est plus là (indique que les sémantiques sont chargées)
  34 |     await expect(page.getByLabel('Enable accessibility')).not.toBeVisible({ timeout: 10000 });
  35 | 
  36 |     // Vérification de sécurité pour s'assurer qu'on n'est pas bloqué sur l'écran d'accueil Flutter sans sémantique
  37 |     const canvas = page.locator('flutter-view');
  38 |     await expect(canvas).toBeVisible({ timeout: 10000 });
  39 |   });
  40 | 
  41 |   test('Page Title Verification', async ({ page }) => {
  42 |     await expect(page).toHaveTitle(/Archipel de la Fortune/i);
  43 |   });
  44 | 
  45 |   test('Landing Page Content', async ({ page }) => {
  46 |     // Locator très robuste utilisant un match partiel sur l'un des aria-labels
  47 |     const branding = page.locator('[aria-label*="Archipel"]');
> 48 |     await expect(branding.first()).toBeVisible({ timeout: 60000 });
     |                                    ^ Error: expect(locator).toBeVisible() failed
  49 |   });
  50 | 
  51 |   test('Authentication UI Elements', async ({ page }) => {
  52 |     const submitBtn = page.getByLabel('AUTH_SUBMIT_BTN');
  53 |     await expect(submitBtn).toBeVisible({ timeout: 20000 });
  54 |   });
  55 | 
  56 |   test('Form Interaction', async ({ page }) => {
  57 |     const emailInput = page.getByLabel('AUTH_EMAIL_FIELD');
  58 |     await expect(emailInput).toBeVisible({ timeout: 20000 });
  59 |     // On tente un clic pour forcer le focus et l'activation sémantique si nécessaire
  60 |     await emailInput.click({ force: true });
  61 |     await emailInput.fill('test@example.com');
  62 |     await expect(emailInput).toHaveValue('test@example.com');
  63 |   });
  64 | });
  65 | 
```