import { Page, Locator } from '@playwright/test';

/**
 * Robustly finds an element using either aria-label or text content.
 * Useful for Flutter Web where semantics can be inconsistent.
 */
export function getResilientLocator(page: Page, label: string): Locator {
    return page.locator(`[aria-label="${label}"], :text("${label}")`).first();
}

/**
 * Clicks an element by its center coordinates to bypass hit-testing issues
 * in Flutter's transparent semantic layer.
 */
export async function clickCoordinate(page: Page, locator: Locator, options: { timeout?: number } = {}) {
    await locator.waitFor({ state: 'attached', timeout: options.timeout || 30000 });
    const box = await locator.boundingBox();
    if (box) {
        await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    } else {
        // Fallback to regular click if no bounding box
        await locator.click({ force: true });
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
    if (toggleText.includes('CRÉER UN PROFIL')) {
        await clickCoordinate(page, toggleBtn);
        await page.waitForTimeout(1000);
    }

    // Fill email
    await clickCoordinate(page, emailField);
    await page.keyboard.type(email, { delay: 50 });
    
    // Fill password
    await clickCoordinate(page, passwordField);
    await page.keyboard.type(pass, { delay: 50 });

    await page.waitForTimeout(1000);
    
    // Submit
    await clickCoordinate(page, submitBtn);
}
