# Use COPY Instead of ADD

> Prefer `COPY` over `ADD` unless you specifically need `ADD`'s extra features. `COPY` is explicit and predictable.

## Rules

- Use `COPY` for copying local files and directories into the image
- Only use `ADD` when you need automatic tar extraction or fetching remote URLs (and prefer `curl`/`wget` + `RUN` over `ADD` for remote URLs)
- `ADD` has implicit behavior (auto-extraction, remote fetch) that can introduce unexpected files or security risks
- Never use `ADD` with remote URLs to untrusted sources — use `curl` or `wget` in a `RUN` step so you can verify checksums
- Use `COPY --chown` to set file ownership in the same layer

## Example

```dockerfile
# Bad: ADD when COPY would suffice
ADD . /app
ADD config.json /etc/app/config.json

# Bad: ADD for remote files (no checksum verification)
ADD https://example.com/binary /usr/local/bin/binary

# Good: explicit COPY
COPY . /app
COPY config.json /etc/app/config.json

# Good: download with verification
RUN curl -fsSL https://example.com/binary -o /usr/local/bin/binary && \
    echo "expected_sha256  /usr/local/bin/binary" | sha256sum -c - && \
    chmod +x /usr/local/bin/binary
```
