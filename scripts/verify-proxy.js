#!/usr/bin/env node

/**
 * Cloudflare Worker Proxy Verification Script
 * Tests connectivity to both direct Supabase and through proxy
 */

const https = require('https');
const url = require('url');

// Color codes for console output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function header(text) {
  console.log('\n' + '='.repeat(60));
  log(text, 'cyan');
  console.log('='.repeat(60) + '\n');
}

// Simple HTTPS request helper
function makeRequest(targetUrl, headers = {}) {
  return new Promise((resolve) => {
    const urlObj = new url.URL(targetUrl);
    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname + urlObj.search,
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...headers,
      },
      timeout: 10000,
    };

    const startTime = Date.now();

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        const duration = Date.now() - startTime;
        resolve({
          status: res.statusCode,
          headers: res.headers,
          body: data,
          duration,
          success: res.statusCode >= 200 && res.statusCode < 300,
        });
      });
    });

    req.on('error', (error) => {
      const duration = Date.now() - startTime;
      resolve({
        status: 0,
        error: error.message,
        duration,
        success: false,
      });
    });

    req.on('timeout', () => {
      req.destroy();
      resolve({
        status: 0,
        error: 'Request timeout',
        duration: Date.now() - startTime,
        success: false,
      });
    });

    req.end();
  });
}

async function testConnection(name, testUrl, anonKey) {
  log(`Testing ${name}...`, 'blue');
  
  const testApiUrl = `${testUrl}/rest/v1/users?limit=1`;
  
  try {
    const result = await makeRequest(testApiUrl, {
      apikey: anonKey,
    });

    if (result.success) {
      log(`✓ ${name}: SUCCESS`, 'green');
      log(`  Status: ${result.status}`);
      log(`  Duration: ${result.duration}ms`);
      try {
        const data = JSON.parse(result.body);
        log(`  Response: ${JSON.stringify(data).substring(0, 100)}...`);
      } catch (e) {
        log(`  Response: ${result.body.substring(0, 100)}...`);
      }
    } else {
      log(`✗ ${name}: FAILED`, 'red');
      log(`  Status: ${result.status}`);
      log(`  Error: ${result.error || 'Unknown error'}`);
      log(`  Duration: ${result.duration}ms`);
    }

    return result.success;
  } catch (error) {
    log(`✗ ${name}: ERROR`, 'red');
    log(`  ${error.message}`);
    return false;
  }
}

async function main() {
  // Get configuration from environment
  const supabaseUrl = process.env.SUPABASE_URL || 'https://vojwwcolmnbzogsrmwap.supabase.co';
  const proxyUrl = process.env.SUPABASE_PROXY_URL || '';
  const anonKey = process.env.SUPABASE_ANON_KEY || '';

  if (!anonKey) {
    log('Error: SUPABASE_ANON_KEY environment variable is required', 'red');
    process.exit(1);
  }

  header('Cloudflare Worker Proxy Verification');

  log('Configuration:', 'yellow');
  log(`  Direct URL: ${supabaseUrl}`);
  log(`  Proxy URL: ${proxyUrl || '(not configured)'}`);
  log(`  Anon Key: ${anonKey.substring(0, 20)}...`);

  let directSuccess = false;
  let proxySuccess = false;

  // Test direct connection
  header('Testing Direct Connection');
  directSuccess = await testConnection('Direct Supabase', supabaseUrl, anonKey);

  // Test proxy connection (if configured)
  if (proxyUrl) {
    header('Testing Proxy Connection');
    proxySuccess = await testConnection('Cloudflare Proxy', proxyUrl, anonKey);
  } else {
    log('Proxy URL not configured, skipping proxy test', 'yellow');
  }

  // Summary
  header('Test Summary');

  if (directSuccess) {
    log('✓ Direct connection: WORKING', 'green');
  } else {
    log('✗ Direct connection: FAILED', 'red');
  }

  if (proxyUrl) {
    if (proxySuccess) {
      log('✓ Proxy connection: WORKING', 'green');

      if (directSuccess && proxySuccess) {
        log(
          '\n✓ Both connections working! Use proxy for India region.',
          'green'
        );
      } else if (proxySuccess && !directSuccess) {
        log(
          '\n✓ Proxy is working! Use this for India region.',
          'green'
        );
      }
    } else {
      log('✗ Proxy connection: FAILED', 'red');

      if (directSuccess) {
        log(
          '\nℹ Direct connection works. Check proxy configuration.',
          'yellow'
        );
      }
    }
  }

  console.log('');
  process.exit(directSuccess || proxySuccess ? 0 : 1);
}

// Run the script
main().catch((error) => {
  log(`Fatal error: ${error.message}`, 'red');
  process.exit(1);
});
