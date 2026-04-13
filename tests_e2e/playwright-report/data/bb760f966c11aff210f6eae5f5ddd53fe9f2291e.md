# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: admin.spec.ts >> Archipel Fortune Admin Panel >> Modify Player Gold
- Location: tests\admin.spec.ts:75:7

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
            - img [ref=e5]
            - group:
              - heading "L'Archipel de la Fortune L'Archipel de la Fortune" [level=2] [ref=e6]
              - generic [ref=e7]:
                - generic: QUÊTE DE GLOIRE ET DE TRÉSORS
              - generic [ref=e8]:
                - generic: AUTHENTIFICATION
              - generic [ref=e9]:
                - textbox "AUTH_EMAIL_FIELD" [ref=e10]: stanworld@gmail.com
                - textbox "Email de l'Explorateur" [ref=e12]
              - generic [ref=e13]:
                - textbox "AUTH_PASSWORD_FIELD" [ref=e14]: Password123!
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
  1   | import { test, expect } from '@playwright/test';
  2   | 
  3   | test.describe('Archipel Fortune Admin Panel', () => {
  4   |   test.setTimeout(120000);
  5   | 
  6   |   const SUPER_ADMIN_EMAIL = 'stanworld@gmail.com';
  7   |   const TEST_PASSWORD = 'Password123!';
  8   | 
  9   |   test.beforeEach(async ({ page }) => {
  10  |     await page.goto('/', { waitUntil: 'load', timeout: 60000 });
  11  |     await page.waitForSelector('flutter-view', { timeout: 30000 });
  12  | 
  13  |     // Activation de l'accessibilité
  14  |     await page.evaluate(() => {
  15  |       const findAndClick = () => {
  16  |         const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
  17  |         const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility' || el.textContent?.includes('accessibility'));
  18  |         if (accessBtn instanceof HTMLElement) {
  19  |           accessBtn.click();
  20  |           return true;
  21  |         }
  22  |         return false;
  23  |       };
  24  |       if (!findAndClick()) {
  25  |         window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
  26  |         setTimeout(findAndClick, 500);
  27  |       }
  28  |     });
  29  | 
  30  |     await page.waitForTimeout(5000);
  31  |     await expect(page.getByLabel('Enable accessibility')).not.toBeVisible({ timeout: 10000 });
  32  |     const canvas = page.locator('flutter-view');
  33  |     await expect(canvas).toBeVisible({ timeout: 10000 });
  34  |   });
  35  | 
  36  |   test('Access Admin Panel as Superadmin', async ({ page }) => {
  37  |     // 1. Ensure we are on the Login screen (not Sign-up)
  38  |     // Check if toggle says "SE CONNECTER" (means we are on signup page)
  39  |     const toggleBtn = page.getByLabel('AUTH_TOGGLE_BTN');
  40  |     const toggleText = await toggleBtn.innerText();
  41  |     if (toggleText.includes('SE CONNECTER')) {
  42  |       await toggleBtn.click();
  43  |     }
  44  | 
  45  |     // 2. Connection as Superadmin
  46  |     const emailInput = page.getByLabel('AUTH_EMAIL_FIELD');
  47  |     await expect(emailInput).toBeVisible({ timeout: 20000 });
  48  |     // On tente un clic pour forcer le focus et l'activation sémantique si nécessaire
  49  |     await emailInput.click({ force: true });
  50  |     await emailInput.fill(SUPER_ADMIN_EMAIL);
  51  |     
  52  |     await page.getByLabel('AUTH_PASSWORD_FIELD').fill(TEST_PASSWORD);
  53  |     const submitBtn = page.getByLabel('AUTH_SUBMIT_BTN');
  54  |     await expect(submitBtn).toBeVisible({ timeout: 20000 });
  55  |     await submitBtn.click({ force: true });
  56  | 
  57  |     // Wait for Login to complete
  58  |     await expect(page.getByText(/Bienvenue/i)).toBeVisible({ timeout: 30000 });
  59  | 
  60  |     // 2. Open User Menu
  61  |     const profileBtn = page.getByLabel('PROFILE_BTN');
  62  |     await expect(profileBtn).toBeVisible({ timeout: 20000 });
  63  |     await profileBtn.click({ force: true });
  64  | 
  65  |     // 3. Click Panel Admin
  66  |     const adminLink = page.getByText(/Panel Admin/i);
  67  |     await expect(adminLink).toBeVisible({ timeout: 20000 });
  68  |     await adminLink.click({ force: true });
  69  | 
  70  |     // 4. Verify Admin Panel Content
  71  |     await expect(page.getByText(/Pannel d'Administration/i)).toBeVisible();
  72  |     await expect(page.locator('[aria-label*="player_item"]')).toBeVisible();
  73  |   });
  74  | 
  75  |   test('Modify Player Gold', async ({ page }) => {
  76  |     // 1. Ensure we are on the Login screen (not Sign-up)
  77  |     const toggleBtn = page.getByLabel('AUTH_TOGGLE_BTN');
  78  |     const toggleText = await toggleBtn.innerText();
  79  |     if (toggleText.includes('SE CONNECTER')) {
  80  |       await toggleBtn.click();
  81  |     }
  82  | 
  83  |     // 2. Connection and navigation
  84  |     await page.getByLabel('AUTH_EMAIL_FIELD').fill(SUPER_ADMIN_EMAIL);
  85  |     await page.getByLabel('AUTH_PASSWORD_FIELD').fill(TEST_PASSWORD);
  86  |     await page.getByLabel('AUTH_SUBMIT_BTN').click();
  87  | 
  88  |     // Wait for Login to complete
> 89  |     await expect(page.getByText(/Bienvenue/i)).toBeVisible({ timeout: 30000 });
      |                                                ^ Error: expect(locator).toBeVisible() failed
  90  |     
  91  |     // Open Admin Panel
  92  |     const profileBtn = page.getByLabel('PROFILE_BTN');
  93  |     await expect(profileBtn).toBeVisible({ timeout: 20000 });
  94  |     await profileBtn.click();
  95  |     await page.getByText(/Panel Admin/i).click();
  96  | 
  97  |     // 1. Click on first player
  98  |     const playerItem = page.locator('[aria-label*="player_item"]').first();
  99  |     await playerItem.click();
  100 | 
  101 |     // 2. Modify gold
  102 |     const goldInput = page.getByLabel(/Pièces d'Or/i);
  103 |     await goldInput.fill('999');
  104 |     
  105 |     // 3. Save
  106 |     await page.locator('button', { hasText: /Sauvegarder/i }).click();
  107 | 
  108 |     // 4. Verify update
  109 |     await expect(page.getByText('999 🪙')).toBeVisible({ timeout: 10000 });
  110 |   });
  111 | });
  112 | 
```