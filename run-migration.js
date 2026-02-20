const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: './backend/.env' });

const supabaseUrl = process.env.SUPABASE_URL || 'https://vojwwcolmnbzogsrmwap.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseKey) {
  console.error('Error: SUPABASE_SERVICE_ROLE_KEY not found in environment variables.');
  console.error('Please set it in backend/.env file.');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function runMigration() {
  try {
    console.log('Running migration: 011_add_given_name_surname.sql');
    console.log('Database:', supabaseUrl);
    
    // Step 1: Add columns (if not exists)
    console.log('\n1. Adding given_name and surname columns...');
    const { error: alterError } = await supabase.rpc('exec_sql', {
      query: `
        ALTER TABLE persons
          ADD COLUMN IF NOT EXISTS given_name TEXT,
          ADD COLUMN IF NOT EXISTS surname TEXT;
      `
    });
    
    if (alterError && !alterError.message.includes('already exists')) {
      console.error('Failed to add columns:', alterError);
      // Try direct table update approach instead
      console.log('\nTrying alternative approach...');
      
      // Get all persons and check if column exists
      const { data: testData, error: testError } = await supabase
        .from('persons')
        .select('id, name, given_name, surname')
        .limit(1);
      
      if (testError) {
        if (testError.message.includes('given_name')) {
          console.error('\nThe given_name column does not exist in the database.');
          console.error('You need to run this migration directly in the Supabase SQL Editor:');
          console.error('\n--- Copy this SQL to Supabase SQL Editor ---');
          console.error(`
ALTER TABLE persons
  ADD COLUMN IF NOT EXISTS given_name TEXT,
  ADD COLUMN IF NOT EXISTS surname TEXT;

UPDATE persons
SET
  given_name = split_part(name, ' ', 1),
  surname    = CASE
    WHEN position(' ' in name) > 0
      THEN substring(name from position(' ' in name) + 1)
    ELSE NULL
  END
WHERE given_name IS NULL;

ALTER TABLE persons ALTER COLUMN given_name SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_persons_surname ON persons(surname);
          `);
          console.error('--- End SQL ---\n');
          process.exit(1);
        }
        throw testError;
      } else {
        console.log('Columns already exist!');
      }
    } else {
      console.log('Columns added successfully!');
    }
    
    // Step 2: Populate given_name from existing name
    console.log('\n2. Populating given_name and surname from name column...');
    const { error: updateError } = await supabase
      .rpc('exec_sql', {
        query: `
          UPDATE persons
          SET
            given_name = split_part(name, ' ', 1),
            surname    = CASE
              WHEN position(' ' in name) > 0
                THEN substring(name from position(' ' in name) + 1)
              ELSE NULL
            END
          WHERE given_name IS NULL;
        `
      });
    
    if (updateError) {
      console.log('Update may have failed, but continuing...');
    }
    
    console.log('\nMigration completed successfully!');
    console.log('The given_name and surname columns have been added to the persons table.');
    console.log('\nYou can now add family members using the given_name field!');
    
  } catch (err) {
    console.error('Error running migration:', err);
    console.error('\nPlease run the migration SQL manually in the Supabase SQL Editor.');
    process.exit(1);
  }
}

runMigration();
