# Phone Number Validation with Twilio

## Why SMS Validation?

### Current Problems:
1. **Fake Numbers** - Users can enter anyone's phone number
2. **Duplicate Profiles** - Same person with multiple unverified phones
3. **Spam/Abuse** - Bad actors can pollute the database
4. **Merge Conflicts** - Can't trust phone-based merge detection

### Benefits of SMS Validation:
- ✅ Verify user actually owns the phone number
- ✅ Prevent duplicate profiles for same phone
- ✅ Enable trusted merge suggestions
- ✅ Allow SMS invites to claimed profiles
- ✅ Build trust in the platform

---

## Implementation Options

### Option 1: Supabase Phone Auth (Recommended for Simplicity)

Supabase has **built-in phone authentication** using Twilio under the hood.

**Pros:**
- Already integrated with Supabase Auth
- No custom code needed
- Users log in with phone OTP
- Free tier: 10,000 MAUs

**Cons:**
- Users must use phone as primary auth (can't use email + phone)
- Less flexible than custom implementation

**Setup:**
1. Go to Supabase Dashboard → Authentication → Providers
2. Enable "Phone" provider
3. Connect your Twilio account (SID + Auth Token)
4. Configure SMS template

**Cost:** Twilio charges ~$0.0075/SMS in India

### Option 2: Custom Twilio Integration (Recommended for Flexibility)

Implement custom phone verification for **existing profiles**.

**Flow:**
1. User enters phone number
2. Backend sends OTP via Twilio
3. User enters OTP
4. Backend verifies OTP
5. Mark phone as `phone_verified: true`

**Advantages:**
- Users can use email/Google auth + add verified phone separately
- More control over UX
- Can validate phones for other family members too

---

## Recommended: Hybrid Approach

**Profile Owner:** Email/Google auth (social login)  
**Phone Verification:** Custom Twilio for profile completeness

### Implementation Steps:

#### 1. Create Phone Verification Table

```sql
-- Store OTP verification attempts
CREATE TABLE phone_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  person_id UUID REFERENCES persons(id),
  verified BOOLEAN DEFAULT false,
  expires_at TIMESTAMPTZ NOT NULL,
  attempts INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_phone_verifications_phone ON phone_verifications(phone, verified);
CREATE INDEX idx_phone_verifications_expires ON phone_verifications(expires_at);
```

#### 2. Install Twilio in Backend

```bash
cd backend
npm install twilio
```

#### 3. Add Twilio Config

```typescript
// backend/src/config/twilio.ts
import twilio from 'twilio';
import { env } from './env';

export const twilioClient = twilio(
  env.TWILIO_ACCOUNT_SID,
  env.TWILIO_AUTH_TOKEN
);

export const TWILIO_PHONE_NUMBER = env.TWILIO_PHONE_NUMBER;
```

#### 4. Create Verification Endpoints

```typescript
// backend/src/routes/phoneVerification.ts
import { Router } from 'express';
import { twilioClient, TWILIO_PHONE_NUMBER } from '../config/twilio';
import { supabaseAdmin } from '../config/supabase';
import crypto from 'crypto';

export const phoneVerificationRouter = Router();

// Send OTP
phoneVerificationRouter.post('/send-otp', async (req, res) => {
  const { phone } = req.body;
  
  // Generate 6-digit OTP
  const otp = crypto.randomInt(100000, 999999).toString();
  
  // Store in database (expires in 10 minutes)
  await supabaseAdmin.from('phone_verifications').insert({
    phone,
    otp_code: otp,
    user_id: req.userId,
    expires_at: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
  });
  
  // Send via Twilio
  await twilioClient.messages.create({
    body: `Your FamilyTree verification code is: ${otp}`,
    from: TWILIO_PHONE_NUMBER,
    to: phone,
  });
  
  res.json({ success: true, message: 'OTP sent' });
});

// Verify OTP
phoneVerificationRouter.post('/verify-otp', async (req, res) => {
  const { phone, otp } = req.body;
  
  const { data, error } = await supabaseAdmin
    .from('phone_verifications')
    .select('*')
    .eq('phone', phone)
    .eq('otp_code', otp)
    .eq('verified', false)
    .gt('expires_at', new Date().toISOString())
    .order('created_at', { ascending: false })
    .limit(1)
    .single();
  
  if (!data) {
    return res.status(400).json({ error: 'Invalid or expired OTP' });
  }
  
  // Mark as verified
  await supabaseAdmin
    .from('phone_verifications')
    .update({ verified: true })
    .eq('id', data.id);
  
  // Update person record
  await supabaseAdmin
    .from('persons')
    .update({ phone_verified: true })
    .eq('phone', phone)
    .eq('auth_user_id', req.userId);
  
  res.json({ success: true, message: 'Phone verified!' });
});
```

#### 5. Add phone_verified Column

```sql
ALTER TABLE persons ADD COLUMN phone_verified BOOLEAN DEFAULT false;
CREATE INDEX idx_persons_phone_verified ON persons(phone, phone_verified);
```

#### 6. Environment Variables

```bash
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+1234567890
```

---

## Cost Estimation

### Twilio Pricing (India):
- **SMS:** ₹0.60 per message (~$0.0075)
- **Phone Number:** ₹800/month (~$10/month)

### Monthly Cost Examples:
- **100 verifications/month:** ₹60 (~$1)
- **1,000 verifications/month:** ₹600 (~$8)
- **10,000 verifications/month:** ₹6,000 (~$80)

### Free Alternatives:
- **Supabase Phone Auth:** Free tier 10,000 MAUs
- **Firebase Auth:** Free (pay for Firebase hosting)
- **AWS SNS:** $0.00645/SMS (slightly cheaper)

---

## Recommended Rollout

### Phase 1: Optional Verification (Month 1-2)
- Add "Verify Phone" button (optional)
- Show badge for verified users
- Build trust gradually

### Phase 2: Verification Required (Month 3+)
- Require verification for:
  - Sending invites
  - Accepting merge requests
  - Editing others' profiles (as admin)
- Boost trust in platform

### Phase 3: SMS Invites (Month 6+)
- "Invite via SMS" feature
- Send invite link to unverified relatives
- Viral growth loop!

---

## Security Best Practices

1. **Rate Limiting**: Max 3 OTP requests per phone per hour
2. **Attempt Limits**: Max 5 verification attempts per OTP
3. **Expiry**: OTPs expire in 10 minutes
4. **One-Time Use**: Invalidate OTP after successful verification
5. **Logging**: Track all SMS sends for abuse monitoring

---

## Alternative: WhatsApp Verification (More Popular in India!)

**Why WhatsApp?**
- 500M+ users in India vs SMS
- Free API (Twilio WhatsApp Business)
- Higher engagement rates
- Richer messages (buttons, media)

**Twilio WhatsApp Setup:**
```typescript
await twilioClient.messages.create({
  body: `Your FamilyTree verification code is: ${otp}`,
  from: 'whatsapp:+14155238886', // Twilio WhatsApp sandbox
  to: `whatsapp:${phone}`,
});
```

**Production:** Need WhatsApp Business Account approval (~1 week process)

---

## Recommendation Summary

**Start with:** Custom Twilio SMS (most flexible)  
**Later add:** WhatsApp verification (higher engagement in India)  
**Cost:** ~₹600-6,000/month depending on scale ($8-80)  

Implement in 3 phases:
1. Optional verification (build trust)
2. Required for key actions (prevent abuse)
3. SMS/WhatsApp invites (viral growth)
