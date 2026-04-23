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
    // "CRÉER UN PROFIL" usually means we are in Login mode and can switch to Register.
    if (toggleText.includes('CRÉER UN PROFIL') || toggleText.includes('RECRUE')) {
      await robustClick(page, toggleBtn);
      await page.waitForTimeout(1000);
    }

    // If we want to LOGIN, but the toggle says "DÉJÀ MEMBRE ? SE CONNECTER",
    // it means we are currently in REGISTER mode. Click to switch.
    if (toggleText.includes('DÉJÀ MEMBRE') || toggleText.includes('CONNECTER')) {
        await robustClick(page, toggleBtn);
        await page.waitForTimeout(1000);
    }

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
    const mapClose = page.locator('text=Fermer');
    await expect(mapClose).toBeVisible();
    await robustClick(page, mapClose);
    await page.waitForTimeout(500);

    // 8. Check Journal
    const journalBtn = getResilientLocator(page, 'JOURNAL_BTN');
    await robustClick(page, journalBtn);
    await page.waitForTimeout(1000);
    const journalTitle = page.locator('text=Journal de Bord');
    await expect(journalTitle).toBeVisible();
    const journalClose = page.locator('text=Fermer');
    await robustClick(page, journalClose);
    await page.waitForTimeout(500);
  });
});
