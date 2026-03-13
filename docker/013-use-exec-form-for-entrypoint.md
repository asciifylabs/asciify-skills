# Use Exec Form for CMD and ENTRYPOINT

> Always use the exec form (JSON array) for `CMD` and `ENTRYPOINT` so the application runs as PID 1 and receives signals correctly.

## Rules

- Use exec form `["executable", "arg1", "arg2"]` instead of shell form `executable arg1 arg2`
- Shell form wraps the command in `/bin/sh -c`, which means the application is not PID 1 and does not receive `SIGTERM` for graceful shutdown
- Use `ENTRYPOINT` for the main executable and `CMD` for default arguments that can be overridden
- If you need shell features (variable expansion, pipes), use an explicit shell: `["/bin/sh", "-c", "command"]`
- Never combine `ENTRYPOINT` shell form with `CMD` — the behavior is unpredictable
- Ensure the application handles `SIGTERM` for clean shutdown in container orchestrators

## Example

```dockerfile
# Bad: shell form — app runs under /bin/sh, does not receive signals
ENTRYPOINT python app.py
CMD python app.py --port 8080

# Good: exec form — app is PID 1, receives SIGTERM
ENTRYPOINT ["python", "app.py"]
CMD ["--port", "8080"]

# Good: explicit shell when needed
CMD ["/bin/sh", "-c", "envsubst < config.tmpl > config.json && exec python app.py"]
```
