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

    // 3. Send multiple native TAB key presses - critical for enabling the semantic tree
    for (let i = 0; i < 3; i++) {
        await page.keyboard.press('Tab');
        await page.waitForTimeout(500);
    }
    
    // 4. Wait for the semantics tree to populate
    try {
        await page.waitForSelector('flt-semantics', { timeout: 45000 });
    } catch (e) {
        console.log("Warning: No flt-semantics nodes found after Tab. Retrying Tab sequence...");
        await page.keyboard.press('Tab');
        await page.waitForTimeout(2000);
        await page.keyboard.press('Tab');
    }

    // 5. Final stability delay
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

export async function getResilientLocator(page: Page, label: string): Promise<Locator> {
    // Target nodes that have the label in aria-label, tooltip or inner text
    const escapedLabel = label.replace(/"/g, '\\"');
    
    // We try multiple strategies in order of reliability
    const selectors = [
        `flt-semantics[aria-label="${escapedLabel}"]:visible`,
        `flt-semantics[aria-label*="${escapedLabel}"]:visible`,
        `flt-semantics[title="${escapedLabel}"]:visible`,
        `flt-semantics:has-text("${escapedLabel}"):visible`,
        `[aria-label="${escapedLabel}"]:visible`,
        `[aria-label*="${escapedLabel}"]:visible`,
        `[role="button"]:has-text("${escapedLabel}"):visible`,
        `[role="menuitem"]:has-text("${escapedLabel}"):visible`
    ];

    const allElements = page.locator(selectors.join(', '));

    const count = await allElements.count().catch(() => 0);
    if (count === 0) {
        // Return a locator that will fail with a descriptive error if waited on
        return allElements.first(); 
    }
    
    if (count === 1) return allElements.first();

    // If multiple, pick the one with the smallest non-zero area (usually the actual interactive button vs its container)
    let bestIndex = 0;
    let minArea = Infinity;

    for (let i = 0; i < count; i++) {
        const box = await allElements.nth(i).boundingBox().catch(() => null);
        if (box) {
            const area = box.width * box.height;
            // Filter out clearly wrong sizes (like 0x0 or full-screen wrappers)
            if (area > 1 && area < minArea && area < (800 * 600)) { 
                minArea = area;
                bestIndex = i;
            }
        }
    }

    return allElements.nth(bestIndex);
}

/**
 * Utility to log the current semantic tree for debugging CI failures.
 */
export async function dumpSemanticTree(page: Page) {
    console.log("--- START SEMANTIC TREE DUMP ---");
    const tree = await page.evaluate(() => {
        const nodes = Array.from(document.querySelectorAll('flt-semantics'));
        return nodes.map(n => ({
            label: n.getAttribute('aria-label'),
            text: n.textContent?.trim(),
            role: n.getAttribute('role'),
            visible: n.clientHeight > 0 && n.clientWidth > 0
        })).filter(n => n.label || n.text);
    });
    console.table(tree);
    console.log("--- END SEMANTIC TREE DUMP ---");
}


/**
 * Specifically targets a menu item in a Flutter PopupMenuButton.
 */
export async function clickMenuItem(page: Page, menuAnchorLabel: string, itemLabel: string) {
    const anchor = await getResilientLocator(page, menuAnchorLabel);
    
    // Ensure anchor is interactive
    await anchor.waitFor({ state: 'visible', timeout: 30000 }).catch(() => {
        console.log(`Warning: Anchor ${menuAnchorLabel} not visible, trying anyway...`);
    });

    const box = await anchor.boundingBox();
    console.log(`Opening menu via anchor: ${menuAnchorLabel}, box: ${JSON.stringify(box)}`);
    
    // 1. Try Keyboard interaction (best for Flutter)
    await anchor.focus().catch(() => {});
    await page.keyboard.press('Enter');
    await page.waitForTimeout(1000); // Wait for rebuild
    
    // 2. Check if menu appeared
    let menuVisible = await page.evaluate(() => {
        const items = Array.from(document.querySelectorAll('flt-semantics'));
        return items.some(i => {
            const label = i.getAttribute('aria-label') || '';
            return label.includes('Panel Admin') || label.includes('Déconnexion') || label.includes('ADMIN_PANEL_BTN');
        });
    });

    if (!menuVisible) {
        console.log("Menu not open after Enter, trying robustClick and Space...");
        await robustClick(page, anchor);
        await page.waitForTimeout(500);
        await page.keyboard.press(' '); 
        await page.waitForTimeout(1500);
    }
    
    // Force semantic tree update for the menu by Tabbing
    await page.keyboard.press('Tab');
    await page.waitForTimeout(1000); 
    
    // 3. Find the item
    let item = await getResilientLocator(page, itemLabel);
    
    // Fallback labels for Admin Panel
    if (await item.count() === 0 && itemLabel === 'ADMIN_PANEL_BTN') {
        console.log("ADMIN_PANEL_BTN not found by label, trying text 'Panel Admin'");
        item = await getResilientLocator(page, 'Panel Admin');
    }
    
    // Aggressive retry if still not found
    if (await item.count() === 0) {
        console.log(`Item ${itemLabel} still not found. Trying more Tabs and Dumping Tree...`);
        await dumpSemanticTree(page);
        for (let i = 0; i < 3; i++) {
            await page.keyboard.press('Tab');
            await page.waitForTimeout(500);
            item = await getResilientLocator(page, itemLabel);
            if (await item.count() > 0) break;
            if (itemLabel === 'ADMIN_PANEL_BTN') {
                item = await getResilientLocator(page, 'Panel Admin');
                if (await item.count() > 0) break;
            }
        }
    }
    
    // 4. Click the item
    try {
        await item.waitFor({ state: 'visible', timeout: 30000 });
        await robustClick(page, item);
        await page.waitForTimeout(1000); // wait for navigation
    } catch (e) {
        await page.screenshot({ path: `screenshots/failed-menu-item-${itemLabel}-${Date.now()}.png` });
        await dumpSemanticTree(page);
        throw e;
    }
}




/**
 * Clicks an element using multiple strategies sequentially (standard, coordinate, pointer sequence).
 * Essential for Flutter Web where semantic nodes can be finicky.
 */
export async function robustClick(page: Page, locator: Locator, options: { timeout?: number } = {}) {
    await locator.waitFor({ state: 'attached', timeout: options.timeout || 60000 });
    
    const label = await locator.getAttribute('aria-label').catch(() => null) ?? 'unlabeled element';
    console.log(`Attempting robustClick on: ${label}`);

    try {
        // 1. Try standard click first
        await locator.click({ force: true, timeout: 5000 });
        await page.waitForTimeout(500);
        return;
    } catch (e) {
        console.log(`Standard click failed for ${label}, trying coordinates...`);
    }

    const box = await locator.boundingBox();
    if (!box) {
        console.log(`No bounding box for ${label}, trying force click again...`);
        await locator.click({ force: true, timeout: 10000 }).catch(() => {});
        return;
    }

    const x = box.x + box.width / 2;
    const y = box.y + box.height / 2;

    try {
        await page.mouse.move(x, y);
        await page.mouse.down();
        await page.waitForTimeout(200); 
        await page.mouse.up();
        await page.waitForTimeout(1000);
    } catch (e) {
        console.log(`Coordinate click failed for ${label}`);
    }
}

/**
 * Specialized login helper for Archipel Fortune
 */
export async function archipelLogin(page: Page, email: string, pass: string) {
    const emailField = await getResilientLocator(page, 'AUTH_EMAIL_FIELD');
    const passwordField = await getResilientLocator(page, 'AUTH_PASSWORD_FIELD');
    const submitBtn = await getResilientLocator(page, 'AUTH_SUBMIT_BTN');
    const toggleBtn = await getResilientLocator(page, 'AUTH_TOGGLE_BTN');

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
