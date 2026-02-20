#!/usr/bin/env node
/**
 * MyFamilyTree - Test Data Seeder
 * Creates dummy users, forum posts, life events, and calendar events
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Missing Supabase credentials in .env file');
  console.error('Required: SUPABASE_URL and SUPABASE_SERVICE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

console.log('\n🌱 MyFamilyTree - Seed Test Data');
console.log('================================\n');

async function seedData() {
  try {
    // Get the first user (or you can specify a user ID)
    const { data: users } = await supabase.auth.admin.listUsers();
    if (!users || users.users.length === 0) {
      console.error('❌ No users found. Please create at least one user first.');
      process.exit(1);
    }
    const userId = users.users[0].id;
    console.log(`✓ Using user ID: ${userId}\n`);

    // 1. Create test persons
    console.log('📝 Creating test persons...');
    const { data: persons, error: personsError } = await supabase
      .from('persons')
      .insert([
        {
          name: 'Rajesh Kumar',
          date_of_birth: '1965-03-15',
          gender: 'male',
          phone: '+919876543210',
          email: 'rajesh.kumar@example.com',
          occupation: 'Retired Teacher',
          community: 'Brahmin',
          city: 'Bangalore',
          state: 'Karnataka',
          marital_status: 'married',
          nakshatra: 'Ashwini',
          rashi: 'Mesha',
          native_place: 'Mysore',
        },
        {
          name: 'Sunita Kumar',
          date_of_birth: '1968-07-22',
          gender: 'female',
          phone: '+919876543211',
          email: 'sunita.kumar@example.com',
          occupation: 'Homemaker',
          community: 'Brahmin',
          city: 'Bangalore',
          state: 'Karnataka',
          marital_status: 'married',
        },
        {
          name: 'Amit Kumar',
          date_of_birth: '1992-11-08',
          gender: 'male',
          phone: '+919876543212',
          email: 'amit.kumar@example.com',
          occupation: 'Software Engineer',
          community: 'Brahmin',
          city: 'Bangalore',
          state: 'Karnataka',
          marital_status: 'married',
          created_by_user_id: userId,
        },
        {
          name: 'Priya Sharma',
          date_of_birth: '1995-05-14',
          gender: 'female',
          phone: '+919876543213',
          email: 'priya.sharma@example.com',
          occupation: 'Doctor',
          community: 'Brahmin',
          city: 'Mumbai',
          state: 'Maharashtra',
          marital_status: 'married',
        },
        {
          name: 'Vishwanath Kumar',
          date_of_birth: '1935-01-10',
          gender: 'male',
          phone: '+919876543218',
          email: 'vishwanath@example.com',
          occupation: 'Retired Government Officer',
          community: 'Brahmin',
          city: 'Mysore',
          state: 'Karnataka',
          marital_status: 'widowed',
          is_alive: false,
          date_of_death: '2020-08-15',
          place_of_death: 'Mysore, Karnataka',
        },
      ])
      .select();

    if (personsError) throw personsError;
    console.log(`✓ Created ${persons.length} persons\n`);

    // 2. Create forum posts
    console.log('💬 Creating forum posts...');
    const { data: posts, error: postsError } = await supabase
      .from('forum_posts')
      .insert([
        {
          author_user_id: userId,
          post_type: 'story',
          title: 'Our Family\'s Journey from Mysore to Bangalore',
          content: 'It was 1985 when our family decided to move from Mysore to Bangalore. My grandfather had just retired...\\n\\nThe memories we made during those trips are priceless!',
          is_pinned: true,
        },
        {
          author_user_id: userId,
          post_type: 'recipe',
          title: 'Grandma\'s Special Bisi Bele Bath Recipe',
          content: '**Ingredients:**\\n- 1 cup rice\\n- 1/2 cup toor dal\\n- Mixed vegetables\\n\\nThis recipe has been passed down 3 generations!',
          likes_count: 12,
        },
        {
          author_user_id: userId,
          post_type: 'announcement',
          title: 'Annual Family Reunion - Save the Date!',
          content: '**Date:** December 25, 2026\\n**Time:** 10:00 AM\\n**Venue:** Kumar Family Home, Bangalore',
          likes_count: 8,
        },
        {
          author_user_id: userId,
          post_type: 'discussion',
          title: 'Planning a Trip to Our Ancestral Village',
          content: 'I\'m thinking of organizing a trip to Mysore for the younger generation. Would anyone be interested?',
          comments_count: 3,
        },
        {
          author_user_id: userId,
          post_type: 'memory',
          title: 'Remembering Grandfather Vishwanath',
          content: 'Today marks 6 years since we lost our beloved grandfather. His legacy lives on in all of us. 🙏',
        },
      ])
      .select();

    if (postsError) throw postsError;
    console.log(`✓ Created ${posts.length} forum posts\n`);

    // 3. Add comments
    if (posts && posts.length > 0) {
      console.log('💭 Adding comments...');
      const discussionPost = posts.find(p => p.post_type === 'discussion');
      if (discussionPost) {
        const { error: commentsError } = await supabase
          .from('forum_comments')
          .insert([
            {
              post_id: discussionPost.id,
              author_user_id: userId,
              content: 'Great idea! I would love to bring my kids along.',
            },
            {
              post_id: discussionPost.id,
              author_user_id: userId,
              content: 'Count me in! We should visit the old temple too.',
            },
          ]);
        if (!commentsError) console.log('✓ Added comments\n');
      }
    }

    // 4. Create life events
    console.log('🎯 Creating life events...');
    const rajesh = persons.find(p => p.name === 'Rajesh Kumar');
    if (rajesh) {
      const { error: eventsError } = await supabase
        .from('life_events')
        .insert([
          {
            person_id: rajesh.id,
            event_type: 'birth',
            title: 'Born in Mysore',
            description: 'Born near Chamundi Hills',
            event_date: '1965-03-15',
            event_place: 'Mysore, Karnataka',
            created_by_user_id: userId,
          },
          {
            person_id: rajesh.id,
            event_type: 'marriage',
            title: 'Married Sunita',
            description: 'Traditional wedding ceremony',
            event_date: '1990-11-25',
            event_place: 'Mysore, Karnataka',
            created_by_user_id: userId,
          },
          {
            person_id: rajesh.id,
            event_type: 'retirement',
            title: 'Retired from Teaching',
            description: 'After 35 years of service',
            event_date: '2020-06-30',
            event_place: 'Bangalore, Karnataka',
            created_by_user_id: userId,
          },
        ]);
      if (!eventsError) console.log('✓ Created life events\n');
    }

    // 5. Create calendar events
    console.log('📅 Creating calendar events...');
    const { data: calEvents, error: calError } = await supabase
      .from('calendar_events')
      .insert([
        {
          title: 'Annual Family Reunion',
          description: 'All family members gathering',
          event_date: '2026-12-25',
          event_time: '10:00:00',
          location: 'Kumar Family Home, Bangalore',
          event_type: 'gathering',
          created_by_user_id: userId,
        },
        {
          title: 'Deepavali Celebration',
          description: 'Festival of Lights',
          event_date: '2026-11-01',
          event_time: '18:00:00',
          location: 'Community Hall',
          event_type: 'festival',
          created_by_user_id: userId,
        },
        {
          title: 'Wedding Anniversary - Rajesh & Sunita',
          description: '36 years of togetherness',
          event_date: '2026-11-25',
          event_time: '19:00:00',
          location: 'Restaurant',
          event_type: 'anniversary',
          created_by_user_id: userId,
        },
      ])
      .select();

    if (calError) throw calError;
    console.log(`✓ Created ${calEvents?.length || 0} calendar events\n`);

    // 6. Create notifications
    console.log('🔔 Creating notifications...');
    const { error: notifError } = await supabase
      .from('notifications')
      .insert([
        {
          user_id: userId,
          notification_type: 'new_post',
          title: 'New Forum Post',
          message: 'Someone shared "Our Family\'s Journey"',
          related_entity_type: 'forum_post',
          is_read: false,
        },
        {
          user_id: userId,
          notification_type: 'event_reminder',
          title: 'Upcoming Event',
          message: 'Family Reunion is in 30 days',
          related_entity_type: 'calendar_event',
          is_read: false,
        },
      ]);
    if (!notifError) console.log('✓ Created notifications\n');

    // Summary
    console.log('========================================');
    console.log('✅ Test data seeded successfully!');
    console.log('========================================');
    console.log('Created:');
    console.log(`  • ${persons.length} test persons`);
    console.log(`  • ${posts.length} forum posts`);
    console.log(`  • ${calEvents?.length || 0} calendar events`);
    console.log(`  • Life events and notifications`);
    console.log('========================================\n');
    console.log('🎉 Refresh your application to see the test data!');

  } catch (error) {
    console.error('❌ Error seeding data:', error.message);
    if (error.details) console.error('Details:', error.details);
    if (error.hint) console.error('Hint:', error.hint);
    process.exit(1);
  }
}

seedData();
