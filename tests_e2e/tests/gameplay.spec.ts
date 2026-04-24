import { test, expect } from '@playwright/test';
import { getResilientLocator, robustClick, waitForAppLoaded } from './test_utils';

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
    const toggleBtn = getResilientLocator(page, 'AUTH_TOGGLE_BTN');
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
    const emailField = getResilientLocator(page, 'AUTH_EMAIL_FIELD');
    const passwordField = getResilientLocator(page, 'AUTH_PASSWORD_FIELD');
    const submitBtn = getResilientLocator(page, 'AUTH_SUBMIT_BTN');

    await robustClick(page, emailField);
    await page.keyboard.type(testEmail, { delay: 50 });
    
    // Fill password
    await robustClick(page, passwordField);
    await page.keyboard.type(testPassword, { delay: 50 });

    await page.waitForTimeout(1000);
    
    // Submit
    await robustClick(page, submitBtn);

    // 2. Wait for login to complete
    const profileBtn = getResilientLocator(page, 'PROFILE_BTN');
    await profileBtn.waitFor({ state: 'attached', timeout: 120000 });

    // 3. Start Expedition
    const exploreBtn = getResilientLocator(page, 'EXPLORE_MAIN_BTN');
    await robustClick(page, exploreBtn);
    await page.waitForTimeout(2000); // Wait for dialog to open

    // 4. Preparation Dialog
    const startBtn = getResilientLocator(page, 'START_EXPEDITION_BTN');
    await robustClick(page, startBtn, { timeout: 60000 });

    // 5. Game Dashboard Navigation
    // Wait for the map to be attached
    const shipIcon = getResilientLocator(page, 'SHIP_ICON');
    await shipIcon.waitFor({ state: 'attached', timeout: 60000 });

    // Take a screenshot of the map
    await page.screenshot({ path: `screenshots/gameplay-map-${Date.now()}.png` });

    // 6. Navigate (Try to rotate or move)
    const moveRight = getResilientLocator(page, 'MOVE_RIGHT_BTN');
    const moveForward = getResilientLocator(page, 'MOVE_UP_BTN');

    if (await moveRight.count() > 0) {
        await robustClick(page, moveRight);
        await page.waitForTimeout(2000);
        await robustClick(page, moveForward);
        await page.waitForTimeout(3000);
        await page.screenshot({ path: `screenshots/gameplay-moved-${Date.now()}.png` });
    }

    // 7. Check Minimap
    const mapBtn = getResilientLocator(page, 'MINIMAP_BTN');
    await robustClick(page, mapBtn);
    await page.waitForTimeout(1000);
    // Dialog should show "Carte du Monde" or "Fermer"
    const mapClose = getResilientLocator(page, 'Fermer');
    await mapClose.waitFor({ state: 'attached', timeout: 30000 });
    await robustClick(page, mapClose);
    await page.waitForTimeout(500);

    // 8. Check Journal
    await page.screenshot({ path: `screenshots/gameplay-before-journal-${Date.now()}.png` });
    const journalBtn = getResilientLocator(page, 'JOURNAL_BTN');
    await robustClick(page, journalBtn);
    await page.waitForTimeout(1000);
    // Casing match for "JOURNAL DE BORD"
    const journalTitle = getResilientLocator(page, 'JOURNAL DE BORD');
    await journalTitle.waitFor({ state: 'attached', timeout: 30000 });
    const journalClose = getResilientLocator(page, 'RETOUR À LA NAVIGATION');
    await journalClose.waitFor({ state: 'attached', timeout: 30000 });
    await robustClick(page, journalClose);
    await page.waitForTimeout(500);
  });
});
