# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: gameplay.spec.ts >> Archipel Fortune Gameplay Loop >> Full Journey: Register -> Prepare -> Navigate
- Location: tests\gameplay.spec.ts:34:7

# Error details

```
TimeoutError: locator.waitFor: Timeout 20000ms exceeded.
Call log:
  - waiting for locator('[aria-label*="START_EXPEDITION_BTN"], flt-semantics:has-text("START_EXPEDITION_BTN")').first()

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
  1  | import { Page, Locator } from '@playwright/test';
  2  | 
  3  | /**
  4  |  * Robustly finds an element using role, aria-label or text content (regex).
  5  |  */
  6  | export function getResilientLocator(page: Page, label: string): Locator {
  7  |     // Priority: Explicit aria-label, followed by fuzzy text match inside flt-semantics nodes
  8  |     return page.locator(`[aria-label*="${label}"], flt-semantics:has-text("${label}")`).first();
  9  | }
  10 | 
  11 | /**
  12 |  * Clicks an element using multiple strategies sequentially (standard, coordinate, pointer sequence).
  13 |  * Essential for Flutter Web where semantic nodes can be finicky.
  14 |  */
  15 | export async function robustClick(page: Page, locator: Locator, options: { timeout?: number } = {}) {
> 16 |     await locator.waitFor({ state: 'attached', timeout: options.timeout || 30000 });
     |                   ^ TimeoutError: locator.waitFor: Timeout 20000ms exceeded.
  17 |     
  18 |     // Brief pause to allow Flutter semantics to settle
  19 |     await page.waitForTimeout(500);
  20 | 
  21 |     const box = await locator.boundingBox();
  22 |     if (!box) {
  23 |         await locator.click({ force: true });
  24 |         return;
  25 |     }
  26 | 
  27 |     const x = box.x + box.width / 2;
  28 |     const y = box.y + box.height / 2;
  29 | 
  30 |     // Strategy: Move -> Down -> Wait -> Up
  31 |     try {
  32 |         await page.mouse.move(x, y);
  33 |         await page.mouse.down();
  34 |         await page.waitForTimeout(200);
  35 |         await page.mouse.up();
  36 |     } catch (e) {
  37 |         // Ultimate fallback
  38 |         await locator.click({ force: true });
  39 |     }
  40 | }
  41 | 
  42 | /**
  43 |  * Specialized login helper for Archipel Fortune
  44 |  */
  45 | export async function archipelLogin(page: Page, email: string, pass: string) {
  46 |     const emailField = getResilientLocator(page, 'AUTH_EMAIL_FIELD');
  47 |     const passwordField = getResilientLocator(page, 'AUTH_PASSWORD_FIELD');
  48 |     const submitBtn = getResilientLocator(page, 'AUTH_SUBMIT_BTN');
  49 | 
  50 |     // Handle Switch if necessary (ensure in login mode)
  51 |     const toggleBtn = getResilientLocator(page, 'AUTH_TOGGLE_BTN');
  52 |     const toggleText = await toggleBtn.innerText().catch(() => '');
  53 |     
  54 |     // If we want to LOGIN, but the toggle says "DÉJÀ MEMBRE ? SE CONNECTER",
  55 |     // it means we are currently in REGISTER mode. Click to switch.
  56 |     if (toggleText.includes('DÉJÀ MEMBRE') || toggleText.includes('CONNECTER')) {
  57 |         await robustClick(page, toggleBtn);
  58 |         await page.waitForTimeout(1000);
  59 |     }
  60 | 
  61 |     // Fill email
  62 |     await robustClick(page, emailField);
  63 |     await page.keyboard.type(email, { delay: 50 });
  64 |     
  65 |     // Fill password
  66 |     await robustClick(page, passwordField);
  67 |     await page.keyboard.type(pass, { delay: 50 });
  68 | 
  69 |     await page.waitForTimeout(1000);
  70 |     
  71 |     // Submit
  72 |     await robustClick(page, submitBtn);
  73 | }
  74 | 
```