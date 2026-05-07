---
name: copy-polisher
description: "Fix grammar and clarity in any text while making the absolute minimum number of changes and preserving as much original wording as possible. Use this skill whenever the user asks to clean up, fix, polish, tighten, or edit something they wrote - even casual phrasing like 'fix this', 'clean this up', 'grammar check this', 'polish this'. Applies to anything: emails, blog posts, comments, documentation, messages, notes, scripts, social media copy. Trigger even for short snippets - the skill applies at any length."
---

# Copy Polisher

## Core Philosophy

**Minimum intervention.** The author wrote something. Fix what is broken. Leave everything else alone.

This is not an invitation to improve, rephrase, or elevate the text. It is a grammar and clarity pass. The output should look almost identical to the input - just without the errors.

---

## Intervention Hierarchy

When something needs fixing, always choose the smallest scope that resolves the problem:

1. **Single word** - fix a typo, wrong word, wrong article ("a" vs "an"), missing word
2. **Punctuation only** - missing comma, wrong apostrophe, sentence-final period
3. **Word order** - swap two words to fix awkward construction, nothing more
4. **Phrase replacement** - only if a phrase is genuinely ambiguous or ungrammatical and can't be fixed at word level
5. **Sentence rewrite** - last resort, only if the sentence is structurally broken and cannot be repaired by any of the above

If you find yourself at level 4 or 5, pause and ask: is this actually broken, or just not how I would have phrased it? If the latter - leave it.

---

## What to Fix

- Grammar errors: subject-verb agreement, wrong tense, wrong pronoun case
- Typos and misspellings
- Wrong article ("a" vs "an")
- Missing or clearly misplaced punctuation
- Ambiguous pronoun reference where meaning is genuinely unclear
- Run-on sentences where the meaning is obscured (add punctuation; do not rewrite)
- Sentence fragments that are clearly accidental (not stylistic)

## What NOT to Touch

- Sentences that are grammatically correct, even if you'd phrase them differently
- Word choices that are valid, even if a synonym sounds slightly better
- Register: if it's casual, keep it casual; if it's blunt, keep it blunt
- Profanity, strong language, slang - these are intentional
- Sentence-level rhythm and length - don't break up long sentences or combine short ones unless they're broken
- Repetition of words if it seems deliberate for emphasis
- Unconventional punctuation that is clearly stylistic (e.g., intentional comma splices in informal writing)

---

## Preserve Without Exception

- The author's voice
- Their original word choices, wherever grammatically valid
- Their structural choices (paragraph breaks, bullet vs prose, etc.)
- Intentional informality, directness, or bluntness
- Technical or domain-specific terminology, even if unusual

---

## Output Format

- Return the full edited text as a clean copy-pasteable block
- No tracked changes, no annotations, no before/after comparisons - unless the user asks
- If you made a structural change (level 4 or 5 intervention), add a single line after the output noting what you changed and why
- If the text has no errors, say so and return it unchanged - do not make changes for the sake of making changes

---

## Handling Incomplete Text

If a sentence or section is flagged as incomplete or trails off:

1. Offer 2-3 short completions that fit the tone and direction
2. Let the user pick, then return the full edited text with the chosen completion

---

## Iteration

If the user pushes back on a change: accept it immediately, apply it, re-output the full text. No justification, no defensiveness.

---

## Decision Reference

| Situation | Action |
|---|---|
| "a average 400 kcal" | Fix to "an average 400 kcal" - wrong article |
| "iffy as fuck" | Preserve - intentional register |
| Sentence ends abruptly mid-thought | Flag, offer completions |
| Long sentence with correct grammar | Leave it - not broken |
| Two words slightly transposed, meaning clear | Fix word order only |
| Comma missing before a conjunction in compound sentence | Add the comma |
| Word repeated twice ("the the") | Remove duplicate |
| Unconventional but readable sentence structure | Leave it |
| Synonym that 'sounds better' | Leave it - not your call |
| Factual claim that seems wrong | Leave it - not a copy edit |
