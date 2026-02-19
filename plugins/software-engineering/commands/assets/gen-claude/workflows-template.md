# Development Workflows

## Feature Development
[Standard flow based on Agent #4 git/CI analysis]
1. Create feature branch from main
2. Implement changes with tests
3. Run linters: [command from Agent #1]
4. Submit PR for review
5. Merge after approval

## Code Review Process
[From Agent #4 CONTRIBUTING.md analysis or provide defaults]
- All PRs require review
- Automated checks must pass
- [Custom review requirements if found]

## Testing Strategy
[From Agent #3 testing patterns]
- Unit tests: [location, naming convention]
- Integration tests: [if detected]
- Coverage threshold: [if found in CI config]

## Release Process
[From Agent #4 CI/CD analysis]
[If GitHub Actions/GitLab CI detected with release workflow:]
- Automated via [CI system]
- Triggered by: [tags, manual, schedule]
[Else:]
- Manual release process (document in CI/CD setup)
