import { Page, Locator } from '@playwright/test';

/**
 * Robustly finds an element using role, aria-label or text content (regex).
 */
export function getResilientLocator(page: Page, label: string): Locator {
    // Priority: Explicit aria-label, followed by fuzzy text match inside flt-semantics nodes
    return page.locator(`[aria-label*="${label}"], flt-semantics:has-text("${label}")`).first();
}

/**
 * Clicks an element using multiple strategies sequentially (standard, coordinate, pointer sequence).
 * Essential for Flutter Web where semantic nodes can be finicky.
 */
export async function robustClick(page: Page, locator: Locator, options: { timeout?: number } = {}) {
    await locator.waitFor({ state: 'attached', timeout: options.timeout || 30000 });
    
    // Slow computer stability
    await page.waitForTimeout(1000);

    const box = await locator.boundingBox();
    if (!box) {
        await locator.click({ force: true }).catch(() => {});
        return;
    }

    const x = box.x + box.width / 2;
    const y = box.y + box.height / 2;

    try {
        await page.mouse.move(x, y);
        await page.mouse.down();
        await page.waitForTimeout(300);
        await page.mouse.up();
        // Give time for UI feedback
        await page.waitForTimeout(1000);
    } catch (e) {
        await locator.click({ force: true }).catch(() => {});
    }
}

/**
 * Specialized login helper for Archipel Fortune
 */
export async function archipelLogin(page: Page, email: string, pass: string) {
    const emailField = getResilientLocator(page, 'AUTH_EMAIL_FIELD');
    const passwordField = getResilientLocator(page, 'AUTH_PASSWORD_FIELD');
    const submitBtn = getResilientLocator(page, 'AUTH_SUBMIT_BTN');

    // Handle Switch if necessary (ensure in login mode)
    const toggleBtn = getResilientLocator(page, 'AUTH_TOGGLE_BTN');
    const toggleText = await toggleBtn.innerText().catch(() => '');
    
    // If we want to LOGIN, but the toggle says "DÉJÀ MEMBRE ? SE CONNECTER",
    // it means we are currently in REGISTER mode. Click to switch.
    if (toggleText.includes('DÉJÀ MEMBRE') || toggleText.includes('CONNECTER')) {
        await robustClick(page, toggleBtn);
        await page.waitForTimeout(1000);
    }

    // Fill email
    await robustClick(page, emailField);
    await page.keyboard.type(email, { delay: 50 });
    
    // Fill password
    await robustClick(page, passwordField);
    await page.keyboard.type(pass, { delay: 50 });

    await page.waitForTimeout(1000);
    
    // Submit
    await robustClick(page, submitBtn);
}
