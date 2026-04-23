# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: gameplay.spec.ts >> Archipel Fortune Gameplay Loop >> Full Journey: Register -> Prepare -> Navigate
- Location: tests\gameplay.spec.ts:15:7

# Error details

```
TimeoutError: locator.waitFor: Timeout 60000ms exceeded.
Call log:
  - waiting for locator('[aria-label*="START_EXPEDITION_BTN"], [aria-label="START_EXPEDITION_BTN"], flt-semantics:has-text("START_EXPEDITION_BTN")').first()

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
              - generic:
                - generic: APP_TITLE L'Archipel de la Fortune
              - generic:
                - generic: Capitaine
              - generic:
                - generic: 🪙
              - generic:
                - generic: 50 Pièces d'Or
              - generic:
                - generic: PLAYER
              - button "EXPLORE_MAIN_BTN" [ref=e7]
              - generic:
                - generic: Une aventure d'exploration, de découvertes et de fortune vous attend...
              - generic:
                - generic: "Version 0.1.3+11 • Mise à jour : 12/04/2026 16:56 • © 2026 SSI"
```

# Test source

```ts
  1   | import { Page, Locator, expect } from '@playwright/test';
  2   | 
  3   | /**
  4   |  * Ensures Flutter Web accessibility (semantics) is enabled.
  5   |  * Critical for CanvasKit renderer in headless CI.
  6   |  */
  7   | export async function ensureAccessibility(page: Page) {
  8   |     // 1. Wait for the app container
  9   |     await page.waitForSelector('flutter-view', { timeout: 60000 });
  10  |     
  11  |     // 2. Try to click the hidden accessibility button if it exists
  12  |     const accessBtn = page.locator('flt-semantics-placeholder, [aria-label="Enable accessibility"]').first();
  13  |     const isVisible = await accessBtn.isVisible().catch(() => false);
  14  |     
  15  |     if (isVisible) {
  16  |         await accessBtn.click({ force: true }).catch(() => {});
  17  |     }
  18  | 
  19  |     // 3. Send a native TAB key press - this is the most reliable way to trigger semantics in most Flutter versions
  20  |     await page.keyboard.press('Tab');
  21  |     
  22  |     // 4. Wait for the semantics tree to populate
  23  |     // We expect at least one flt-semantics node to appear eventually
  24  |     await page.waitForSelector('flt-semantics', { timeout: 30000 }).catch(() => {
  25  |         console.log("Warning: No flt-semantics nodes found after Tab. This might be normal if the page is empty.");
  26  |     });
  27  | 
  28  |     // 5. Short stability delay
  29  |     await page.waitForTimeout(2000);
  30  | }
  31  | 
  32  | /**
  33  |  * Waits for the app to be fully loaded and interactive.
  34  |  */
  35  | export async function waitForAppLoaded(page: Page, options: { timeout?: number } = {}) {
  36  |     await page.waitForSelector('flutter-view', { timeout: options.timeout || 60000 });
  37  |     await ensureAccessibility(page);
  38  | }
  39  | 
  40  | /**
  41  |  * Robustly finds an element using role, aria-label or text content (regex).
  42  |  * Targets flt-semantics nodes specifically used by Flutter Web.
  43  |  */
  44  | export function getResilientLocator(page: Page, label: string): Locator {
  45  |     // Target nodes that have the label in aria-label or inner text
  46  |     return page.locator(`[aria-label*="${label}"], [aria-label="${label}"], flt-semantics:has-text("${label}")`).first();
  47  | }
  48  | 
  49  | /**
  50  |  * Clicks an element using multiple strategies sequentially (standard, coordinate, pointer sequence).
  51  |  * Essential for Flutter Web where semantic nodes can be finicky.
  52  |  */
  53  | export async function robustClick(page: Page, locator: Locator, options: { timeout?: number } = {}) {
> 54  |     await locator.waitFor({ state: 'attached', timeout: options.timeout || 60000 });
      |                   ^ TimeoutError: locator.waitFor: Timeout 60000ms exceeded.
  55  |     
  56  |     // Slow computer stability
  57  |     await page.waitForTimeout(500);
  58  | 
  59  |     const box = await locator.boundingBox();
  60  |     if (!box) {
  61  |         // Fallback to standard click if no bounding box
  62  |         await locator.click({ force: true }).catch(() => {});
  63  |         return;
  64  |     }
  65  | 
  66  |     const x = box.x + box.width / 2;
  67  |     const y = box.y + box.height / 2;
  68  | 
  69  |     try {
  70  |         // Move mouse and click using coordinates - often more reliable for CanvasKit
  71  |         await page.mouse.move(x, y);
  72  |         await page.mouse.down();
  73  |         await page.waitForTimeout(100);
  74  |         await page.mouse.up();
  75  |         // Give time for UI feedback
  76  |         await page.waitForTimeout(500);
  77  |     } catch (e) {
  78  |         await locator.click({ force: true }).catch(() => {});
  79  |     }
  80  | }
  81  | 
  82  | /**
  83  |  * Specialized login helper for Archipel Fortune
  84  |  */
  85  | export async function archipelLogin(page: Page, email: string, pass: string) {
  86  |     const emailField = getResilientLocator(page, 'AUTH_EMAIL_FIELD');
  87  |     const passwordField = getResilientLocator(page, 'AUTH_PASSWORD_FIELD');
  88  |     const submitBtn = getResilientLocator(page, 'AUTH_SUBMIT_BTN');
  89  | 
  90  |     // Handle Switch if necessary (ensure in login mode)
  91  |     const toggleBtn = getResilientLocator(page, 'AUTH_TOGGLE_BTN');
  92  |     
  93  |     // Check toggle text to determine mode
  94  |     const text = await toggleBtn.textContent().catch(() => '');
  95  |     const altText = await toggleBtn.getAttribute('aria-label').catch(() => '');
  96  |     const combinedText = (text + altText).toUpperCase();
  97  | 
  98  |     // If we want to LOGIN, but the toggle suggests switching TO login, we click it.
  99  |     // Labels: "NOUVELLE RECRUE ? CRÉER UN PROFIL" (we are in login mode)
  100 |     //         "DÉJÀ MEMBRE ? SE CONNECTER" (we are in register mode)
  101 |     if (combinedText.includes('DÉJÀ MEMBRE') || combinedText.includes('CONNECTER')) {
  102 |         await robustClick(page, toggleBtn);
  103 |         await page.waitForTimeout(1000);
  104 |     }
  105 | 
  106 |     // Fill email
  107 |     await robustClick(page, emailField);
  108 |     await page.keyboard.type(email, { delay: 30 });
  109 |     
  110 |     // Fill password
  111 |     await robustClick(page, passwordField);
  112 |     await page.keyboard.type(pass, { delay: 30 });
  113 | 
  114 |     await page.waitForTimeout(500);
  115 |     
  116 |     // Submit
  117 |     await robustClick(page, submitBtn);
  118 | }
  119 | 
```