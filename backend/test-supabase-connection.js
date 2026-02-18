// Simple test to check if we can connect to Supabase
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

console.log('Testing Supabase connection...');
console.log('URL:', SUPABASE_URL);
console.log('Service Role Key length:', SERVICE_ROLE_KEY?.length || 0);
console.log('Service Role Key preview:', SERVICE_ROLE_KEY?.substring(0, 30) + '...');

const supabaseAdmin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

console.log('\nSupabase client created successfully');
console.log('Attempting to get a user with an invalid token to test connection...');

// Test with an obviously invalid token to see if we get a connection error or auth error
supabaseAdmin.auth.getUser('invalid_token_for_testing')
  .then(result => {
    console.log('\nResult:', JSON.stringify(result, null, 2));
    if (result.error) {
      console.log('\nError message:', result.error.message);
      console.log('Error name:', result.error.name);
      console.log('Error status:', result.error.status);
      
      // Check if it's connection or auth error
      if (result.error.message.includes('fetch') || result.error.message.includes('network')) {
        console.log('\n❌ CONNECTION ERROR - Cannot reach Supabase');
      } else {
        console.log('\n✅ CONNECTION OK - Got expected auth error (not connection error)');
      }
    } else {
      console.log('\n✅ Unexpected success (invalid token should fail)');
    }
  })
  .catch(err => {
    console.error('\n❌ EXCEPTION:', err);
    console.error('Type:', typeof err);
    console.error('Message:', err.message);
    console.error('Stack:', err.stack);
  });
