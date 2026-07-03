// 1. Define CORS headers directly inline so we don't need external files
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // 2. Handle CORS pre-flight requests from Flutter (Web/Mobile)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 3. Get the DeepSeek API Key from Supabase's secure environment
    const DEEPSEEK_API_KEY = Deno.env.get('DEEPSEEK_API_KEY')
    if (!DEEPSEEK_API_KEY) {
      throw new Error('Missing DEEPSEEK_API_KEY environment variable')
    }

    // 4. Parse the body incoming from your Flutter App
    const body = await req.json()
    const { systemPrompt, messages, stream } = body

    let formattedMessages = [
      ...(systemPrompt ? [{ role: 'system', content: systemPrompt }] : []),
      ...(messages || []),
    ]

    // If no user/assistant messages provided, add a default user message
    // so DeepSeek has something to respond to
    if (formattedMessages.length <= 1 && messages && messages.length === 0) {
      formattedMessages.push({
        role: 'user',
        content: systemPrompt || 'Hello, please respond with study tips.',
      })
    }

    // 5. Make the secure server-to-server call to DeepSeek
    const response = await fetch('https://api.deepseek.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${DEEPSEEK_API_KEY}`,
      },
      body: JSON.stringify({
        model: 'deepseek-chat',
        stream: stream === true,
        messages: formattedMessages,
      }),
    })

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(`DeepSeek API error (${response.status}): ${errorText}`)
    }

    // 6. If streaming, pass the SSE body directly through to the client
    if (stream === true && response.body) {
      return new Response(response.body, {
        headers: {
          ...corsHeaders,
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
        status: 200,
      })
    }

    // 7. Non-streaming: return the full JSON response
    const data = await response.json()
    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error'
    return new Response(JSON.stringify({ error: message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})