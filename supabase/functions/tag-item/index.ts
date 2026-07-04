import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS })
  }

  try {
    const { image_url } = await req.json()
    if (!image_url) throw new Error("image_url is required")

    const prompt = `You are a wardrobe cataloging assistant. Look at this photo of a single clothing item and return ONLY a JSON object (no markdown, no explanation) with these exact fields:
{
  "name": "short descriptive name, e.g. 'Blue Denim Jacket'",
  "category": "one of: top, bottom, dress, outerwear, shoes, accessory, bag",
  "color_primary": "main color, plain English, e.g. 'navy blue'",
  "color_secondary": "secondary color if any, else null",
  "pattern": "one of: solid, striped, plaid, floral, graphic, textured, other",
  "season": "one of: spring, summer, fall, winter, all-season",
  "formality": "one of: casual, business-casual, formal, athletic"
}`

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${Deno.env.get("GROQ_API_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "meta-llama/llama-4-scout-17b-16e-instruct",
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: prompt },
              { type: "image_url", image_url: { url: image_url } },
            ],
          },
        ],
        max_tokens: 300,
        temperature: 0.2,
        response_format: { type: "json_object" },
      }),
    })

    const data = await response.json()
    if (!data.choices || data.choices.length === 0) {
      console.error("Groq error:", data)
      throw new Error(data.error?.message || "Groq failed to tag the item.")
    }

    const tags = JSON.parse(data.choices[0].message.content)

    return new Response(JSON.stringify({ tags }), {
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
