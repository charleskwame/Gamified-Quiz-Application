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

    // Build the messages array for DeepSeek
    let formattedMessages = [
      ...(systemPrompt ? [{ role: 'system', content: systemPrompt }] : []),
      ...(messages || []),
    ]

    // If no user/assistant messages provided (only system prompt exists),
    // add a default user message so DeepSeek has something to respond to
    if (formattedMessages.length === 0) {
      formattedMessages.push({
        role: 'user',
        content: 'Hello, please provide study tips.',
      })
    } else if (formattedMessages.length === 1 && formattedMessages[0].role === 'system') {
      // Only a system prompt exists; add a default user message
      formattedMessages.push({
        role: 'user',
        content: 'Please provide study tips based on my quiz results.',
      })
    }

    // 5. Make the secure server-to-server call to DeepSeek
    const deepseekResponse = await fetch('https://api.deepseek.com/v1/chat/completions', {
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

    // Read the response content-type from DeepSeek
    const deepseekContentType = deepseekResponse.headers.get('content-type') || ''

    // If DeepSeek returns an error status OR returns JSON (error body even with 200), handle it
    if (!deepseekResponse.ok || deepseekContentType.includes('application/json')) {
      const errorBody = await deepseekResponse.text()
      throw new Error(
        `DeepSeek API error (${deepseekResponse.status}): ${errorBody || 'no body'}`,
      )
    }

    // 6. If streaming, pass the SSE body directly through to the client
    if (stream === true && deepseekResponse.body) {
      return new Response(deepseekResponse.body, {
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
    // Note: If we reach here with stream=true but no response.body, return error
    if (stream === true) {
      throw new Error('Streaming requested but response body is empty from DeepSeek')
    }

    const data = await deepseekResponse.json()
    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error'
    // Return 400 for client errors, 500 for server errors
    const status = message.includes('DeepSeek API error') ? 502 : 400
    return new Response(JSON.stringify({ error: message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status,
    })
  }
})
