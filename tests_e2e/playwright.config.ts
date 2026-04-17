import { defineConfig, devices } from '@playwright/test';

/**
 * Base URL résolu via la variable d'environnement PLAYWRIGHT_BASE_URL.
 * Permet d'exécuter les tests contre dev, staging, ou une instance locale.
 *
 * Usage :
 *   PLAYWRIGHT_BASE_URL=https://archipel-fortune-staging.web.app npx playwright test
 *   (ou via build_deploy.sh --e2e / build_deploy.ps1 -RunE2E)
 */
const BASE_URL = process.env.PLAYWRIGHT_BASE_URL ?? 'https://archipel-fortune-dev.web.app';

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  // CI runners are slow; use 1 worker to ensure reliability and avoid Firebase Auth concurrency limits
  workers: process.env.CI ? 1 : 1, 
  reporter: [['html', { open: 'never' }], ['list']],
  use: {
    baseURL: BASE_URL,
    trace: 'on-first-retry',
    viewport: { width: 1280, height: 720 },
    // Aumented timeouts for slow CI runners
    actionTimeout: 60000,
    navigationTimeout: 120000,
  },
  projects: [
    {
      name: 'chromium',
      use: { 
        ...devices['Desktop Chrome'],
        // Hardware acceleration can be buggy in headless CI
        launchOptions: {
          args: ['--disable-web-security', '--disable-gpu', '--enable-software-rendering']
        }
      },
    },
  ],
});
