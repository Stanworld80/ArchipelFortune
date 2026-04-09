# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: smoke.spec.ts >> Archipel Fortune Smoke Tests >> Landing Page Content
- Location: tests\smoke.spec.ts:38:7

# Error details

```
TimeoutError: locator.waitFor: Timeout 30000ms exceeded.
Call log:
  - waiting for locator('text=Archipel de la Fortune').first()

```

# Page snapshot

```yaml
- generic [active] [ref=e4]:
  - generic:
    - generic:
      - generic:
        - generic:
          - generic:
            - group:
              - group "Connexion branding_title L'Archipel de la Fortune":
                - textbox "Email" [ref=e6]
                - textbox "Mot de passe" [ref=e8]
                - button "Se connecter" [ref=e9]
                - button "Pas encore de compte ? S'inscrire" [ref=e10]
                - button "Continuer avec Google" [ref=e11]
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
  13 |       const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
  14 |       const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility' || el.textContent?.includes('accessibility'));
  15 |       if (accessBtn instanceof HTMLElement) {
  16 |         accessBtn.click();
  17 |       }
  18 |     });
  19 | 
  20 |     // 2. Si ça échoue, on tente le clic forcé via Playwright
  21 |     try {
  22 |       const pBtn = page.getByRole('button', { name: /Enable accessibility/i });
  23 |       if (await pBtn.isVisible({ timeout: 2000 })) {
  24 |         await pBtn.click({ force: true });
  25 |       }
  26 |     } catch (e) {
  27 |       // Ignore
  28 |     }
  29 | 
  30 |     // Attente de l'injection sémantique
  31 |     await page.waitForTimeout(10000);
  32 |   });
  33 | 
  34 |   test('Page Title Verification', async ({ page }) => {
  35 |     await expect(page).toHaveTitle(/Archipel de la Fortune/i);
  36 |   });
  37 | 
  38 |   test('Landing Page Content', async ({ page }) => {
  39 |     // Attendre que l'élément soit présent dans le DOM (même s'il n'est pas encore visible)
  40 |     const branding = page.locator('text=Archipel de la Fortune');
> 41 |     await branding.first().waitFor({ state: 'attached', timeout: 30000 });
     |                            ^ TimeoutError: locator.waitFor: Timeout 30000ms exceeded.
  42 |     await expect(branding.first()).toBeVisible({ timeout: 30000 });
  43 |   });
  44 | 
  45 |   test('Authentication UI Elements', async ({ page }) => {
  46 |     const signupBtn = page.getByText(/S'inscrire/i);
  47 |     await expect(signupBtn.first()).toBeVisible({ timeout: 20000 });
  48 |   });
  49 | 
  50 |   test('Form Interaction', async ({ page }) => {
  51 |     const emailInput = page.getByLabel('Email');
  52 |     await emailInput.fill('test@example.com');
  53 |     await expect(emailInput).toHaveValue('test@example.com');
  54 |   });
  55 | });
  56 | 
```