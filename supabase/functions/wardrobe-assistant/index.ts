import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS })
  }

  try {
    const { mode, prompt } = await req.json()
    if (!mode || !prompt) throw new Error("mode and prompt are required")
    if (mode !== "search" && mode !== "outfit") throw new Error("mode must be 'search' or 'outfit'")

    const authHeader = req.headers.get("Authorization")
    if (!authHeader) throw new Error("Missing Authorization header")

    // Forward the caller's JWT so RLS scopes this to their own items only.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: items, error } = await supabase
      .from("tw_items")
      .select("id, name, category, color_primary, color_secondary, pattern, season, formality, favorite")

    if (error) throw error
    if (!items || items.length === 0) {
      return new Response(JSON.stringify({ item_ids: [], reasoning: "Your wardrobe is empty — add some items first." }), {
        status: 200,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      })
    }

    const itemsList = items
      .map((it) => `- id:${it.id} | ${it.name} | category:${it.category} | color:${it.color_primary}${it.color_secondary ? "/" + it.color_secondary : ""} | pattern:${it.pattern} | season:${it.season} | formality:${it.formality}`)
      .join("\n")

    const systemPrompt = mode === "search"
      ? `You are a wardrobe search assistant. Given the user's clothing items and a search query, return ONLY a JSON object: {"item_ids": ["id1", "id2", ...]} containing the ids of items matching the query. No explanation.`
      : `You are a personal stylist. Given the user's clothing items and a request, suggest a coherent outfit (one item per relevant category — e.g. a top + bottom + shoes, or a dress + shoes) that matches on color/style/formality/season. Return ONLY a JSON object: {"item_ids": ["id1", "id2", ...], "reasoning": "one short sentence explaining the outfit choice"}.`

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${Deno.env.get("GROQ_API_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "llama-3.1-8b-instant",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: `Wardrobe items:\n${itemsList}\n\nRequest: ${prompt}` },
        ],
        max_tokens: 400,
        temperature: 0.4,
        response_format: { type: "json_object" },
      }),
    })

    const data = await response.json()
    if (!data.choices || data.choices.length === 0) {
      console.error("Groq error:", data)
      throw new Error(data.error?.message || "Groq failed to respond.")
    }

    const result = JSON.parse(data.choices[0].message.content)

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    })
  } catch (e) {
    console.error("Function Error:", e.message)
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    })
  }
})
