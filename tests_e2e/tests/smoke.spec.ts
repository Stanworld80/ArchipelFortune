import { test, expect } from '@playwright/test';
import { waitForAppLoaded, getResilientLocator } from './test_utils';

test.describe('Archipel Fortune Smoke Tests', () => {
  test.setTimeout(90000);

  test.beforeEach(async ({ page }) => {
    await page.goto('/', { waitUntil: 'load', timeout: 60000 });
    await waitForAppLoaded(page);
  });

  test('Page Title Verification', async ({ page }) => {
    await expect(page).toHaveTitle(/Archipel de la Fortune/i);
  });

  test('Authentication UI Presence', async ({ page }) => {
    const emailField = getResilientLocator(page, 'AUTH_EMAIL_FIELD');
    const passwordField = getResilientLocator(page, 'AUTH_PASSWORD_FIELD');
    const submitBtn = getResilientLocator(page, 'AUTH_SUBMIT_BTN');
    const toggleBtn = getResilientLocator(page, 'AUTH_TOGGLE_BTN');

    await expect(emailField).toBeVisible({ timeout: 20000 });
    await expect(passwordField).toBeVisible();
    await expect(submitBtn).toBeVisible();
    await expect(toggleBtn).toBeVisible();
  });

  test('Form Interaction', async ({ page }) => {
    const emailField = getResilientLocator(page, 'AUTH_EMAIL_FIELD');
    await expect(emailField).toBeVisible({ timeout: 20000 });
    await emailField.click({ force: true });
    await emailField.fill('test@example.com');
    
    // On vérifie que le champ est éditable
    await expect(emailField).toBeEnabled();
  });
});
