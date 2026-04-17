import { Page, Locator, expect } from '@playwright/test';

/**
 * Ensures Flutter Web accessibility (semantics) is enabled.
 * Critical for CanvasKit renderer in headless CI.
 */
export async function ensureAccessibility(page: Page) {
    // 1. Wait for the app container
    await page.waitForSelector('flutter-view', { timeout: 30000 });
    
    // 2. Try to click the hidden accessibility button if it exists
    const accessBtn = page.locator('flt-semantics-placeholder, [aria-label="Enable accessibility"]').first();
    const isVisible = await accessBtn.isVisible().catch(() => false);
    
    if (isVisible) {
        await accessBtn.click({ force: true }).catch(() => {});
    }

    // 3. Send a native TAB key press - this is the most reliable way to trigger semantics in most Flutter versions
    await page.keyboard.press('Tab');
    
    // 4. Wait for the semantics tree to populate
    // We expect at least one flt-semantics node to appear eventually
    await page.waitForSelector('flt-semantics', { timeout: 10000 }).catch(() => {
        console.log("Warning: No flt-semantics nodes found after Tab. This might be normal if the page is empty.");
    });

    // 5. Short stability delay
    await page.waitForTimeout(2000);
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
    await locator.waitFor({ state: 'attached', timeout: options.timeout || 30000 });
    
    // Slow computer stability
    await page.waitForTimeout(500);

    const box = await locator.boundingBox();
    if (!box) {
        // Fallback to standard click if no bounding box
        await locator.click({ force: true }).catch(() => {});
        return;
    }

    const x = box.x + box.width / 2;
    const y = box.y + box.height / 2;

    try {
        // Move mouse and click using coordinates - often more reliable for CanvasKit
        await page.mouse.move(x, y);
        await page.mouse.down();
        await page.waitForTimeout(100);
        await page.mouse.up();
        // Give time for UI feedback
        await page.waitForTimeout(500);
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
    
    // Check toggle text to determine mode
    const text = await toggleBtn.textContent().catch(() => '');
    const altText = await toggleBtn.getAttribute('aria-label').catch(() => '');
    const combinedText = (text + altText).toUpperCase();

    // If we want to LOGIN, but the toggle suggests switching TO login, we click it.
    // Labels: "NOUVELLE RECRUE ? CRÉER UN PROFIL" (we are in login mode)
    //         "DÉJÀ MEMBRE ? SE CONNECTER" (we are in register mode)
    if (combinedText.includes('DÉJÀ MEMBRE') || combinedText.includes('CONNECTER')) {
        await robustClick(page, toggleBtn);
        await page.waitForTimeout(1000);
    }

    // Fill email
    await robustClick(page, emailField);
    await page.keyboard.type(email, { delay: 30 });
    
    // Fill password
    await robustClick(page, passwordField);
    await page.keyboard.type(pass, { delay: 30 });

    await page.waitForTimeout(500);
    
    // Submit
    await robustClick(page, submitBtn);
}
