// supabase/functions/delete-account/index.ts

import { serve } from "https://deno.land/std@0.131.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const { userId } = await req.json();

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { error } = await supabaseAdmin.auth.admin.deleteUser(userId);

    if (error) throw error;

    return new Response("User deleted ✅", { status: 200 });
  } catch (error) {
    return new Response(JSON.stringify(error), { status: 500 });
  }
});
