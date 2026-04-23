import { Page, Locator, expect } from '@playwright/test';

/**
 * Ensures Flutter Web accessibility (semantics) is enabled.
 * Critical for CanvasKit renderer in headless CI.
 */
export async function ensureAccessibility(page: Page) {
    // 1. Wait for the app container
    await page.waitForSelector('flutter-view', { timeout: 60000 });
    
    // 2. Try to click the hidden accessibility button if it exists
    const accessBtn = page.locator('flt-semantics-placeholder, [aria-label="Enable accessibility"]').first();
    const isVisible = await accessBtn.isVisible().catch(() => false);
    
    if (isVisible) {
        await accessBtn.click({ force: true }).catch(() => {});
    }

    // 3. Send multiple native TAB key presses - some Flutter versions need more than one
    await page.keyboard.press('Tab');
    await page.waitForTimeout(500);
    await page.keyboard.press('Tab');
    
    // 4. Wait for the semantics tree to populate
    // We expect at least one flt-semantics node to appear eventually
    try {
        await page.waitForSelector('flt-semantics', { timeout: 45000 });
    } catch (e) {
        console.log("Warning: No flt-semantics nodes found after Tab. Retrying Tab...");
        await page.keyboard.press('Tab');
        await page.waitForTimeout(2000);
    }

    // 5. Short stability delay
    await page.waitForTimeout(2000);
}

/**
 * Waits for any loading indicator (CircularProgressIndicator) to disappear.
 */
export async function waitForNoLoading(page: Page, options: { timeout?: number } = {}) {
    // Wait for the indicator to potentially appear, then disappear
    // In Flutter, these often have aria-label "Chargement" or similar, or just a specific role
    const loader = page.locator('flt-semantics[role="progressbar"], [aria-label*="Loading"], [aria-label*="Chargement"]').first();
    
    // Give it a moment to appear if it's about to
    await page.waitForTimeout(1000);
    
    if (await loader.isVisible()) {
        await loader.waitFor({ state: 'hidden', timeout: options.timeout || 60000 }).catch(() => {
            console.log("Timeout waiting for loader to hide, continuing anyway...");
        });
    }
}

/**
 * Waits for the app to be fully loaded and interactive.
 */
export async function waitForAppLoaded(page: Page, options: { timeout?: number } = {}) {
    await page.waitForSelector('flutter-view', { timeout: options.timeout || 60000 });
    await ensureAccessibility(page);
}

/**
 * Robustly finds an element using role, aria-label or text content (regex).
 * Targets flt-semantics nodes specifically used by Flutter Web.
 */
export function getResilientLocator(page: Page, label: string): Locator {
    // Target nodes that have the label in aria-label or inner text
    return page.locator(`[aria-label*="${label}"], [aria-label="${label}"], flt-semantics:has-text("${label}")`).first();
}

/**
 * Clicks an element using multiple strategies sequentially (standard, coordinate, pointer sequence).
 * Essential for Flutter Web where semantic nodes can be finicky.
 */
export async function robustClick(page: Page, locator: Locator, options: { timeout?: number } = {}) {
    await locator.waitFor({ state: 'attached', timeout: options.timeout || 60000 });
    
    // Stability check: Ensure the element is not moving (useful for animated menus)
    let prevBox = await locator.boundingBox();
    for (let i = 0; i < 5; i++) {
        await page.waitForTimeout(200);
        const currentBox = await locator.boundingBox();
        if (prevBox && currentBox && 
            Math.abs(prevBox.x - currentBox.x) < 1 && 
            Math.abs(prevBox.y - currentBox.y) < 1) {
            break; // Element is stable
        }
        prevBox = currentBox;
    }

    const box = await locator.boundingBox();
    if (!box) {
        // Fallback to standard click if no bounding box
        await locator.click({ force: true, timeout: 15000 }).catch(() => {});
        return;
    }

    const x = box.x + box.width / 2;
    const y = box.y + box.height / 2;

    try {
        // Move mouse and click using coordinates - often more reliable for CanvasKit
        await page.mouse.move(x, y);
        await page.mouse.down();
        await page.waitForTimeout(150); // Slightly longer press
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
    const toggleBtn = getResilientLocator(page, 'AUTH_TOGGLE_BTN');

    // Wait for stability
    await page.waitForTimeout(2000);

    // 1. Ensure we are in LOGIN mode, not REGISTER
    const text = await toggleBtn.textContent().catch(() => '');
    const altText = await toggleBtn.getAttribute('aria-label').catch(() => '');
    const combinedText = (text + altText).toUpperCase();

    if (combinedText.includes('DÉJÀ MEMBRE') || combinedText.includes('CONNECTER')) {
        await robustClick(page, toggleBtn);
        await page.waitForTimeout(1500);
    }

    // 2. Fill email (with clear)
    await robustClick(page, emailField);
    await page.keyboard.press('Control+A');
    await page.keyboard.press('Backspace');
    await page.keyboard.type(email, { delay: 50 });
    
    // 3. Fill password (with clear)
    await robustClick(page, passwordField);
    await page.keyboard.press('Control+A');
    await page.keyboard.press('Backspace');
    await page.keyboard.type(pass, { delay: 50 });

    await page.waitForTimeout(1000);
    
    // 4. Submit and wait for loading to start/finish
    await robustClick(page, submitBtn);
    
    // Wait for the app to react
    await page.waitForTimeout(2000);
    await waitForNoLoading(page);
}
