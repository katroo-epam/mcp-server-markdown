# Context

We have an MCP server that works with markdown documentation. We want to add the ability to automatically find all links in documents — to other files, to websites, to images — and return them in a clean, structured format. Right now this has to be done manually or with separate scripts, which is inconvenient.

The MCP server should be able to scan a given folder, go through all markdown files inside, and collect a list of every link: where exactly in the file it appears, where it points, and whether it actually works. If a link points to a local file, we'd like to know right away whether that file exists. If not — mark it as broken.

The output should be a simple list: file, line number, link type, text, and target URL. Something that can be plugged into automation — for example, a CI pipeline that checks documentation for broken links.

# Goal

Add an MCP tool called `find_links` to `mcp-server-markdown`.
It scans markdown files under a directory and returns the links it finds as structured JSON.

# Input

```json
{
  "directory": "project/docs",
  "validateLocal": true,
  "includeImages": true,
  "includeExternal": true
}
```

- `directory` is required.
- `validateLocal`, `includeImages`, and `includeExternal` are optional.

# Output

Return JSON in this shape:

```json
{
  "links": [
    {
      "file": "guides/intro.md",
      "line": 1,
      "column": 5,
      "kind": "link",
      "text": "API",
      "target": "../api.md#intro",
      "status": "ok"
    }
  ]
}
```

Each item in `links` has `file`, `line`, `column`, `kind`, `text`, `target`, and `status`.
`kind` is `link`, `image`, or `reference`.
`status` is `ok`, `missing_file`, `missing_anchor`, `external`, or `skipped`.

# Rules

- Scan markdown files recursively under `directory` and return the links it finds as structured JSON.
- Return `file` paths relative to `directory`, with `line` and `column` as 1-based positions.
- Support inline links, inline images, and full reference links. Return records for link usages in markdown content, not for reference definition lines.
- For images, `text` is the alt text. For reference links, `target` is the resolved target.
- If `includeImages` is `false`, omit image links. If `includeExternal` is `false`, omit external links.
- If `validateLocal` is `false`, local links stay in the result with `status: "skipped"`.
- If `validateLocal` is `true`, existing local files without fragments are `ok`, existing markdown files with anchors are `ok`, missing local files are `missing_file`, and missing anchors are `missing_anchor`.
- Local targets resolve relative to the source file, and `#anchor` refers to the current file.
- External targets are targets with an explicit URI scheme, and they are not fetched.
- Missing `directory` or a non-directory `directory` value must fail as an MCP tool error.
- A bad file or bad record must not fail the whole call.

# Examples

File tree:

```text
docs/
  api.md
  install.md
  logo.png
  guides/
    intro.md
```

Input:

```json
{
  "directory": "docs",
  "validateLocal": false,
  "includeImages": true,
  "includeExternal": true
}
```

`docs/guides/intro.md`:

```md
See [API](../api.md#intro)
![Logo](../logo.png)
[Install guide][install]
[Site](https://example.com)

[install]: ../install.md
```

Expected result:

```json
{
  "links": [
    {
      "file": "guides/intro.md",
      "line": 1,
      "column": 5,
      "kind": "link",
      "text": "API",
      "target": "../api.md#intro",
      "status": "skipped"
    },
    {
      "file": "guides/intro.md",
      "line": 2,
      "column": 1,
      "kind": "image",
      "text": "Logo",
      "target": "../logo.png",
      "status": "skipped"
    },
    {
      "file": "guides/intro.md",
      "line": 3,
      "column": 1,
      "kind": "reference",
      "text": "Install guide",
      "target": "../install.md",
      "status": "skipped"
    },
    {
      "file": "guides/intro.md",
      "line": 4,
      "column": 1,
      "kind": "link",
      "text": "Site",
      "target": "https://example.com",
      "status": "external"
    }
  ]
}
```

File tree:

```text
docs/
  target.md
  guides/
    intro.md
```

Input:

```json
{
  "directory": "docs",
  "validateLocal": true,
  "includeImages": true,
  "includeExternal": true
}
```

`docs/target.md`:

```md
# anchor
```

`docs/guides/intro.md`:

```md
[Good](../target.md#anchor)
[Missing file](../missing.md)
[Missing anchor](../target.md#missing-anchor)
```

Expected behavior: `../target.md#anchor` is `ok`, `../missing.md` is `missing_file`, and `../target.md#missing-anchor` is `missing_anchor`.
