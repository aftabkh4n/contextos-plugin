# Privacy Policy: ContextOS plugin

Last updated: 26 October 2026

ContextOS runs entirely on your computer. The author does not run any
server and does not receive, collect or store any of your data.

## What ContextOS stores
- Memories that you or Claude save (decisions, notes, todos, skills),
  in a local SQLite database under ~/.contextos/ on your machine.
- Log files under ~/.contextos/logs/. Memory content is not written to
  logs, except that saving a skill logs the skill's short name and tags.

## What ContextOS reads
- Git information for the current repository: branch, recent commit
  messages and the number of uncommitted files. This is used to build
  the context shown to Claude at session start.

## Network use
- On first run and after updates, the plugin downloads the ContextOS
  program from this project's GitHub releases
  (github.com/aftabkh4n/contextos). GitHub may log that request under
  its own privacy policy.
- By default, embeddings are computed locally with a bundled model.
  Nothing is sent anywhere.
- If you choose to configure the optional OpenAI embeddings provider,
  memory text is sent to OpenAI to create embeddings, under OpenAI's
  privacy policy. The optional Ollama provider sends text only to the
  Ollama server you configure, usually on your own machine.

## Retention and deletion
Your data stays on your machine until you delete it. Memories that go
unused for 90 days are archived, not deleted. To remove everything,
delete the ~/.contextos folder.

## Telemetry
None. ContextOS does not collect usage data or analytics.

## Contact
Open an issue at https://github.com/aftabkh4n/contextos-plugin/issues
