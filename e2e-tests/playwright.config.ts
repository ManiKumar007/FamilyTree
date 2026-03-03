import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for MyFamilyTree E2E tests
 *
 * Environment modes:
 *   Local (default):  npm test
 *   Production:       TEST_ENV=production npm test
 *
 * Local mode requires:
 *   1. Backend running on http://localhost:3000
 *   2. Frontend running on http://localhost:5500
 *
 * Production mode tests against live Vercel deployments.
 * Override URLs with FRONTEND_URL and API_BASE_URL env vars.
 */
const isProduction = process.env.TEST_ENV === 'production';

const FRONTEND_URL = process.env.FRONTEND_URL
  || (isProduction ? 'https://familytree-web.vercel.app' : 'http://localhost:5500');

const API_BASE_URL = process.env.API_BASE_URL
  || (isProduction ? 'https://backend-five-blue-16.vercel.app' : 'http://localhost:3000');

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : (isProduction ? 1 : 0),
  workers: 1,
  reporter: 'html',
  timeout: isProduction ? 180000 : 120000, // production may be slower (cold starts)

  use: {
    baseURL: FRONTEND_URL,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    navigationTimeout: isProduction ? 90000 : 60000,
    actionTimeout: isProduction ? 45000 : 30000,
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },

    // Uncomment to test on other browsers
    // {
    //   name: 'firefox',
    //   use: { ...devices['Desktop Firefox'] },
    // },
    // {
    //   name: 'webkit',
    //   use: { ...devices['Desktop Safari'] },
    // },
  ],

  // Only start local servers when NOT running against production
  ...(!isProduction && {
    webServer: [
      {
        command: 'cd .. && .\\start-backend.ps1',
        url: 'http://localhost:3000/api/health',
        reuseExistingServer: !process.env.CI,
        timeout: 30000,
      },
      {
        command: 'cd .. && powershell -Command "cd app; flutter run -d web-server --web-port=5500 --web-renderer html"',
        url: 'http://localhost:5500',
        reuseExistingServer: !process.env.CI,
        timeout: 120000,
      },
    ],
  }),
});

// Export for use in test files
export { isProduction, FRONTEND_URL, API_BASE_URL };
