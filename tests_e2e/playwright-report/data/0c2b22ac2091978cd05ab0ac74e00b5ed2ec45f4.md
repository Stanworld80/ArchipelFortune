# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: smoke.spec.ts >> Archipel Fortune Smoke Tests >> Landing Page Content
- Location: tests\smoke.spec.ts:48:7

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
  3  | test.describe('Archipel Fortune Smoke Tests', () => {
  4  |   test.setTimeout(90000);
  5  | 
  6  |   test.beforeEach(async ({ page }) => {
  7  |     await page.goto('/', { waitUntil: 'load', timeout: 60000 });
  8  |     await page.waitForSelector('flutter-view', { timeout: 30000 });
  9  | 
  10 |     // Activation de l'accessibilité via plusieurs méthodes pour maximiser la réussite
  11 |     await page.evaluate(() => {
  12 |       // 1. Recherche directe dans tout le document
  13 |       const findAndClick = () => {
  14 |         const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
  15 |         const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility' || el.textContent?.includes('accessibility'));
  16 |         if (accessBtn instanceof HTMLElement) {
  17 |           accessBtn.click();
  18 |           return true;
  19 |         }
  20 |         return false;
  21 |       };
  22 |       
  23 |       if (!findAndClick()) {
  24 |         // Envoi d'un événement clavier Tab pour forcer l'apparition du bouton
  25 |         window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
  26 |         setTimeout(findAndClick, 500);
  27 |       }
  28 |     });
  29 | 
  30 |     // 2. Si ça échoue, on tente le clic forcé via Playwright
  31 |     try {
  32 |       const pBtn = page.getByRole('button', { name: /Enable accessibility/i });
  33 |       if (await pBtn.isVisible({ timeout: 5000 })) {
  34 |         await pBtn.click({ force: true });
  35 |       }
  36 |     } catch (e) {
  37 |       // Ignore
  38 |     }
  39 | 
  40 |     // Attente de l'injection sémantique (réduit à 5s car 10s c'est long)
  41 |     await page.waitForTimeout(5000);
  42 |   });
  43 | 
  44 |   test('Page Title Verification', async ({ page }) => {
  45 |     await expect(page).toHaveTitle(/Archipel de la Fortune/i);
  46 |   });
  47 | 
  48 |   test('Landing Page Content', async ({ page }) => {
  49 |     // Locator très robuste utilisant un match partiel sur l'un des aria-labels
  50 |     const branding = page.locator('[aria-label*="Archipel"]');
> 51 |     await expect(branding.first()).toBeVisible({ timeout: 60000 });
     |                                    ^ Error: expect(locator).toBeVisible() failed
  52 |   });
  53 | 
  54 |   test('Authentication UI Elements', async ({ page }) => {
  55 |     const submitBtn = page.getByLabel('AUTH_SUBMIT_BTN');
  56 |     await expect(submitBtn).toBeVisible({ timeout: 20000 });
  57 |   });
  58 | 
  59 |   test('Form Interaction', async ({ page }) => {
  60 |     const emailInput = page.getByLabel('AUTH_EMAIL_FIELD');
  61 |     await emailInput.fill('test@example.com');
  62 |     await expect(emailInput).toHaveValue('test@example.com');
  63 |   });
  64 | });
  65 | 
```