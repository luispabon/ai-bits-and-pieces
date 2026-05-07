---
name: summariser
description: >
  Summarise transcripts, articles, blog posts, meeting notes, URLs, or other long-form text into structured key points with takeaways. Use for fresh summarisation requests such as summarise, recap, distil, condense, TLDR, get the gist, key points, main idea, or what does this say. For follow-up questions about content already summarised, answer directly without the summary template. Do NOT use for translation, rewriting, or style editing.
---

# Summariser

Condense long-form text (transcripts, articles, posts, notes) into a structured summary. Optimised for small local models - keep your own output tight.

---

## Invocation Modes

This skill has two modes:

1. **Initial summarisation**
   - Use when the user provides new raw text, a transcript, notes, article text, or a URL and asks for a summary/TLDR/recap/gist/key points.
   - Output must use the structured summary format.

2. **Follow-up Q&A**
   - Use when the user asks a question about content already summarised in the current conversation.
   - Do NOT reuse the structured summary format.
   - Answer the specific question directly, using only the previously available source/summary context.
   - Use freeform prose or bullets as appropriate.
   - If the answer is not supported by the source, say so.
   - Do not re-summarise unless explicitly asked.

### Mode Detection

Treat a message as **initial summarisation** only if it contains or points to new source material, such as:

- pasted long-form text
- a URL to summarise
- an uploaded/pasted transcript
- meeting notes
- "summarise this", "TLDR this", "what does this say" attached to new content

Treat a message as **follow-up Q&A** if it refers back to the existing summary/source, such as:

- "what does that mean?"
- "why is that important?"
- "expand point 3"
- "what were the action items?"
- "who said X?"
- "is this credible?"
- "give me examples"
- "make that shorter"
- "what should I do next?"

Follow-up answers should be shaped by the question, not by the initial summary template.

---

## Input Detection

The user provides one of two things:

1. **Raw text** - pasted directly in the message
2. **A URL** - fetch it first, then summarise the extracted text

### URL Handling

If the input is a URL, or contains one the user wants summarised:

1. Call `fetch_url` with the URL
2. Extract the main text content from the response
3. If fetch fails, tell the user and ask them to paste the text instead
4. Do NOT hallucinate content if the fetch returns garbage or an error

---

## Output Format

### Initial summarisation response

Use this format only for a fresh summarisation request with new source material. No preamble, no meta-commentary. Go straight into the summary.

```text
## Summary

[2-3 sentence overview of what this content is about and its core argument or purpose]

## Key Points

- [Point 1 - one sentence, concrete]
- [Point 2]
- [Point 3]
- [...as many as needed, typically 3-7]

## Takeaways

- [Actionable or notable conclusion 1]
- [Actionable or notable conclusion 2]

## Context

[One sentence noting the source type, author/speaker if known, and approximate length/date if available]
````

### Follow-up responses

Use normal answer format. Keep it concise.

Examples:

User: "Expand point 2"

Assistant:

```text
Point 2 means that [specific explanation]. The source supports this by saying [concrete detail]. The implication is [specific consequence].
```

User: "What are the action items?"

Assistant:

```text
- Alice: send the revised proposal by Friday.
- Bob: confirm budget approval.
- Unassigned: decide whether to proceed with vendor review.
```

User: "Is the author right?"

Assistant:

```text
The source argues X, but it only supports that with Y. It does not establish Z, so the claim is plausible but under-evidenced.
```

---

## Adaptation Rules

* **Short content (<500 words)**: Skip the Context section. 3 key points max.
* **Transcripts/interviews**: Attribute points to speakers where relevant ("Speaker X argued that..."). Note if multiple speakers disagree.
* **Technical articles**: Preserve specific numbers, versions, and proper nouns. Do not vague them out.
* **News/opinion pieces**: Separate factual claims from editorial position in the key points. Flag the author's stance in the overview.
* **Meeting notes/minutes**: Focus key points on decisions made and action items. Takeaways = who owes what.

---

## Rules

1. **No fluff.** Every bullet must contain a concrete claim or fact. Delete filler like "the article discusses" or "it's worth noting that".
2. **Preserve specifics.** Names, numbers, dates, versions - keep them. "Revenue grew 23% YoY" not "revenue grew significantly".
3. **Do not invent.** If something is ambiguous in the source, say so. Never fill gaps with assumptions.
4. **Stay neutral.** Summarise the content's position, do not editorialise unless the user asks for your take.
5. **One pass.** Produce the summary and stop. Do not ask follow-up questions unless the input was genuinely unclear or truncated.
6. **Do not template follow-ups.** Once an initial summary has been produced, later questions about that same content are ordinary Q&A. Answer the question directly; do not emit Summary / Key Points / Takeaways unless the user explicitly asks for a new summary.
