#import "../assets/template.typ": *

#tool-sheet("OpenRouter")[
  == Core Commands
  #commands-table((
    ([`POST /api/v1/chat/completions`], [Create a chat completion with OpenAI-compatible messages]),
    ([`Authorization: Bearer $OPENROUTER_API_KEY`], [Required auth header for API requests]),
    ([`Content-Type: application/json`], [Send JSON request bodies]),
    ([`HTTP-Referer: <YOUR_SITE_URL>`], [Optional app attribution / leaderboard header]),
    ([`X-OpenRouter-Title: <YOUR_SITE_NAME>`], [Optional app title attribution header]),
    ([`model: "~openai/gpt-latest"`], [Latest-alias example that resolves to the newest OpenAI flagship model]),
    ([`messages: [{ role: "user", content: "..." }]`], [Minimum chat request payload shape]),
    ([`stream: true`], [Enable streaming response mode]),
    ([`GET /api/v1/models`], [List model slugs programmatically]),
    ([`npm install @openrouter/sdk`], [Install the typed TypeScript client SDK]),
    ([`pip install openrouter`], [Install the Python client SDK]),
    ([`npm install @openrouter/agent`], [Install the higher-level Agent SDK]),
    ([`new OpenRouter({ apiKey })`], [Create a TypeScript SDK client]),
    ([`OpenRouter(api_key=os.getenv("OPENROUTER_API_KEY"))`], [Create a Python SDK client]),
    ([`client.chat.send({ model, messages })`], [Send a chat request with the client SDK]),
    ([`baseURL: "https://openrouter.ai/api/v1"`], [Point the OpenAI SDK at OpenRouter as a drop-in base URL]),
    ([`models: ["model-a", "model-b"]`], [Request routing across candidate models]),
    ([`provider: { ... }`], [Optionally express provider routing preferences]),
    ([`session_id: "..."`], [Sticky routing key for grouped conversations/agent workflows]),
  ))

  == Workflows
  + *Raw API call*: send `POST https://openrouter.ai/api/v1/chat/completions` with auth, JSON body, a `model`, and `messages`.
  + *Use a latest alias*: start with `~openai/gpt-latest` for a moving OpenAI flagship default, then replace it with a specific model slug when reproducibility matters.
  + *Choose integration level*: use raw HTTP for full control, `@openrouter/sdk` / `openrouter` for typed clients, and `@openrouter/agent` for tool use, loops, and state.
  + *OpenAI SDK migration*: keep existing OpenAI SDK structure, set `baseURL`/`base_url` to `https://openrouter.ai/api/v1`, and pass the OpenRouter API key.
  + *Build an agent*: install `@openrouter/agent`, define tools with schemas, call `callModel`, then read the final result with `result.getText()`.
  + *Discover models*: browse `openrouter.ai/models` manually or call `GET /api/v1/models` in tooling.

  == Gotchas
  - OpenRouter-specific attribution headers are optional; they help app attribution/leaderboards but are not required for basic calls.
  - The quickstart recommends OpenRouter SDKs by default; use OpenAI SDK examples mainly when you are migrating existing OpenAI SDK code.
  - `max_tokens` is deprecated in the API reference; prefer `max_completion_tokens`.
  - Not every provider/model supports every parameter (`top_k`, `min_p`, repetition penalty, tool behavior, modalities, etc.).
  - `session_id` can improve sticky routing/cache behavior; keep it stable per conversation but under 256 characters.
  - Streaming changes response handling; debug options in the API reference are streaming-only.
  - Free models and rate limits are documented separately in the FAQ, not in the quickstart.
  - Model aliases are convenient but moving targets; pin exact slugs for regression tests or stable production behavior.
]  
