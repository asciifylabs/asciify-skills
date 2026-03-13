# Use Multi-Stage Builds

> Use multi-stage builds to separate build dependencies from the runtime image, producing smaller and more secure final images.

## Rules

- Use a builder stage for compilation, dependency installation, and asset generation
- Copy only the necessary artifacts into the final runtime stage
- Name stages explicitly with `AS` for clarity (e.g., `FROM golang:1.22 AS builder`)
- Use the smallest possible base image for the final stage (e.g., `distroless`, `alpine`, `slim`)
- Never ship build tools, compilers, or package managers in production images
- Use `--from=builder` to copy artifacts between stages

## Example

```dockerfile
# Bad: single stage with build tools in production
FROM golang:1.22
WORKDIR /app
COPY . .
RUN go build -o server .
CMD ["./server"]

# Good: multi-stage build
FROM golang:1.22 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o server .

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /app/server /server
USER nonroot:nonroot
ENTRYPOINT ["/server"]
```
