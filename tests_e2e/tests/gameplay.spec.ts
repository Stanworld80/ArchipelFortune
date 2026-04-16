import { test, expect } from '@playwright/test';
import { getResilientLocator, clickCoordinate } from './test_utils';

test.describe('Archipel Fortune Gameplay Loop', () => {
  test.setTimeout(240000); // Gameplay takes time

  const testEmail = `player_${Math.floor(Math.random() * 10000)}@test.com`;
  const testPassword = 'Password123!';

  test.beforeEach(async ({ page }) => {
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flutter-view', { timeout: 30000 });

    // activation de l'accessibilité
    await page.evaluate(() => {
        const findAndClick = () => {
            const btns = Array.from(document.querySelectorAll('flt-semantics-placeholder, [aria-label="Enable accessibility"]'));
            const accessBtn = btns.find(el => el.getAttribute('aria-label') === 'Enable accessibility' || el.textContent?.includes('accessibility'));
            if (accessBtn instanceof HTMLElement) {
                accessBtn.click();
                return true;
            }
            return false;
        };
        if (!findAndClick()) {
            window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));
            setTimeout(findAndClick, 1000);
        }
    });

    await page.waitForTimeout(3000);
  });

  test('Full Journey: Register -> Prepare -> Navigate', async ({ page }) => {
    // 1. Ensure we are in registration mode
    const toggleBtn = getResilientLocator(page, 'AUTH_TOGGLE_BTN');
    await toggleBtn.waitFor({ state: 'attached', timeout: 30000 });
    const toggleText = await toggleBtn.innerText().catch(() => '');
    
    // We want registration mode.
    // "CRÉER UN PROFIL" usually means we are in Login mode and can switch to Register.
    if (toggleText.includes('CRÉER UN PROFIL') || toggleText.includes('RECRUE')) {
      await clickCoordinate(page, toggleBtn);
      await page.waitForTimeout(1000);
    }

    const emailField = getResilientLocator(page, 'AUTH_EMAIL_FIELD');
    const passwordField = getResilientLocator(page, 'AUTH_PASSWORD_FIELD');
    const submitBtn = getResilientLocator(page, 'AUTH_SUBMIT_BTN');

    await clickCoordinate(page, emailField);
    await page.keyboard.type(testEmail, { delay: 50 });
    
    await clickCoordinate(page, passwordField);
    await page.keyboard.type(testPassword, { delay: 50 });
    
    await page.waitForTimeout(1000);
    await clickCoordinate(page, submitBtn);

    // 2. Wait for login to complete
    const profileBtn = getResilientLocator(page, 'PROFILE_BTN');
    await profileBtn.waitFor({ state: 'attached', timeout: 120000 });

    // 3. Start Expedition
    const exploreBtn = getResilientLocator(page, 'EXPLORE_MAIN_BTN');
    await clickCoordinate(page, exploreBtn);

    // 4. Preparation Dialog
    const startBtn = getResilientLocator(page, 'START_EXPEDITION_BTN');
    await clickCoordinate(page, startBtn, { timeout: 20000 });

    // 5. Game Dashboard Navigation
    // Wait for the map to be attached
    const shipIcon = getResilientLocator(page, 'SHIP_ICON');
    await shipIcon.waitFor({ state: 'attached', timeout: 60000 });

    // Take a screenshot of the map
    await page.screenshot({ path: `screenshots/gameplay-map-${Date.now()}.png` });

    // 6. Navigate (Try to rotate or move)
    const rotateRight = getResilientLocator(page, 'ROTATE_RIGHT_BTN');
    const moveForward = getResilientLocator(page, 'MOVE_FORWARD_BTN');

    if (await rotateRight.count() > 0) {
        await clickCoordinate(page, rotateRight);
        await page.waitForTimeout(2000);
        await clickCoordinate(page, moveForward);
        await page.waitForTimeout(3000);
        await page.screenshot({ path: `screenshots/gameplay-moved-${Date.now()}.png` });
    }
  });
});
