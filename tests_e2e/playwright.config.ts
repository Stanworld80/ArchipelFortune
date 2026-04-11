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
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [['html', { open: 'never' }], ['list']],
  use: {
    baseURL: BASE_URL,
    trace: 'on-first-retry',
    viewport: { width: 1280, height: 720 },
    // Active automatiquement l'accessibilité Flutter Web (nécessaire avec CanvasKit)
    // en simulant une pression Tab au démarrage de chaque page
    actionTimeout: 30000,
    navigationTimeout: 60000,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
