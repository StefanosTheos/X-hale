# X-hale limitations and roadmap

This is the maintained public engineering backlog, replacing root review diaries. Historical observations are not automatically current defects: confirm the implementation and associated tests before changing an item's status.

## Public-release preparation

- [x] Correct documentation for model defaults, processing order, optional retrieval, buffered SSE output and awaited memory curation.
- [x] Label biometrics as demonstration data and the app as a research prototype.
- [x] Add the owner-approved MIT code license with a separate third-party review.
- [x] Ignore local manuscripts, CV, editorial reviews and generated evaluation output.
- [x] Consolidate durable findings here and preserve private review copies outside the tracked tree.
- [x] Replace screenshot placeholders with supplied application captures and document their provenance/version limits.
- [ ] Add a current Hailey conversation capture from a controlled demo account; record its date and code revision.
- [ ] Complete [asset-provenance and redistribution review](../THIRD_PARTY_NOTICES.md), including historical copies.
- [ ] Confirm Firebase restrictions, Appwrite permissions, server-key scopes and deployment access controls. Public client identifiers do not establish secure cloud configuration.
- [ ] Provide a complete Appwrite schema/bootstrap and reviewed seed data; manual instructions are not an automated fresh-project deployment.
- [ ] Add routine Flutter/backend test CI alongside benchmark and keep-alive workflows.
- [ ] Validate deployment provenance, dependency versions, operating limits and monitoring before production release.

## AI evaluation, safety and knowledge

- [ ] Obtain independent clinical/content review; developer-authored scenarios and model judges do not establish clinical efficacy or safety.
- [ ] Extend evaluation to natural multi-turn dialogue, memory acquisition, prompt injection, multilingual behavior and emergency/overdose detection.
- [ ] Review triage parse-failure behavior: its current fallback is non-crisis general conversation.
- [ ] Improve crisis-resource localization and maintenance; verify end-to-end client locale transmission.
- [ ] Strengthen canonical source metadata and citation validation; lexical/numeric checks do not establish semantic entailment or clinical correctness.
- [ ] Verify deployed Qdrant contents against the intended manifest and each evaluation's corpus version.
- [ ] Validate extracted facts and confidence empirically; inspect whether storage limits before ranking omit more relevant facts.
- [ ] Keep graph expansion, reranking and web fallback disabled until quality, source, quota and latency regressions have been evaluated.
- [ ] Treat fine-tuning as a later experiment, not an implemented capability.

## Privacy, operations and application quality

- [ ] Review conversation/fact deletion consistency and failure recovery; they are separate operations rather than one atomic erasure.
- [ ] Complete logging redaction, access and retention review; verify operational endpoint exposure and metrics collection.
- [ ] Measure concurrency, recovery, latency and availability separately from sequential benchmark completion.
- [ ] Recheck quit-date time zones and cross-device profile synchronization.
- [ ] Re-evaluate older mini-game/UX observations against current code: 2048 pause/resume, repeated game-over UI, obstacle randomness/interval naming, avatar flows and loading affordances.

The removed `chatbot_review.md` assessed the legacy backend. `chatbot_revamp_overview.md` mixed a design proposal with later implementation notes. Use [the active architecture](../rag_backend2.0/ARCHITECTURE.md) and [setup guide](SETUP.md) for current behavior.

Publication-method and participant-study editorial notes remain private. Study evidence about an earlier assistant must not be presented as validation of current Hailey.
