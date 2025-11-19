import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Resend } from "npm:resend@2.0.0";

const resend = new Resend(Deno.env.get("RESEND_API_KEY"));
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

    const appUrl = "https://toothfile.com/";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { inviterName, inviterEmail, inviterRole, recipientEmail, personalMessage } = await req.json();

    // ✅ Create invited user
    const { data, error } = await supabase.auth.admin.inviteUserByEmail(recipientEmail, {
      data: { role: inviterRole },
    });

    if (error) throw error;

    // ✅ Custom HTML email
    await resend.emails.send({
      from: "ToothFile <onboarding@resend.dev>",
      to: [recipientEmail],
      subject: `${inviterName} invited you to ToothFile`,
      html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Join ${inviterName} on ToothFile</title>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #2563eb, #1d4ed8); color: white; padding: 30px 20px; text-align: center; border-radius: 8px 8px 0 0; }
          .logo { font-size: 28px; font-weight: bold; margin-bottom: 10px; }
          .content { padding: 30px 20px; background: #ffffff; border: 1px solid #e5e7eb; }
          .highlight { background: #f8fafc; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #2563eb; }
          .features { background: #f9fafb; padding: 20px; border-radius: 8px; margin: 20px 0; }
          .feature-item { margin: 15px 0; padding-left: 20px; position: relative; }
          .feature-item::before { content: "✓"; position: absolute; left: 0; color: #059669; font-weight: bold; }
          .cta-button { display: inline-block; padding: 15px 30px; background: #2563eb; color: white; text-decoration: none; border-radius: 8px; font-weight: 600; margin: 20px 0; }
          .footer { padding: 20px; text-align: center; font-size: 14px; color: #6b7280; background: #f9fafb; border-radius: 0 0 8px 8px; }
          .personal-message { background: #fef3c7; border: 1px solid #f59e0b; padding: 15px; border-radius: 6px; margin: 20px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="logo">🦷 ToothFile</div>
            <p style="margin: 0; font-size: 18px;">Secure Dental Collaboration Platform</p>
          </div>
          
          <div class="content">
            <h2 style="color: #1f2937; margin-top: 0;">You're Invited to Join ToothFile!</h2>
            
            <p>Hello!</p>
            
            <p><strong>${inviterName}</strong> has invited you to join ToothFile, a secure platform designed specifically for dental professionals to share files safely.</p>
            
            ${personalMessage ? `
              <div class="personal-message">
                <strong>Personal message from ${inviterName}:</strong><br>
                "${personalMessage}"
              </div>
            ` : ''}
            
            <div class="highlight">
              <h3 style="margin-top: 0; color: #2563eb;">What is ToothFile?</h3>
              <p>ToothFile is a specialized platform that enables secure file sharing between dentists and dental technicians. Share patient files and dental scans while maintaining the highest security standards.</p>
            </div>
            
            <div class="features">
              <h3 style="margin-top: 0; color: #1f2937;">What you can do with ToothFile:</h3>
              <div class="feature-item">Securely share dental files</div>
              <div class="feature-item">Collaborate in real-time with dental professionals</div>
              <div class="feature-item">Track file delivery and access with detailed notifications</div>
              <div class="feature-item">Connect with dentists and dental technicians</div>
              <div class="feature-item">Maintain patient privacy with security</div>
              <div class="feature-item">Access to ToothFile from any device, anywhere</div>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="${appUrl}" class="cta-button">Join ToothFile Now</a>
            </div>
            
            <p style="color: #6b7280; font-size: 14px;">
              Getting started is easy! Click the button above to create your free account and start collaborating with ${inviterName} and other dental professionals securely.
            </p>
            
            <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;">
            
            <p style="font-size: 14px; color: #6b7280;">
              This invitation was sent by <strong>${inviterName}</strong> (${inviterEmail}) who is already using ToothFile to streamline their dental workflow.
            </p>
          </div>
          
          <div class="footer">
            <p style="margin: 0;">
              <strong>ToothFile</strong> - Secure Dental Collaboration<br>
              Connecting dentists and dental technicians
            </p>
            <p style="margin: 10px 0 0 0; font-size: 12px;">
              If you have any questions, feel free to reply to this email.
            </p>
          </div>
        </div>
      </body>
      </html>
      `
    });

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err) {
    // Handle unknown error type
    const errorMessage = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
