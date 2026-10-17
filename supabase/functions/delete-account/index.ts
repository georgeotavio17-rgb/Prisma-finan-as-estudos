import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Método não permitido." }), { status: 405, headers: corsHeaders });

  try {
    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (!token || token === authHeader) return new Response(JSON.stringify({ error: "Sessão inválida." }), { status: 401, headers: corsHeaders });

    const url = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!url || !serviceKey) throw new Error("A função não está configurada no servidor.");

    const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: { user }, error: userError } = await admin.auth.getUser(token);
    if (userError || !user) return new Response(JSON.stringify({ error: "Não foi possível validar sua sessão." }), { status: 401, headers: corsHeaders });

    const body = await req.json().catch(() => ({}));
    if (String(body.emailConfirmation || "").trim().toLowerCase() !== String(user.email || "").toLowerCase()) {
      return new Response(JSON.stringify({ error: "O e-mail de confirmação não corresponde à conta conectada." }), { status: 400, headers: corsHeaders });
    }

    const bucket = admin.storage.from("prisma-avatars");
    const { data: files, error: listError } = await bucket.list(user.id, { limit: 100 });
    if (listError) throw listError;
    if (files?.length) {
      const { error: removeError } = await bucket.remove(files.map((file) => user.id + "/" + file.name));
      if (removeError) throw removeError;
    }

    const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
    if (deleteError) throw deleteError;
    return new Response(JSON.stringify({ success: true }), { status: 200, headers: corsHeaders });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : "Falha ao excluir a conta." }), { status: 500, headers: corsHeaders });
  }
});