# Security

## Snyk High Risk Rating

`caveman-compress` get Snyk High Risk rating from static analysis guesswork. This doc say what skill do and not do.

### What triggers the rating

1. **subprocess usage**: Skill call `claude` CLI with `subprocess.run()` as fallback when `ANTHROPIC_API_KEY` not set. Subprocess use fixed arg list. No shell interpolation. User file content go by stdin, not shell arg.

2. **File read/write**: Skill read file user point to, compress it, write back same path. Save `.original.md` backup next to it. No read or write outside user path.

### What the skill does NOT do

- Not execute user file content as code
- Not make network requests except Anthropic's API (via SDK or CLI)
- Not access files outside path user provide
- Not use shell=True or string interpolation in subprocess calls
- Not collect or transmit data beyond file being compressed

### Auth behavior

If `ANTHROPIC_API_KEY` set, skill use Anthropic Python SDK direct, no subprocess. If not set, fall back to `claude` CLI, which use user existing Claude desktop auth.

### File size limit

Files bigger than 500KB get rejected before any API call.

### Reporting a vulnerability

If you think real security issue found, open GitHub issue with label `security`.