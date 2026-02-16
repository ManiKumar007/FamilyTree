import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for MyFamilyTree E2E tests
 * 
 * Tests require:
 * 1. Backend running on http://localhost:3000
 * 2. Frontend running on http://localhost:5500
 */
export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : 1,
  reporter: 'html',
  timeout: 120000, // 2 minutes per test (Flutter web is slow on first load)
  
  use: {
    baseURL: 'http://localhost:5500',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    navigationTimeout: 60000, // 1 minute for navigation
    actionTimeout: 30000, // 30 seconds for actions
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
});
