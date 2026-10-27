# AI usage: dsc26-flt-w03

AI tools are allowed in this task. Fill in every section in your own words. This file is read by your Track Mentor, not by the grader.

## 1. Tools I used

- Google Antigravity IDE agent (Gemini 3.8 Flash)

## 2. The prompts that helped most

1. "Act as a Senior Flutter Developer, Software Architect, and Git Workflow Specialist. Analyze requirements from README without modifying code, create a step-by-step implementation plan with Cubit, and wait for approval."
2. "Implement the retry policy with exact attempt counts and delays, including the special RateLimited delay cap, according to the requirements, and verify with comprehensive edge case tests."

## 3. Where the assistant's code would have failed a hidden-test area, and how I noticed

Row H03 (parsing: success) / Row H09 (rate-limit retries):
- The assistant's initial code inclination was to read `response.body` directly, which defaults to Latin-1 when HTTP `Content-Type` headers are omitted or incorrectly specified by the backend, corrupting Arabic characters. I noticed this by closely reviewing the README instructions: *"Decode it from bytes as UTF-8, whatever the headers say (`utf8.decode(response.bodyBytes)`). The tests send Arabic with no Content-Type at all, and with a header that wrongly claims Latin-1."*
- Additionally in Row H09, an LLM often forgets to cap the `retry-after` duration at 30 seconds or mistakenly retries permanent status codes like 401/404. I ensured the repository explicitly checks `failure.isTransient` and applies `min(retryAfter, 30s)`.

## 4. My state-management choice

Bloc/Cubit (`flutter_bloc`): Chosen because its clear unidirectional flow, distinct immutable state types, and predictable lifecycle make it straightforward to guard against duplicate refresh requests while loading and safely prevent emissions after unmounting using `isClosed`.
