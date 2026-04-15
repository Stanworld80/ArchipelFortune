# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: admin.spec.ts >> Admin Panel Tests >> Admin Authentication and Navigation
- Location: tests\admin.spec.ts:26:7

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: locator('[aria-label="PROFILE_BTN"]').first()
Expected: visible
Timeout: 60000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" with timeout 60000ms
  - waiting for locator('[aria-label="PROFILE_BTN"]').first()

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
              - heading "APP_TITLE L'Archipel de la Fortune" [level=2] [ref=e6]
              - generic [ref=e7]:
                - generic: QUÊTE DE GLOIRE ET DE TRÉSORS
              - generic [ref=e8]:
                - generic: AUTHENTIFICATION
              - generic [ref=e9]:
                - textbox "AUTH_EMAIL_FIELD" [ref=e10]: admin@stanworld.com
                - textbox "Email de l'Explorateur" [ref=e12]
              - generic [ref=e13]:
                - textbox "AUTH_PASSWORD_FIELD" [ref=e14]: password123
                - textbox "Mot de Passe Secret" [ref=e16]
              - button "AUTH_SUBMIT_BTN" [ref=e17]:
                - button "LANCER L'AVENTURE" [active] [ref=e18]
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
  3  | const SUPER_ADMIN_EMAIL = 'admin@stanworld.com';
  4  | const TEST_PASSWORD = 'password123';
  5  | 
  6  | test.describe('Admin Panel Tests', () => {
  7  |   test.setTimeout(180000);
  8  | 
  9  |   test.beforeEach(async ({ page }) => {
  10 |     await page.goto('/', { waitUntil: 'load', timeout: 60000 });
  11 |     await page.waitForSelector('flutter-view', { timeout: 30000 });
  12 | 
  13 |     await page.evaluate(() => {
  14 |       const activate = () => {
  15 |         const btn = document.querySelector('flt-semantics-placeholder, [aria-label="Enable accessibility"]');
  16 |         if (btn instanceof HTMLElement) btn.click();
  17 |       };
  18 |       activate();
  19 |       window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
  20 |       setTimeout(activate, 1000);
  21 |     });
  22 | 
  23 |     await page.waitForTimeout(5000);
  24 |   });
  25 | 
  26 |   test('Admin Authentication and Navigation', async ({ page }) => {
  27 |     // 1. Ensure we are in login mode
  28 |     const toggleBtn = page.locator('[aria-label="AUTH_TOGGLE_BTN"]').first();
  29 |     await expect(toggleBtn).toBeVisible({ timeout: 45000 });
  30 |     const toggleText = await toggleBtn.innerText();
  31 |     if (toggleText.includes('SE CONNECTER') || toggleText.includes('MEMBRE')) {
  32 |        // if we see "DÉJÀ MEMBRE ? SE CONNECTER", click it to switch to login mode
  33 |        if (toggleText.includes('DÉJÀ MEMBRE')) await toggleBtn.click();
  34 |     }
  35 | 
  36 |     // 2. Clear and fill login info
  37 |     const emailField = page.locator('input[aria-label*="Email"], [aria-label="AUTH_EMAIL_FIELD"]').first();
  38 |     const passField = page.locator('input[aria-label*="Passe"], [aria-label="AUTH_PASSWORD_FIELD"]').first();
  39 |     const submitBtn = page.locator('[aria-label="AUTH_SUBMIT_BTN"]').first();
  40 | 
  41 |     await emailField.click({ force: true });
  42 |     await emailField.fill(SUPER_ADMIN_EMAIL);
  43 |     await passField.fill(TEST_PASSWORD);
  44 |     await submitBtn.click();
  45 | 
  46 |     // 3. Wait for HomeView
  47 |     // We wait for the profile button which only appears when profile is loaded
  48 |     const profileBtn = page.locator('[aria-label="PROFILE_BTN"]').first();
  49 |     try {
> 50 |       await expect(profileBtn).toBeVisible({ timeout: 60000 });
     |                                ^ Error: expect(locator).toBeVisible() failed
  51 |     } catch (e) {
  52 |       // Check for error snackbar
  53 |       const errorMsg = page.locator('text=/Erreur|Error/i').first();
  54 |       if (await errorMsg.isVisible()) {
  55 |         throw new Error(`Login failed with UI error: ${await errorMsg.innerText()}`);
  56 |       }
  57 |       throw e;
  58 |     }
  59 |     
  60 |     await profileBtn.click({ force: true });
  61 | 
  62 |     // 4. Navigate to Admin Panel
  63 |     const adminLink = page.getByText(/Panel Admin/i).first();
  64 |     await expect(adminLink).toBeVisible({ timeout: 10000 });
  65 |     await adminLink.click();
  66 | 
  67 |     // 5. Check Admin Panel Title
  68 |     await expect(page.getByText(/Administration/i)).toBeVisible({ timeout: 20000 });
  69 |   });
  70 | 
  71 |   test('Modify Player Gold', async ({ page }) => {
  72 |     // Fast login
  73 |     await page.locator('input[aria-label*="Email"], [aria-label="AUTH_EMAIL_FIELD"]').first().fill(SUPER_ADMIN_EMAIL);
  74 |     await page.locator('input[aria-label*="Passe"], [aria-label="AUTH_PASSWORD_FIELD"]').first().fill(TEST_PASSWORD);
  75 |     await page.locator('[aria-label="AUTH_SUBMIT_BTN"]').first().click();
  76 | 
  77 |     const profileBtn = page.locator('[aria-label="PROFILE_BTN"]').first();
  78 |     await expect(profileBtn).toBeVisible({ timeout: 60000 });
  79 |     await profileBtn.click({ force: true });
  80 |     
  81 |     await page.getByText(/Panel Admin/i).first().click();
  82 | 
  83 |     // Verify we are in admin view
  84 |     await expect(page.getByText(/Administration/i)).toBeVisible();
  85 |     
  86 |     // The gold input might be in a list
  87 |     const goldInput = page.locator('input').first(); // Simplistic, but let's see if it finds at least one input in admin view
  88 |     if (await goldInput.isVisible()) {
  89 |       await goldInput.fill('888');
  90 |       await expect(goldInput).toHaveValue('888');
  91 |     }
  92 |   });
  93 | });
  94 | 
```