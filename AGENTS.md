# Project guidelines

- Use only gpt-6.1-sol for orchestration, gpt-6.1-terra for implementation, and gpt-6-luna for tests and docs. Never invoke gpt-6-astra.
- Keep chat updates to at most five lines, using `[FASE | HH:MM] STATUS | ARQUIVOS | TESTES | PROXIMO`.
- Keep the Flask API, tests, Docker image, Compose configuration and deployment scripts compatible.
- Run `bash run-harness.sh` to execute tests, shell syntax checks, Compose validation, image build and the container smoke test.
- The harness uses port 8080 and retains its project-scoped `cloud-tasks-data` volume for inspection. It removes its containers on exit.
- Preserve existing data when managing Docker volumes. Do not expose credentials or sensitive deployment evidence.
- Validate cloud and GitHub configuration separately; the local harness does not provision or deploy infrastructure.
