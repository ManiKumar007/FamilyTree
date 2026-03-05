/**
 * Email service using SMTP (nodemailer).
 * Configure via environment variables:
 *   SMTP_HOST, SMTP_PORT, SMTP_SECURE, SMTP_USER, SMTP_PASS, SMTP_FROM
 *
 * For Supabase's SMTP settings (Auth > SMTP provider), copy the host/user/pass
 * values as Vercel env vars with the SMTP_ prefix.
 *
 * If SMTP vars are not set, all send calls are silently no-ops so the app
 * continues to work without email configured (falls back to in-app notifications).
 */

import * as nodemailer from 'nodemailer';

interface EmailOptions {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

function createTransporter(): nodemailer.Transporter | null {
  const host = process.env.SMTP_HOST;
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (!host || !user || !pass) {
    return null;
  }

  return nodemailer.createTransport({
    host,
    port: parseInt(process.env.SMTP_PORT || '587', 10),
    secure: process.env.SMTP_SECURE === 'true',
    auth: { user, pass },
  });
}

export async function sendEmail(options: EmailOptions): Promise<void> {
  const transporter = createTransporter();
  if (!transporter) {
    console.warn('[EmailService] SMTP not configured — skipping email send');
    return;
  }

  const from = process.env.SMTP_FROM || process.env.SMTP_USER;

  await transporter.sendMail({
    from: `"Vansh Family Tree" <${from}>`,
    to: options.to,
    subject: options.subject,
    html: options.html,
    text: options.text,
  });
}

// ---------------------------------------------------------------------------
// Email templates
// ---------------------------------------------------------------------------

export async function sendClaimApprovalRequest({
  to,
  claimantName,
  personName,
  approveUrl,
  rejectUrl,
  expiresAt,
}: {
  to: string;
  claimantName: string;
  personName: string;
  approveUrl: string;
  rejectUrl: string;
  expiresAt: Date;
}): Promise<void> {
  const expiresStr = expiresAt.toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });

  const html = `
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; background: #f9f7f4; padding: 20px;">
  <div style="max-width: 520px; margin: 0 auto; background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
    
    <!-- Header -->
    <div style="background: linear-gradient(135deg, #7C3AED, #A78BFA); padding: 28px 32px; text-align: center;">
      <h1 style="color: white; margin: 0; font-size: 22px;">🌳 Vansh Family Tree</h1>
      <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0; font-size: 14px;">Profile Claim Request</p>
    </div>

    <!-- Body -->
    <div style="padding: 28px 32px;">
      <p style="color: #374151; font-size: 16px; margin-top: 0;">Hello,</p>

      <p style="color: #374151; font-size: 15px; line-height: 1.6;">
        <strong>${claimantName}</strong> is requesting to claim the profile of
        <strong>${personName}</strong> in your family tree.
      </p>

      <p style="color: #6B7280; font-size: 14px; line-height: 1.6;">
        If you recognise this person, please approve the request so they can
        join your family tree. If you don't recognise them, please reject it.
        <br><br>
        This request will <strong>auto-approve on ${expiresStr}</strong> if you
        take no action.
      </p>

      <!-- Action buttons -->
      <div style="margin: 28px 0; text-align: center;">
        <a href="${approveUrl}"
           style="display: inline-block; padding: 13px 28px; background: #059669; color: white;
                  text-decoration: none; border-radius: 8px; font-size: 15px; font-weight: 600;
                  margin-right: 12px;">
          ✅ Approve
        </a>
        <a href="${rejectUrl}"
           style="display: inline-block; padding: 13px 28px; background: #DC2626; color: white;
                  text-decoration: none; border-radius: 8px; font-size: 15px; font-weight: 600;">
          ❌ Reject
        </a>
      </div>

      <p style="color: #9CA3AF; font-size: 12px; line-height: 1.5; border-top: 1px solid #F3F4F6; padding-top: 16px; margin-bottom: 0;">
        These links expire on ${expiresStr}. After that the request is automatically
        approved. If you have questions, open the app and check the Notifications tab.
      </p>
    </div>
  </div>
</body>
</html>`;

  await sendEmail({
    to,
    subject: `[Action Required] ${claimantName} wants to claim ${personName}'s profile`,
    html,
    text: `${claimantName} wants to claim ${personName}'s profile in your family tree.\n\nApprove: ${approveUrl}\nReject: ${rejectUrl}\n\nThis auto-approves on ${expiresStr}.`,
  });
}

export async function sendClaimOutcomeEmail({
  to,
  personName,
  approved,
  frontendUrl,
}: {
  to: string;
  personName: string;
  approved: boolean;
  frontendUrl: string;
}): Promise<void> {
  if (!to) return;

  const subject = approved
    ? `Your claim for ${personName}'s profile was approved 🎉`
    : `Your claim for ${personName}'s profile was rejected`;

  const html = `
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; background: #f9f7f4; padding: 20px;">
  <div style="max-width: 520px; margin: 0 auto; background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
    <div style="background: linear-gradient(135deg, #7C3AED, #A78BFA); padding: 28px 32px; text-align: center;">
      <h1 style="color: white; margin: 0; font-size: 22px;">🌳 Vansh Family Tree</h1>
    </div>
    <div style="padding: 28px 32px;">
      ${approved ? `
        <p style="color: #374151; font-size: 16px;">
          Great news! The family tree owner has <strong style="color:#059669">approved</strong>
          your claim for <strong>${personName}</strong>'s profile.
        </p>
        <p style="color: #6B7280; font-size: 14px;">
          Open the app to see your family tree.
        </p>
        <div style="text-align: center; margin: 24px 0;">
          <a href="${frontendUrl}/tree"
             style="display: inline-block; padding: 13px 28px; background: #7C3AED; color: white;
                    text-decoration: none; border-radius: 8px; font-size: 15px; font-weight: 600;">
            Open My Tree
          </a>
        </div>
      ` : `
        <p style="color: #374151; font-size: 16px;">
          Unfortunately the family tree owner has <strong style="color:#DC2626">rejected</strong>
          your claim for <strong>${personName}</strong>'s profile.
        </p>
        <p style="color: #6B7280; font-size: 14px;">
          You can still create a fresh profile in the app if you haven't already.
        </p>
        <div style="text-align: center; margin: 24px 0;">
          <a href="${frontendUrl}/profile-setup"
             style="display: inline-block; padding: 13px 28px; background: #7C3AED; color: white;
                    text-decoration: none; border-radius: 8px; font-size: 15px; font-weight: 600;">
            Create New Profile
          </a>
        </div>
      `}
    </div>
  </div>
</body>
</html>`;

  await sendEmail({ to, subject, html });
}
