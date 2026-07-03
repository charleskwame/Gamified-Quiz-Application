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

    const formattedMessages = [
      ...(systemPrompt ? [{ role: 'system', content: systemPrompt }] : []),
      ...(messages || []),
    ]

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

    // 6. If streaming, forward the SSE stream back to the client
    if (stream === true && response.body) {
      // Use a TransformStream to pass through SSE data chunks
      const { readable, writable } = new TransformStream()
      const writer = writable.getWriter()
      const reader = response.body.getReader()
      const decoder = new TextDecoder()
      const encoder = new TextEncoder()

      // Pump chunks in the background
      const pump = async () => {
        try {
          while (true) {
            const { done, value } = await reader.read()
            if (done) {
              await writer.write(encoder.encode('data: [DONE]\n\n'))
              await writer.close()
              break
            }
            const text = decoder.decode(value, { stream: true })
            await writer.write(encoder.encode(text))
          }
        } catch (e) {
          console.error('Stream pump error:', e)
          await writer.abort(e)
        }
      }
      pump()

      return new Response(readable, {
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
    const message = error instanceof Error ? error.message : 'Unknown error';
    return new Response(JSON.stringify({ error: message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})