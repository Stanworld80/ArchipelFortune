# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: admin.spec.ts >> Admin Panel Tests >> Admin Authentication and Navigation
- Location: tests\admin.spec.ts:102:7

# Error details

```
TimeoutError: locator.waitFor: Timeout 120000ms exceeded.
Call log:
  - waiting for locator('[aria-label="PROFILE_BTN"]').first()

```

# Page snapshot

```yaml
- generic [active] [ref=e4]:
  - generic:
    - generic:
      - generic:
        - generic:
          - generic:
            - button "Show menu PROFILE_BTN" [ref=e5]
            - img [ref=e6]
            - group:
              - generic [ref=e7]:
                - generic: APP_TITLE L'Archipel de la Fortune
              - generic [ref=e8]:
                - generic: Capitaine
              - generic [ref=e9]:
                - generic: 🪙
              - generic [ref=e10]:
                - generic: 50 Pièces d'Or
              - generic [ref=e11]:
                - generic: SUPERADMIN
              - button "EXPLORE_MAIN_BTN" [ref=e12]
              - generic [ref=e13]:
                - generic: Une aventure d'exploration, de découvertes et de fortune vous attend...
              - generic [ref=e14]:
                - generic: "Version 0.1.3+11 • Mise à jour : 12/04/2026 16:56 • © 2026 SSI"
```

# Test source

```ts
  1   | import { test, expect } from '@playwright/test';
  2   | 
  3   | test.describe('Admin Panel Tests', () => {
  4   |   // Use a long timeout for admin operations
  5   |   test.setTimeout(180000);
  6   | 
  7   |   const SUPER_ADMIN_EMAIL = 'stantest@stanworld.org';
  8   |   const SUPER_ADMIN_PASSWORD = 'Tester=2026';
  9   | 
  10  |   test.beforeEach(async ({ page }) => {
  11  |     await page.goto('/', { waitUntil: 'load', timeout: 60000 });
  12  |     await page.waitForSelector('flutter-view', { timeout: 30000 });
  13  | 
  14  |     // activation de l'accessibilité via plusieurs méthodes (copié depuis smoke.spec.ts)
  15  |     await page.evaluate(() => {
  16  |       const findAndClick = () => {
  17  |         const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
  18  |         const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility' || el.textContent?.includes('accessibility'));
  19  |         if (accessBtn instanceof HTMLElement) {
  20  |           accessBtn.click();
  21  |           return true;
  22  |         }
  23  |         return false;
  24  |       };
  25  |       
  26  |       if (!findAndClick()) {
  27  |         window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
  28  |         setTimeout(findAndClick, 1000);
  29  |       }
  30  |     });
  31  | 
  32  |     await page.waitForTimeout(5000);
  33  |     
  34  |     const accessBtn = page.locator('[aria-label="Enable accessibility"]').first();
  35  |     if (await accessBtn.isVisible()) {
  36  |       await accessBtn.click({ force: true }).catch(() => {});
  37  |     }
  38  |   });
  39  | 
  40  |   async function adminLogin(page) {
  41  |     const emailField = page.locator('[aria-label*="AUTH_EMAIL_FIELD"], [aria-label*="Email de l\'Explorateur"]').first();
  42  |     const passwordField = page.locator('[aria-label*="AUTH_PASSWORD_FIELD"], [aria-label*="Mot de Passe Secret"]').first();
  43  |     const submitBtn = page.locator('[aria-label="AUTH_SUBMIT_BTN"]').first();
  44  | 
  45  |     await emailField.waitFor({ state: 'attached', ...({ timeout: 45000 }) });
  46  |     
  47  |     // Ensure we are in Login mode (not registration)
  48  |     const toggleBtn = page.locator('[aria-label="AUTH_TOGGLE_BTN"]').first();
  49  |     const toggleText = await toggleBtn.innerText().catch(() => '');
  50  |     if (toggleText.includes('SE CONNECTER') || toggleText.toLowerCase().includes('login')) {
  51  |        await toggleBtn.click();
  52  |        await page.waitForTimeout(1000);
  53  |     }
  54  | 
  55  |     const emailBox = await emailField.boundingBox();
  56  |     if (emailBox) {
  57  |       await page.mouse.click(emailBox.x + emailBox.width / 2, emailBox.y + emailBox.height / 2);
  58  |       await page.waitForTimeout(500);
  59  |       await page.keyboard.type(SUPER_ADMIN_EMAIL, { delay: 50 });
  60  |     } else {
  61  |       await emailField.click({ force: true });
  62  |       await page.keyboard.type(SUPER_ADMIN_EMAIL, { delay: 50 });
  63  |     }
  64  |     const passwordBox = await passwordField.boundingBox();
  65  |     if (passwordBox) {
  66  |       await page.mouse.click(passwordBox.x + passwordBox.width / 2, passwordBox.y + passwordBox.height / 2);
  67  |       await page.waitForTimeout(500);
  68  |       await page.keyboard.type(SUPER_ADMIN_PASSWORD, { delay: 50 });
  69  |     } else {
  70  |       await passwordField.click({ force: true });
  71  |       await page.keyboard.type(SUPER_ADMIN_PASSWORD, { delay: 50 });
  72  |     }
  73  |     await page.waitForTimeout(1000);
  74  |     const submitBox = await submitBtn.boundingBox();
  75  |     if (submitBox) {
  76  |       await page.mouse.click(submitBox.x + submitBox.width / 2, submitBox.y + submitBox.height / 2);
  77  |     } else {
  78  |       await submitBtn.click({ force: true });
  79  |     }
  80  | 
  81  |     // Check for success or error
  82  |     const profileBtn = page.locator('[aria-label="PROFILE_BTN"]').first();
  83  |     const errorSnackbar = page.locator('.SnackBar, :text("Erreur"), [aria-label*="Error"]').first();
  84  |     
  85  |     try {
  86  |       // Wait for success without failing if the error snackbar isn't immediately visible
> 87  |       await page.locator('[aria-label="PROFILE_BTN"]').first().waitFor({ state: 'attached', timeout: 120000 });
      |                                                                ^ TimeoutError: locator.waitFor: Timeout 120000ms exceeded.
  88  |       await page.screenshot({ path: `screenshots/admin-login-success-${Date.now()}.png` });
  89  |     } catch (e) {
  90  |       const errorVisible = await page.locator('.SnackBar, :text("Erreur"), [aria-label*="Error"]').first().isVisible();
  91  |       if (errorVisible) {
  92  |         const errorText = await page.locator('.SnackBar, :text("Erreur"), [aria-label*="Error"]').first().innerText().catch(() => 'Unknown error');
  93  |         console.error(`Login failed with error: ${errorText}`);
  94  |         throw new Error(`Login failed for ${SUPER_ADMIN_EMAIL}: ${errorText}`);
  95  |       }
  96  |       console.error(`Login timed out for ${SUPER_ADMIN_EMAIL}. This is likely due to network issues or Firebase performance.`);
  97  |       await page.screenshot({ path: `login-timeout-${Date.now()}.png`, fullPage: true });
  98  |       throw e;
  99  |     }
  100 |   }
  101 | 
  102 |   test('Admin Authentication and Navigation', async ({ page }) => {
  103 |     await adminLogin(page);
  104 | 
  105 |     const profileBtn = page.locator('[aria-label="PROFILE_BTN"]').first();
  106 |     await profileBtn.click();
  107 | 
  108 |     const adminPanelBtn = page.locator('[aria-label="ADMIN_PANEL_BTN"]').first();
  109 |     await adminPanelBtn.waitFor({ state: 'attached', ...({ timeout: 30000 }) });
  110 |     await adminPanelBtn.click();
  111 | 
  112 |     await page.getByText('PANEL ADMINISTRATION').waitFor({ state: 'attached', ...({ timeout: 20000 }) });
  113 |     await page.screenshot({ path: `screenshots/admin-panel-view-${Date.now()}.png` });
  114 |   });
  115 | 
  116 |   test('Modify Player Gold', async ({ page }) => {
  117 |     await adminLogin(page);
  118 | 
  119 |     const profileBtn = page.locator('[aria-label="PROFILE_BTN"]').first();
  120 |     await profileBtn.click();
  121 |     
  122 |     const adminPanelBtn = page.locator('[aria-label="ADMIN_PANEL_BTN"]').first();
  123 |     await adminPanelBtn.waitFor({ state: 'attached', ...({ timeout: 30000 }) });
  124 |     await adminPanelBtn.click();
  125 | 
  126 |     // In the admin panel, find a gold input and change value
  127 |     // Increased timeout for lazy-loaded list items in the admin panel
  128 |     const goldInput = page.locator('input[aria-label*="Gold"], [aria-description*="Gold"]').first();
  129 |     await goldInput.waitFor({ state: 'attached', ...({ timeout: 30000 }) });
  130 |     
  131 |     const originalValue = await goldInput.inputValue();
  132 |     await goldInput.fill('99999');
  133 |     await page.keyboard.press('Enter');
  134 | 
  135 |     // Verify it saved (usually by checking a snackbar or value persistence)
  136 |     await page.waitForTimeout(3000);
  137 |     await expect(goldInput).toHaveValue('99999', { timeout: 10000 });
  138 |     await page.screenshot({ path: `screenshots/admin-gold-modified-${Date.now()}.png` });
  139 |     
  140 |     // Cleanup: restore value
  141 |     await goldInput.fill(originalValue);
  142 |     await page.keyboard.press('Enter');
  143 |     await page.waitForTimeout(1000);
  144 |   });
  145 | });
  146 | 
```