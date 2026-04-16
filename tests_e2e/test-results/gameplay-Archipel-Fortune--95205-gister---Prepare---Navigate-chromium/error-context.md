# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: gameplay.spec.ts >> Archipel Fortune Gameplay Loop >> Full Journey: Register -> Prepare -> Navigate
- Location: tests\gameplay.spec.ts:39:7

# Error details

```
Error: Timed out waiting for login to complete for player_7027@test.com
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
                - generic: PLAYER
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
  3   | test.describe('Archipel Fortune Gameplay Loop', () => {
  4   |   test.setTimeout(240000); // Gameplay takes time
  5   | 
  6   |   const testEmail = `player_${Math.floor(Math.random() * 10000)}@test.com`;
  7   |   const testPassword = 'Password123!';
  8   | 
  9   |   test.beforeEach(async ({ page }) => {
  10  |     await page.goto('/', { waitUntil: 'load', timeout: 60000 });
  11  |     await page.waitForSelector('flutter-view', { timeout: 30000 });
  12  | 
  13  |     // activation de l'accessibilité via plusieurs méthodes (copié depuis smoke.spec.ts)
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
  24  |       
  25  |       if (!findAndClick()) {
  26  |         window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
  27  |         setTimeout(findAndClick, 1000);
  28  |       }
  29  |     });
  30  | 
  31  |     await page.waitForTimeout(5000);
  32  |     
  33  |     const accessBtn = page.locator('[aria-label="Enable accessibility"]').first();
  34  |     if (await accessBtn.isVisible()) {
  35  |       await accessBtn.click({ force: true }).catch(() => {});
  36  |     }
  37  |   });
  38  | 
  39  |   test('Full Journey: Register -> Prepare -> Navigate', async ({ page }) => {
  40  |     // 1. Ensure we are in registration mode
  41  |     const toggleBtn = page.locator('[aria-label="AUTH_TOGGLE_BTN"]').first();
  42  |     await toggleBtn.waitFor({ state: 'attached', ...({ timeout: 45000 }) });
  43  |     const toggleText = await toggleBtn.innerText();
  44  |     
  45  |     // We want registration mode.
  46  |     // If the button says "DÉJÀ MEMBRE ? SE CONNECTER", we are already in registration mode.
  47  |     // If it says "NOUVELLE RECRUE ? CRÉER UN PROFIL", we are in login mode, so click to switch.
  48  |     if (toggleText.includes('CRÉER UN PROFIL')) {
  49  |       await toggleBtn.click();
  50  |       await page.waitForTimeout(1000);
  51  |     }
  52  | 
  53  |     const emailField = page.locator('[aria-label*="AUTH_EMAIL_FIELD"], [aria-label*="Email de l\'Explorateur"]').first();
  54  |     const passwordField = page.locator('[aria-label*="AUTH_PASSWORD_FIELD"], [aria-label*="Mot de Passe Secret"]').first();
  55  |     const submitBtn = page.locator('[aria-label="AUTH_SUBMIT_BTN"]').first();
  56  | 
  57  |     const emailBox = await emailField.boundingBox();
  58  |     if (emailBox) {
  59  |       await page.mouse.click(emailBox.x + emailBox.width / 2, emailBox.y + emailBox.height / 2);
  60  |       await page.waitForTimeout(500);
  61  |       await page.keyboard.type(testEmail, { delay: 50 });
  62  |     } else {
  63  |       await emailField.click({ force: true });
  64  |       await page.keyboard.type(testEmail, { delay: 50 });
  65  |     }
  66  |     const passwordBox = await passwordField.boundingBox();
  67  |     if (passwordBox) {
  68  |       await page.mouse.click(passwordBox.x + passwordBox.width / 2, passwordBox.y + passwordBox.height / 2);
  69  |       await page.waitForTimeout(500);
  70  |       await page.keyboard.type(testPassword, { delay: 50 });
  71  |     } else {
  72  |       await passwordField.click({ force: true });
  73  |       await page.keyboard.type(testPassword, { delay: 50 });
  74  |     }
  75  |     await page.waitForTimeout(1000);
  76  |     const submitBox = await submitBtn.boundingBox();
  77  |     if (submitBox) {
  78  |       await page.mouse.click(submitBox.x + submitBox.width / 2, submitBox.y + submitBox.height / 2);
  79  |     } else {
  80  |       await submitBtn.click({ force: true });
  81  |     }
  82  | 
  83  |     // 2. Wait for login to complete (increased timeout for slow CI)
  84  |     try {
  85  |       await page.locator('[aria-label="PROFILE_BTN"]').first().waitFor({ state: 'attached', timeout: 120000 });
  86  |     } catch (e) {
  87  |       const errorVisible = await page.locator('.SnackBar, :text("Erreur"), [aria-label*="Error"]').first().isVisible();
  88  |       if (errorVisible) {
  89  |         const errorText = await page.locator('.SnackBar, :text("Erreur"), [aria-label*="Error"]').first().innerText().catch(() => 'Unknown error');
  90  |         throw new Error(`Registration/Login failed for ${testEmail}: ${errorText}`);
  91  |       }
  92  |       await page.screenshot({ path: `gameplay-auth-timeout-${Date.now()}.png`, fullPage: true });
> 93  |       throw new Error(`Timed out waiting for login to complete for ${testEmail}`);
      |             ^ Error: Timed out waiting for login to complete for player_7027@test.com
  94  |     }
  95  | 
  96  |     // 3. HomeView check
  97  |     const exploreBtn = page.locator('[aria-label="EXPLORE_MAIN_BTN"]').first();
  98  |     await exploreBtn.waitFor({ state: 'attached', ...({ timeout: 45000 }) });
  99  |     await exploreBtn.click({ force: true });
  100 | 
  101 |     // 4. Preparation Dialog
  102 |     const startExpBtn = page.locator('[aria-label="START_EXPEDITION_BTN"]').first();
  103 |     await startExpBtn.waitFor({ state: 'attached', ...({ timeout: 20000 }) });
  104 |     await startExpBtn.click();
  105 | 
  106 |     // 5. Session View (Map)
  107 |     // The position text is a great way to confirm we are in the session
  108 |     // Updated for 64x64 map (Center is 32, 32)
  109 |     await page.getByText(/POSITION: 32, 32/i).waitFor({ state: 'attached', ...({ timeout: 45000 }) });
  110 | 
  111 |     // 6. Movement
  112 |     const advanceBtn = page.locator('[aria-label="MOVE_UP_BTN"]').first();
  113 |     await advanceBtn.waitFor({ state: 'attached', ...({ timeout: 10000 }) });
  114 |     await advanceBtn.click();
  115 | 
  116 |     // Position update verification (Move up from 32, 32 -> 32, 31)
  117 |     await page.getByText(/POSITION: 32, 31/i).waitFor({ state: 'attached', ...({ timeout: 15000 }) });
  118 |   });
  119 | });
  120 | 
```