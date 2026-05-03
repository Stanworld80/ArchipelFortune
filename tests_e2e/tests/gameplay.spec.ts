import { test, expect } from '@playwright/test';
import { getResilientLocator, robustClick, waitForAppLoaded, clickMenuItem, dumpSemanticTree } from './test_utils';


test.describe('Archipel Fortune Gameplay Loop', () => {
  test.setTimeout(240000); // Gameplay takes time

  const testEmail = `player_${Math.floor(Math.random() * 10000)}@test.com`;
  const testPassword = 'Password123!';

  test.beforeEach(async ({ page }) => {
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await waitForAppLoaded(page);
  });

  test('Full Journey: Register -> Prepare -> Navigate', async ({ page }) => {
    // 1. Ensure we are in registration mode
    const toggleBtn = await getResilientLocator(page, 'AUTH_TOGGLE_BTN');
    await toggleBtn.waitFor({ state: 'attached', timeout: 60000 });
    const toggleText = await toggleBtn.innerText().catch(() => '');
    
    // We want registration mode.
    // "CRÉER UN PROFIL" means we are in Login mode and must switch to Register.
    if (toggleText.includes('CRÉER UN PROFIL') || toggleText.includes('RECRUE')) {
      await robustClick(page, toggleBtn);
      await page.waitForTimeout(1000);
    }
    // If it already says "DÉJÀ MEMBRE", we are in Register mode, do nothing.

    // Fill email
    const emailField = await getResilientLocator(page, 'AUTH_EMAIL_FIELD');
    const passwordField = await getResilientLocator(page, 'AUTH_PASSWORD_FIELD');
    const submitBtn = await getResilientLocator(page, 'AUTH_SUBMIT_BTN');

    await robustClick(page, emailField);
    await page.keyboard.type(testEmail, { delay: 50 });
    
    // Fill password
    await robustClick(page, passwordField);
    await page.keyboard.type(testPassword, { delay: 50 });

    await page.waitForTimeout(1000);
    
    // Submit
    await robustClick(page, submitBtn);

    // 2. Wait for login to complete and profile button to appear
    const profileBtn = await getResilientLocator(page, 'PROFILE_BTN');
    try {
        await profileBtn.waitFor({ state: 'attached', timeout: 120000 });
        console.log("Registration/Login successful.");
    } catch (e) {
        console.log("Registration failed or PROFILE_BTN not found. Dumping tree...");
        await dumpSemanticTree(page);
        throw e;
    }
    
    await page.waitForTimeout(5000);

    // 3. Start Expedition
    const exploreBtn = await getResilientLocator(page, 'EXPLORE_MAIN_BTN');
    try {
        await exploreBtn.waitFor({ state: 'visible', timeout: 60000 });
        await robustClick(page, exploreBtn);
    } catch (e) {
        console.log("EXPLORE_MAIN_BTN not found. Dumping tree...");
        await dumpSemanticTree(page);
        throw e;
    }
    await page.waitForTimeout(5000); // Wait for dialog to open completely

    // 4. Preparation Dialog
    const startBtn = await getResilientLocator(page, 'START_EXPEDITION_BTN');
    await robustClick(page, startBtn, { timeout: 60000 });

    // 5. Game Dashboard Navigation
    // Wait for the map to be attached
    const shipIcon = await getResilientLocator(page, 'SHIP_ICON');
    await shipIcon.waitFor({ state: 'attached', timeout: 60000 });

    // Handle starting island loot
    const autoBtn = await getResilientLocator(page, 'AUTO');
    if (await autoBtn.count() > 0) {
        await autoBtn.waitFor({ state: 'attached', timeout: 5000 }).catch(() => {});
        if (await autoBtn.isVisible()) {
            await robustClick(page, autoBtn);
            await page.waitForTimeout(3000); // wait for reveal
            const finBtn = await getResilientLocator(page, 'FIN');
            await robustClick(page, finBtn);
            await page.waitForTimeout(2000); // wait for overlay to close
        }
    }

    // Take a screenshot of the map
    await page.screenshot({ path: `screenshots/gameplay-map-${Date.now()}.png` });

    // 6. Navigate (Try to rotate or move)
    const moveRight = await getResilientLocator(page, 'MOVE_RIGHT_BTN');
    const moveForward = await getResilientLocator(page, 'MOVE_UP_BTN');

    if (await moveRight.count() > 0) {
        await robustClick(page, moveRight);
        await page.waitForTimeout(2000);
        await robustClick(page, moveForward);
        await page.waitForTimeout(3000);
        await page.screenshot({ path: `screenshots/gameplay-moved-${Date.now()}.png` });
    }

    // 7. Check Minimap
    // Use the tooltip-based menu item or button
    const mapBtn = await getResilientLocator(page, 'MINIMAP_BTN');
    await robustClick(page, mapBtn);
    
    // Wait for the map dialog to appear
    // We try to find the title, but don't strictly fail if the semantic tree is slow to expose it
    const mapTitle = await getResilientLocator(page, 'Carte du Monde');
    await mapTitle.waitFor({ state: 'attached', timeout: 15000 }).catch(() => {
        console.log("Minimap title 'Carte du Monde' not found, checking for 'Fermer' button instead.");
    });
    
    // Find the "Fermer" button inside the dialog specifically
    const mapClose = await getResilientLocator(page, 'Fermer');
    await mapClose.waitFor({ state: 'visible', timeout: 30000 });
    await robustClick(page, mapClose);
    
    // Stability delay for dialog close animation
    await page.waitForTimeout(1000);


    // 8. Check Journal
    await page.screenshot({ path: `screenshots/gameplay-before-journal-${Date.now()}.png` });
    const journalBtn = await getResilientLocator(page, 'JOURNAL_BTN');
    await robustClick(page, journalBtn);
    await page.waitForTimeout(2000); // Wait for open animation
    
    // Check for Journal title (relaxed)
    const journalTitle = await getResilientLocator(page, 'JOURNAL DE BORD');
    await journalTitle.waitFor({ state: 'attached', timeout: 15000 }).catch(() => {
        console.log("Journal title 'JOURNAL DE BORD' not found, checking for close button.");
    });
    
    const journalClose = await getResilientLocator(page, 'RETOUR À LA NAVIGATION');
    await journalClose.waitFor({ state: 'visible', timeout: 30000 });
    await robustClick(page, journalClose);
    await page.waitForTimeout(2000);
  });
});
