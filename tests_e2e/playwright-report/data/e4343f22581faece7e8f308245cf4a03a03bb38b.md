# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: admin.spec.ts >> Archipel Fortune Admin Panel >> Access Admin Panel as Superadmin
- Location: tests\admin.spec.ts:23:7

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: getByText(/Bienvenue/i)
Expected: visible
Timeout: 30000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" with timeout 30000ms
  - waiting for getByText(/Bienvenue/i)

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
              - group "Connexion branding_title L'Archipel de la Fortune":
                - textbox "Email" [ref=e6]: stanworld@gmail.com
                - textbox "Mot de passe" [active] [ref=e8]: Password123!
                - button "Se connecter" [ref=e9]
                - button "Pas encore de compte ? S'inscrire" [ref=e10]
                - button "Continuer avec Google" [ref=e11]
```

# Test source

```ts
  1  | import { test, expect } from '@playwright/test';
  2  | 
  3  | test.describe('Archipel Fortune Admin Panel', () => {
  4  |   test.setTimeout(120000);
  5  | 
  6  |   const SUPER_ADMIN_EMAIL = 'stanworld@gmail.com';
  7  |   const TEST_PASSWORD = 'Password123!';
  8  | 
  9  |   test.beforeEach(async ({ page }) => {
  10 |     await page.goto('/', { waitUntil: 'load', timeout: 60000 });
  11 |     await page.waitForSelector('flutter-view', { timeout: 30000 });
  12 | 
  13 |     // Enable accessibility
  14 |     await page.evaluate(() => {
  15 |       const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
  16 |       const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility');
  17 |       if (accessBtn instanceof HTMLElement) accessBtn.click();
  18 |     });
  19 | 
  20 |     await page.waitForTimeout(5000);
  21 |   });
  22 | 
  23 |   test('Access Admin Panel as Superadmin', async ({ page }) => {
  24 |     // 1. Connection as Superadmin
  25 |     await page.getByLabel('Email').fill(SUPER_ADMIN_EMAIL);
  26 |     await page.getByLabel('Mot de passe').fill(TEST_PASSWORD);
  27 |     await page.getByRole('button', { name: /Se connecter/i }).click();
  28 | 
  29 |     // Wait for Login to complete
> 30 |     await expect(page.getByText(/Bienvenue/i)).toBeVisible({ timeout: 30000 });
     |                                                ^ Error: expect(locator).toBeVisible() failed
  31 | 
  32 |     // 2. Open User Menu
  33 |     const profileBtn = page.getByLabel('PROFILE_BTN');
  34 |     await expect(profileBtn).toBeVisible({ timeout: 20000 });
  35 |     await profileBtn.click();
  36 | 
  37 |     // 3. Click Panel Admin
  38 |     const adminLink = page.getByText(/Panel Admin/i);
  39 |     await expect(adminLink).toBeVisible({ timeout: 20000 });
  40 |     await adminLink.click();
  41 | 
  42 |     // 4. Verify Admin Panel Content
  43 |     await expect(page.getByText(/Pannel d'Administration/i)).toBeVisible();
  44 |     await expect(page.locator('[aria-label*="player_item"]')).toBeVisible();
  45 |   });
  46 | 
  47 |   test('Modify Player Gold', async ({ page }) => {
  48 |     // Connection and navigation
  49 |     await page.getByLabel('Email').fill(SUPER_ADMIN_EMAIL);
  50 |     await page.getByLabel('Mot de passe').fill(TEST_PASSWORD);
  51 |     await page.getByRole('button', { name: /Se connecter/i }).click();
  52 | 
  53 |     // Wait for Login to complete
  54 |     await expect(page.getByText(/Bienvenue/i)).toBeVisible({ timeout: 30000 });
  55 |     
  56 |     // Open Admin Panel
  57 |     const profileBtn = page.getByLabel('PROFILE_BTN');
  58 |     await expect(profileBtn).toBeVisible({ timeout: 20000 });
  59 |     await profileBtn.click();
  60 |     await page.getByText(/Panel Admin/i).click();
  61 | 
  62 |     // 1. Click on first player
  63 |     const playerItem = page.locator('[aria-label*="player_item"]').first();
  64 |     await playerItem.click();
  65 | 
  66 |     // 2. Modify gold
  67 |     const goldInput = page.getByLabel(/Pièces d'Or/i);
  68 |     await goldInput.fill('999');
  69 |     
  70 |     // 3. Save
  71 |     await page.locator('button', { hasText: /Sauvegarder/i }).click();
  72 | 
  73 |     // 4. Verify update
  74 |     await expect(page.getByText('999 🪙')).toBeVisible({ timeout: 10000 });
  75 |   });
  76 | });
  77 | 
```