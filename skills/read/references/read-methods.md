# Read Methods Reference

## Proxy Cascade

Try in order. Success = non-empty output with readable content. If a proxy returns empty, an error page, or fewer than 5 lines, treat it as failed and try the next:

### 1. r.jina.ai

```bash
curl -sL "https://r.jina.ai/{url}"
```

Wide coverage, preserves image links. Try this first.

### 2. defuddle.md

```bash
curl -sL "https://defuddle.md/{url}"
```

Cleaner output with YAML frontmatter. Use if r.jina.ai returns empty or errors.

### 3. Local tools

```bash
npx agent-fetch "{url}" --json
# or
defuddle parse "{url}" -m -j
```

Last resort if both proxies fail.

## PDF to Markdown

### Remote PDF URL

r.jina.ai handles PDF URLs directly:

```bash
curl -sL "https://r.jina.ai/{pdf_url}"
```

If that fails, download and extract locally:

```bash
curl -sL "{pdf_url}" -o /tmp/input.pdf
pdftotext -layout /tmp/input.pdf -
```

### Local PDF file

```bash
# Best quality (requires: pip install marker-pdf)
marker_single /path/to/file.pdf --output_dir ~/Downloads/

# Fast, text-heavy PDFs (requires: brew install poppler)
pdftotext -layout /path/to/file.pdf - | sed 's/\f/\n---\n/g'

# No-dependency fallback
python3 -c "
import pypdf, sys
r = pypdf.PdfReader(sys.argv[1])
print('\n\n'.join(p.extract_text() for p in r.pages))
" /path/to/file.pdf
```

Use `marker` when layout matters (papers, tables). Use `pdftotext` for speed.

## WeChat Public Account

Requires a local `fetch_weixin.py` with `playwright`, `beautifulsoup4`, `lxml`.

```bash
python3 /path/to/fetch_weixin.py "{url}"
```

Output: YAML frontmatter (title, author, date, url) + Markdown body.
Fallback: use proxy cascade if no local script is available.
