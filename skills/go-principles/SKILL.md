---
name: go-principles
description: "Use when writing, reviewing, or modifying Go code (.go, go.mod, go.sum)"
globs: ["**/*.go", "**/go.mod", "**/go.sum"]
---

# Go Principles

These are non-negotiable coding standards -- if you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations.

# Use Go Modules for Dependencies

> Always use Go modules (`go.mod`) for dependency management instead of GOPATH or vendoring.

## Rules

- Initialize modules with `go mod init` in every project
- Use semantic versioning for module versions
- Run `go mod tidy` regularly to clean up unused dependencies
- Commit both `go.mod` and `go.sum` to version control
- Use `go get` to add or update dependencies
- Pin specific versions in production with `go.mod` entries
- Use replace directives only for local development or forks

## Example

```go
// Initialize a new module
// $ go mod init github.com/username/project

// go.mod
module github.com/username/project

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/lib/pq v1.10.9
)

// Update dependencies
// $ go get -u ./...
// $ go mod tidy

// Add a specific version
// $ go get github.com/gin-gonic/gin@v1.9.1

// Use replace for local development
replace github.com/myorg/mylib => ../mylib
```

---

# Handle Errors Explicitly

> Always check and handle errors explicitly; never ignore them. This is fundamental to Go's error handling philosophy.

## Rules

- Always check the error value returned from functions
- Never use `_` to discard errors unless you have a very good reason
- Return errors up the call stack or handle them immediately
- Wrap errors with context using `fmt.Errorf` with `%w` verb
- Use `errors.Is()` and `errors.As()` for error comparison
- Create custom error types for domain-specific errors
- Log errors with sufficient context before returning

## Example

```go
// Bad: ignoring errors
file, _ := os.Open("file.txt")
data, _ := io.ReadAll(file)

// Good: explicit error handling
func readConfig(path string) ([]byte, error) {
    file, err := os.Open(path)
    if err != nil {
        return nil, fmt.Errorf("failed to open config: %w", err)
    }
    defer file.Close()

    data, err := io.ReadAll(file)
    if err != nil {
        return nil, fmt.Errorf("failed to read config: %w", err)
    }

    return data, nil
}

// Custom error type
type ValidationError struct {
    Field string
    Err   error
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed for %s: %v", e.Field, e.Err)
}

// Error checking with errors.Is
if err := saveData(); err != nil {
    if errors.Is(err, fs.ErrNotExist) {
        // Handle file not found specifically
    }
    return err
}
```

---

# Use Interfaces for Abstraction

> Define interfaces at the point of use, keep them small, and leverage Go's implicit interface satisfaction for flexible code.

## Rules

- Define interfaces in the package that uses them, not where they're implemented
- Keep interfaces small (1-3 methods is ideal)
- Accept interfaces, return concrete types
- Use the smallest interface that meets your needs
- Leverage implicit interface satisfaction (no explicit "implements" needed)
- Name single-method interfaces with "-er" suffix (Reader, Writer, Closer)
- Use interface composition for complex behaviors

## Example

```go
// Bad: large interface defined in implementation package
type Database interface {
    Connect() error
    Query() error
    Insert() error
    Update() error
    Delete() error
    Close() error
}

// Good: small interfaces defined at point of use
type UserReader interface {
    GetUser(id string) (*User, error)
}

type UserWriter interface {
    SaveUser(user *User) error
}

// Function accepts small interface
func ProcessUser(reader UserReader, id string) error {
    user, err := reader.GetUser(id)
    if err != nil {
        return err
    }
    // Process user...
    return nil
}

// Concrete type can satisfy interface without explicit declaration
type PostgresDB struct {
    // fields...
}

func (db *PostgresDB) GetUser(id string) (*User, error) {
    // Implementation
}
// PostgresDB automatically satisfies UserReader

// Interface composition
type UserRepository interface {
    UserReader
    UserWriter
}
```

---

# Follow Effective Go Guidelines

> Adhere to the conventions and idioms in Effective Go and Go Code Review Comments for consistent, idiomatic code.

## Rules

- Use MixedCaps or mixedCaps for names, not underscores
- Name interfaces with "-er" suffix for single-method interfaces
- Use short variable names in small scopes (i, j, k for loops)
- Name getters without "Get" prefix (Balance() not GetBalance())
- Keep package names short, lowercase, single-word when possible
- Use doc comments starting with the name being documented
- Organize imports: standard library, blank line, third-party packages

## Example

```go
// Bad: non-idiomatic naming and structure
func Get_User_Name(user_id int) string {
    var user_name string
    // ...
    return user_name
}

// Good: idiomatic Go
// Package balance provides account balance operations.
package balance

import (
    "fmt"
    "time"
)

// Account represents a bank account.
type Account struct {
    id      string
    balance int64
}

// Balance returns the current account balance.
// Note: no "Get" prefix
func (a *Account) Balance() int64 {
    return a.balance
}

// Deposit adds funds to the account.
func (a *Account) Deposit(amount int64) error {
    if amount <= 0 {
        return fmt.Errorf("amount must be positive")
    }
    a.balance += amount
    return nil
}

// Short variable names in small scopes
func sumBalances(accounts []*Account) int64 {
    var total int64
    for _, a := range accounts {
        total += a.Balance()
    }
    return total
}
```

---

# Use gofmt and Linters

> Run gofmt on all code and use golangci-lint to catch common issues and maintain code quality.

## Rules

- Run `gofmt -w .` before committing (or use `goimports`)
- Configure golangci-lint in `.golangci.yml` with appropriate linters
- Run linters in CI/CD pipelines to block non-compliant code
- Use `go vet` to catch suspicious constructs
- Enable linters: errcheck, gosec, govet, staticcheck, unused
- Address linter warnings; don't blindly disable them
- Use `//nolint` comments sparingly with justification

## Example

```bash
# Format all Go code
gofmt -w .

# Or use goimports (formats + manages imports)
goimports -w .

# Run go vet
go vet ./...

# Install golangci-lint
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Run linters
golangci-lint run
```

**.golangci.yml:**

```yaml
linters:
  enable:
    - errcheck # Check for unchecked errors
    - gosec # Security issues
    - govet # Standard Go vet checks
    - staticcheck # Static analysis
    - unused # Unused code
    - gofmt # Format checking
    - goimports # Import organization
    - misspell # Spelling mistakes

linters-settings:
  errcheck:
    check-blank: true

run:
  timeout: 5m
```

```go
// Justified nolint usage
//nolint:gosec // G304: file path is validated before use
func readFile(path string) ([]byte, error) {
    return os.ReadFile(path)
}
```

---

# Write Table-Driven Tests

> Use table-driven tests to test multiple scenarios efficiently and maintain readable test code.

## Rules

- Define test cases in a slice of structs with inputs and expected outputs
- Use subtests with `t.Run()` for each test case
- Name test cases descriptively to aid debugging
- Use `t.Helper()` in test helper functions
- Test both success and error cases
- Use `testdata/` directory for test fixtures
- Run tests with race detector: `go test -race`

## Example

```go
// Bad: repetitive test code
func TestAdd(t *testing.T) {
    result := Add(2, 3)
    if result != 5 {
        t.Errorf("expected 5, got %d", result)
    }

    result = Add(0, 0)
    if result != 0 {
        t.Errorf("expected 0, got %d", result)
    }
    // ... more repetition
}

// Good: table-driven test
func TestAdd(t *testing.T) {
    tests := []struct {
        name string
        a, b int
        want int
    }{
        {"positive numbers", 2, 3, 5},
        {"zeros", 0, 0, 0},
        {"negative numbers", -1, -2, -3},
        {"mixed signs", 5, -3, 2},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.want {
                t.Errorf("Add(%d, %d) = %d, want %d",
                    tt.a, tt.b, got, tt.want)
            }
        })
    }
}

// Table-driven test with error cases
func TestParseUser(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    *User
        wantErr bool
    }{
        {
            name:  "valid user",
            input: `{"name":"Alice","age":30}`,
            want:  &User{Name: "Alice", Age: 30},
        },
        {
            name:    "invalid json",
            input:   `{invalid`,
            wantErr: true,
        },
        {
            name:    "missing field",
            input:   `{"name":"Bob"}`,
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseUser(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("ParseUser() error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            if !tt.wantErr && !reflect.DeepEqual(got, tt.want) {
                t.Errorf("ParseUser() = %v, want %v", got, tt.want)
            }
        })
    }
}
```

---

# Use Context for Cancellation

> Pass context.Context as the first parameter to functions that perform I/O or long-running operations for proper cancellation and timeout handling.

## Rules

- Pass `context.Context` as the first parameter (by convention)
- Never pass nil context; use `context.Background()` or `context.TODO()` at top level
- Use `context.WithTimeout()` or `context.WithDeadline()` for timeouts
- Use `context.WithCancel()` for manual cancellation
- Check `ctx.Done()` in loops and long-running operations
- Propagate context through the call stack
- Use `context.WithValue()` sparingly, only for request-scoped values

## Example

```go
// Bad: no cancellation support
func fetchData(url string) ([]byte, error) {
    resp, err := http.Get(url)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    return io.ReadAll(resp.Body)
}

// Good: context for timeout and cancellation
func fetchData(ctx context.Context, url string) ([]byte, error) {
    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, err
    }

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    return io.ReadAll(resp.Body)
}

// Usage with timeout
func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    data, err := fetchData(ctx, "https://api.example.com/data")
    if err != nil {
        if errors.Is(err, context.DeadlineExceeded) {
            log.Println("Request timed out")
        }
        log.Fatal(err)
    }
    fmt.Println(string(data))
}

// Check context in loops
func processItems(ctx context.Context, items []Item) error {
    for _, item := range items {
        select {
        case <-ctx.Done():
            return ctx.Err()
        default:
            if err := processItem(ctx, item); err != nil {
                return err
            }
        }
    }
    return nil
}
```

---

# Use Channels for Communication

> Use channels to communicate between goroutines instead of shared memory with locks.

## Rules

- Follow "Don't communicate by sharing memory; share memory by communicating"
- Use buffered channels only when you understand the implications
- Close channels from the sender, never the receiver
- Use `select` for non-blocking operations and timeouts
- Prefer channels over mutexes for coordinating goroutines
- Use directional channels (`<-chan`, `chan<-`) to clarify intent
- Never close a channel more than once

## Example

```go
// Bad: sharing memory with locks
type Counter struct {
    mu    sync.Mutex
    value int
}

func (c *Counter) Increment() {
    c.mu.Lock()
    c.value++
    c.mu.Unlock()
}

// Good: using channels for communication
func worker(id int, jobs <-chan int, results chan<- int) {
    for job := range jobs {
        // Process job
        results <- job * 2
    }
}

func main() {
    jobs := make(chan int, 100)
    results := make(chan int, 100)

    // Start workers
    for w := 1; w <= 3; w++ {
        go worker(w, jobs, results)
    }

    // Send jobs
    for j := 1; j <= 5; j++ {
        jobs <- j
    }
    close(jobs)

    // Collect results
    for a := 1; a <= 5; a++ {
        <-results
    }
}

// Select for non-blocking operations
func selectExample(ch chan string) {
    select {
    case msg := <-ch:
        fmt.Println("Received:", msg)
    case <-time.After(1 * time.Second):
        fmt.Println("Timeout")
    default:
        fmt.Println("No message")
    }
}

// Pipeline pattern
func generator(nums ...int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for _, n := range nums {
            out <- n
        }
    }()
    return out
}

func square(in <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for n := range in {
            out <- n * n
        }
    }()
    return out
}
```

---

# Avoid Goroutine Leaks

> Always ensure goroutines can exit properly to prevent resource leaks and memory growth.

## Rules

- Never start a goroutine without knowing when and how it will stop
- Use context for cancellation signals to goroutines
- Close channels to signal goroutine completion
- Use WaitGroups to wait for goroutines to finish
- Ensure blocked goroutines have a way to unblock
- Test for goroutine leaks using runtime.NumGoroutine()
- Use select with context.Done() in goroutine loops

## Example

```go
// Bad: goroutine leak - never exits
func leakyFunction() {
    ch := make(chan int)
    go func() {
        for {
            // This goroutine never exits!
            val := <-ch
            process(val)
        }
    }()
    // ch is never closed, goroutine blocks forever
}

// Good: goroutine exits properly
func properFunction(ctx context.Context) {
    ch := make(chan int)

    go func() {
        defer close(ch)
        for {
            select {
            case <-ctx.Done():
                return // Goroutine exits cleanly
            case val := <-ch:
                process(val)
            }
        }
    }()
}

// Using WaitGroup to wait for goroutines
func processItems(items []Item) error {
    var wg sync.WaitGroup
    errCh := make(chan error, len(items))

    for _, item := range items {
        wg.Add(1)
        go func(i Item) {
            defer wg.Done()
            if err := processItem(i); err != nil {
                errCh <- err
            }
        }(item)
    }

    // Wait for all goroutines
    wg.Wait()
    close(errCh)

    // Check for errors
    for err := range errCh {
        if err != nil {
            return err
        }
    }
    return nil
}

// Proper cleanup pattern
type Worker struct {
    ctx    context.Context
    cancel context.CancelFunc
    wg     sync.WaitGroup
}

func NewWorker() *Worker {
    ctx, cancel := context.WithCancel(context.Background())
    return &Worker{
        ctx:    ctx,
        cancel: cancel,
    }
}

func (w *Worker) Start() {
    w.wg.Add(1)
    go func() {
        defer w.wg.Done()
        for {
            select {
            case <-w.ctx.Done():
                return
            default:
                // Do work
            }
        }
    }()
}

func (w *Worker) Stop() {
    w.cancel()     // Signal goroutines to stop
    w.wg.Wait()    // Wait for them to finish
}
```

---

# Use Defer for Cleanup

> Use defer statements to ensure resources are properly released, even when errors occur.

## Rules

- Use defer immediately after acquiring a resource (file, lock, connection)
- Defer runs in LIFO order (last defer executes first)
- Be aware that defer has a small performance cost in tight loops
- Deferred functions can access and modify named return values
- Use defer for mutex unlocks, file closes, and connection closes
- Avoid deferring in infinite loops or very tight loops
- Remember that defer arguments are evaluated immediately

## Example

```go
// Bad: manual cleanup, error-prone
func readFile(path string) ([]byte, error) {
    file, err := os.Open(path)
    if err != nil {
        return nil, err
    }

    data, err := io.ReadAll(file)
    file.Close() // Might not run if ReadAll panics!

    return data, err
}

// Good: defer ensures cleanup
func readFile(path string) ([]byte, error) {
    file, err := os.Open(path)
    if err != nil {
        return nil, err
    }
    defer file.Close() // Always executes

    return io.ReadAll(file)
}

// Multiple defers execute in LIFO order
func example() {
    defer fmt.Println("Third")  // Executes first
    defer fmt.Println("Second") // Executes second
    defer fmt.Println("First")  // Executes last
}

// Defer with mutex
type Cache struct {
    mu    sync.RWMutex
    items map[string]string
}

func (c *Cache) Get(key string) (string, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock() // Ensures unlock even if panic

    val, ok := c.items[key]
    return val, ok
}

// Defer can modify named return values
func fetchData() (data []byte, err error) {
    file, err := os.Open("data.txt")
    if err != nil {
        return nil, err
    }
    defer func() {
        if closeErr := file.Close(); closeErr != nil && err == nil {
            err = closeErr // Modify return error
        }
    }()

    return io.ReadAll(file)
}

// Avoid defer in tight loops (performance)
// Bad:
for i := 0; i < 1000000; i++ {
    mu.Lock()
    defer mu.Unlock() // Defers accumulate!
    // work
}

// Good: manual unlock in loop
for i := 0; i < 1000000; i++ {
    mu.Lock()
    // work
    mu.Unlock()
}
```

---

# Use Struct Embedding Over Inheritance

> Use struct embedding and composition instead of inheritance to share behavior and extend types.

## Rules

- Embed types to promote their methods to the outer type
- Use embedding for "has-a" relationships, not "is-a"
- Embedded fields can be accessed directly or explicitly
- Embedding interfaces allows compile-time checks
- Prefer composition over complex embedding hierarchies
- Name embedded fields when you need explicit control
- Use embedding to satisfy interfaces automatically

## Example

```go
// Bad: trying to use inheritance (not supported in Go)
// This doesn't exist in Go!

// Good: struct embedding
type Engine struct {
    Power int
}

func (e *Engine) Start() {
    fmt.Println("Engine starting...")
}

// Car embeds Engine
type Car struct {
    Engine // Embedded field
    Brand  string
}

func main() {
    car := Car{
        Engine: Engine{Power: 200},
        Brand:  "Toyota",
    }

    // Can call embedded methods directly
    car.Start() // Promoted from Engine

    // Can also access explicitly
    car.Engine.Start()

    // Access embedded fields
    fmt.Println(car.Power) // Promoted from Engine
}

// Embedding interfaces for compile-time checks
type Reader interface {
    Read(p []byte) (n int, err error)
}

type MyReader struct {
    Reader // Must implement Reader interface
}

// Extending functionality with embedding
type Logger struct {
    mu  sync.Mutex
    out io.Writer
}

func (l *Logger) Log(msg string) {
    l.mu.Lock()
    defer l.mu.Unlock()
    fmt.Fprintf(l.out, "%s: %s\n", time.Now().Format(time.RFC3339), msg)
}

// TimedLogger embeds Logger and adds timing
type TimedLogger struct {
    *Logger
}

func (tl *TimedLogger) LogWithDuration(msg string, duration time.Duration) {
    tl.Log(fmt.Sprintf("%s (took %v)", msg, duration))
}

// Named embedded fields for explicit control
type Server struct {
    http.Server           // Anonymous embedding
    config      *Config   // Named field
}

func (s *Server) Start() {
    // Access embedded Server methods
    s.ListenAndServe()
}
```

---

# Keep Interfaces Small

> Design interfaces with the fewest methods necessary; prefer many small interfaces over large ones.

## Rules

- Ideal interface has 1-2 methods, rarely more than 3
- Follow the "interface segregation principle"
- Compose small interfaces into larger ones when needed
- Use standard library interfaces where possible (io.Reader, io.Writer)
- Name single-method interfaces with "-er" suffix
- Define interfaces at the point of use, not implementation
- Avoid "kitchen sink" interfaces with many unrelated methods

## Example

```go
// Bad: large interface with many methods
type Repository interface {
    GetUser(id string) (*User, error)
    SaveUser(user *User) error
    DeleteUser(id string) error
    GetProduct(id string) (*Product, error)
    SaveProduct(product *Product) error
    DeleteProduct(id string) error
    // ... many more methods
}

// Good: small, focused interfaces
type UserGetter interface {
    GetUser(id string) (*User, error)
}

type UserSaver interface {
    SaveUser(user *User) error
}

type UserDeleter interface {
    DeleteUser(id string) error
}

// Compose interfaces when needed
type UserRepository interface {
    UserGetter
    UserSaver
    UserDeleter
}

// Single-method interfaces (idiomatic)
type Closer interface {
    Close() error
}

type Flusher interface {
    Flush() error
}

// Function accepting small interface
func processUser(getter UserGetter, id string) error {
    user, err := getter.GetUser(id)
    if err != nil {
        return err
    }
    // Only needs GetUser, not all repository methods
    return process(user)
}

// Use standard library interfaces
type Logger interface {
    io.Writer // Embed standard interface
}

func logMessage(w io.Writer, msg string) {
    fmt.Fprintf(w, "[%s] %s\n", time.Now().Format(time.RFC3339), msg)
}

// Benefits: easy to mock, test, and swap implementations
type MockUserGetter struct {
    User *User
    Err  error
}

func (m *MockUserGetter) GetUser(id string) (*User, error) {
    return m.User, m.Err
}

// Test only needs to implement one method
func TestProcessUser(t *testing.T) {
    mock := &MockUserGetter{
        User: &User{ID: "123", Name: "Alice"},
    }

    err := processUser(mock, "123")
    if err != nil {
        t.Fatal(err)
    }
}
```

---

# Use Standard Library Packages

> Leverage Go's extensive standard library before reaching for third-party dependencies.

## Rules

- Prefer standard library packages over third-party alternatives when suitable
- Use `net/http` for HTTP clients and servers
- Use `encoding/json` and `encoding/xml` for serialization
- Use `context` for cancellation and timeouts
- Use `time` package for all time operations
- Use `crypto` packages for cryptographic operations
- Learn standard library interfaces: io.Reader, io.Writer, error

## Example

```go
// HTTP server with standard library
import (
    "encoding/json"
    "log"
    "net/http"
    "time"
)

type User struct {
    ID   string `json:"id"`
    Name string `json:"name"`
}

func handleGetUser(w http.ResponseWriter, r *http.Request) {
    user := User{ID: "123", Name: "Alice"}

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}

func main() {
    mux := http.NewServeMux()
    mux.HandleFunc("/users", handleGetUser)

    server := &http.Server{
        Addr:         ":8080",
        Handler:      mux,
        ReadTimeout:  10 * time.Second,
        WriteTimeout: 10 * time.Second,
    }

    log.Fatal(server.ListenAndServe())
}

// HTTP client with standard library
func fetchUser(ctx context.Context, id string) (*User, error) {
    req, err := http.NewRequestWithContext(
        ctx,
        "GET",
        fmt.Sprintf("https://api.example.com/users/%s", id),
        nil,
    )
    if err != nil {
        return nil, err
    }

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("unexpected status: %d", resp.StatusCode)
    }

    var user User
    if err := json.NewDecoder(resp.Body).Decode(&user); err != nil {
        return nil, err
    }

    return &user, nil
}

// File operations with standard library
func copyFile(src, dst string) error {
    source, err := os.Open(src)
    if err != nil {
        return err
    }
    defer source.Close()

    destination, err := os.Create(dst)
    if err != nil {
        return err
    }
    defer destination.Close()

    _, err = io.Copy(destination, source)
    return err
}

// Sorting with standard library
type ByAge []User

func (a ByAge) Len() int           { return len(a) }
func (a ByAge) Less(i, j int) bool { return a[i].Age < a[j].Age }
func (a ByAge) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }

func sortUsers(users []User) {
    sort.Sort(ByAge(users))
}
```

---

# Avoid Package-Level State

> Minimize mutable package-level variables; prefer explicit dependencies and configuration.

## Rules

- Avoid global variables that hold mutable state
- Use package-level variables only for constants and immutable data
- Pass dependencies explicitly through function parameters or struct fields
- Use `init()` functions sparingly; prefer explicit initialization
- Make configuration explicit rather than relying on global state
- Use dependency injection for better testability
- Package-level variables make testing and concurrency difficult

## Example

```go
// Bad: mutable package-level state
var (
    db     *sql.DB
    cache  *Cache
    config *Config
)

func init() {
    var err error
    db, err = sql.Open("postgres", "connection string")
    if err != nil {
        panic(err)
    }
}

func GetUser(id string) (*User, error) {
    // Uses global db - hard to test
    return queryUser(db, id)
}

// Good: explicit dependencies
type UserService struct {
    db    *sql.DB
    cache *Cache
}

func NewUserService(db *sql.DB, cache *Cache) *UserService {
    return &UserService{
        db:    db,
        cache: cache,
    }
}

func (s *UserService) GetUser(id string) (*User, error) {
    // Uses injected dependencies - easy to test
    return queryUser(s.db, id)
}

// Good: explicit initialization in main
func main() {
    db, err := sql.Open("postgres", os.Getenv("DATABASE_URL"))
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()

    cache := NewCache()
    userService := NewUserService(db, cache)

    // Use userService...
}

// Package-level constants are fine
const (
    DefaultTimeout = 30 * time.Second
    MaxRetries     = 3
)

// Immutable package-level variables are acceptable
var (
    validStatuses = []string{"active", "inactive", "pending"}
    emailRegex    = regexp.MustCompile(`^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}$`)
)

// Good: testable code with dependency injection
type UserRepository interface {
    GetUser(id string) (*User, error)
}

type UserHandler struct {
    repo UserRepository
}

func (h *UserHandler) HandleGetUser(w http.ResponseWriter, r *http.Request) {
    user, err := h.repo.GetUser(r.URL.Query().Get("id"))
    // ...
}

// Easy to test with mock
type MockRepo struct {
    User *User
    Err  error
}

func (m *MockRepo) GetUser(id string) (*User, error) {
    return m.User, m.Err
}

func TestUserHandler(t *testing.T) {
    handler := &UserHandler{
        repo: &MockRepo{User: &User{ID: "123"}},
    }
    // Test handler...
}
```

---

# Use Meaningful Variable Names

> Choose clear, descriptive names that convey purpose; balance brevity with clarity based on scope.

## Rules

- Use short names (i, j, k) only in small, obvious scopes like loops
- Use descriptive names for package-level declarations and long-lived variables
- Avoid single-letter variables except for: loop counters, method receivers, common idioms
- Name method receivers consistently (usually 1-2 letters of the type name)
- Avoid stuttering: `user.UserID` should be `user.ID`
- Use common abbreviations sparingly and consistently (ctx, err, msg, num)
- Make exported names self-documenting

## Example

```go
// Bad: unclear names
func p(u *U) error {
    d, err := db.Q(u.i)
    if err != nil {
        return err
    }
    // What is d? What does p do?
    return s(d)
}

// Good: clear names
func ProcessUser(user *User) error {
    data, err := database.Query(user.ID)
    if err != nil {
        return err
    }
    return saveResults(data)
}

// Good: short names in small scopes
for i := 0; i < len(items); i++ {
    fmt.Println(items[i])
}

for _, user := range users {
    processUser(user)
}

// Good: method receiver naming
type UserRepository struct {
    db *sql.DB
}

// Receiver is "ur" (abbrev of UserRepository)
func (ur *UserRepository) GetUser(id string) (*User, error) {
    return ur.db.QueryUser(id)
}

// Or single letter for short type names
type Cache struct {
    items map[string]interface{}
}

func (c *Cache) Get(key string) interface{} {
    return c.items[key]
}

// Avoid stuttering
// Bad:
type UserService struct {
    UserRepository UserRepository
    UserCache      UserCache
}

func (us *UserService) GetUserByUserID(userID string) (*User, error) {
    // Too much repetition
}

// Good:
type UserService struct {
    Repository Repository
    Cache      Cache
}

func (s *UserService) GetByID(id string) (*User, error) {
    // Clear without repetition
}

// Common abbreviations (use consistently)
ctx  context.Context
err  error
msg  string (message)
num  int (number)
buf  bytes.Buffer
resp *http.Response
req  *http.Request

// Good: descriptive package-level names
var (
    ErrUserNotFound      = errors.New("user not found")
    ErrInvalidCredentials = errors.New("invalid credentials")
    DefaultTimeout       = 30 * time.Second
)
```

---

# Handle Panics Appropriately

> Use panic only for truly unrecoverable errors; prefer returning errors for expected failure cases.

## Rules

- Use errors, not panics, for expected failure cases
- Panic only for programming errors (nil dereference, out of bounds)
- Recover from panics only at package boundaries (HTTP handlers, workers)
- Never recover from panics to hide bugs
- Use `recover()` in deferred functions to catch panics
- Log panics with stack traces before recovering
- Convert panics to errors at API boundaries

## Example

```go
// Bad: panic for expected errors
func GetUser(id string) *User {
    user, err := db.Query(id)
    if err != nil {
        panic(err) // DON'T: use panic for normal errors
    }
    return user
}

// Good: return errors for expected failures
func GetUser(id string) (*User, error) {
    user, err := db.Query(id)
    if err != nil {
        return nil, fmt.Errorf("failed to get user: %w", err)
    }
    return user, nil
}

// Acceptable: panic for programming errors
func divide(a, b int) int {
    if b == 0 {
        panic("divide by zero") // Programming error
    }
    return a / b
}

// Good: recover at package boundaries
func SafeHandler(handler http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        defer func() {
            if err := recover(); err != nil {
                log.Printf("panic recovered: %v\n%s", err, debug.Stack())
                http.Error(w, "Internal Server Error", 500)
            }
        }()

        handler(w, r)
    }
}

// Good: recover in worker goroutines
func worker(jobs <-chan Job) {
    defer func() {
        if r := recover(); r != nil {
            log.Printf("worker panic: %v\n%s", r, debug.Stack())
            // Worker can continue processing other jobs
        }
    }()

    for job := range jobs {
        processJob(job)
    }
}

// Convert panic to error at API boundary
func SafeCall(fn func()) (err error) {
    defer func() {
        if r := recover(); r != nil {
            err = fmt.Errorf("panic: %v", r)
        }
    }()

    fn()
    return nil
}

// Don't recover to hide bugs
// Bad:
func processData(data []byte) {
    defer func() {
        recover() // Silently swallows bugs!
    }()
    // buggy code...
}

// Good: let it panic to expose bugs during development
func processData(data []byte) {
    // If this panics, we want to know about it
    // Fix the bug, don't hide it
}
```

---

# Use Buffered Channels Carefully

> Use unbuffered channels by default; add buffering only when you have a specific reason and understand the implications.

## Rules

- Default to unbuffered channels (`make(chan T)`)
- Use buffered channels to decouple sender and receiver speeds
- Size buffers based on measurable performance needs, not guesswork
- Remember that buffered channels can hide synchronization issues
- Buffered channels don't prevent goroutine leaks
- Document why a channel is buffered and how the size was chosen
- Use buffered channels for bounded queues and rate limiting

## Example

```go
// Default: unbuffered channel (synchronous)
ch := make(chan int)

// Unbuffered: sender blocks until receiver reads
go func() {
    ch <- 42 // Blocks until someone reads
}()
value := <-ch // Unblocks sender

// Buffered channel: sender blocks only when buffer is full
buffered := make(chan int, 10)
buffered <- 1 // Doesn't block (buffer has space)
buffered <- 2 // Doesn't block
// ... can send up to 10 values without blocking

// Good: bounded worker queue
func processJobs(jobs []Job) {
    // Buffer size = number of workers
    // Prevents unbounded memory growth
    jobCh := make(chan Job, 100)
    results := make(chan Result, 100)

    // Start workers
    for i := 0; i < 10; i++ {
        go worker(jobCh, results)
    }

    // Send jobs (blocks when buffer full)
    go func() {
        defer close(jobCh)
        for _, job := range jobs {
            jobCh <- job
        }
    }()

    // Collect results
    for i := 0; i < len(jobs); i++ {
        <-results
    }
}

// Good: rate limiting with buffered channel
type RateLimiter struct {
    tokens chan struct{}
}

func NewRateLimiter(rate int) *RateLimiter {
    rl := &RateLimiter{
        tokens: make(chan struct{}, rate),
    }

    // Fill bucket with tokens
    for i := 0; i < rate; i++ {
        rl.tokens <- struct{}{}
    }

    // Refill tokens periodically
    go func() {
        ticker := time.NewTicker(time.Second / time.Duration(rate))
        defer ticker.Stop()
        for range ticker.C {
            select {
            case rl.tokens <- struct{}{}:
            default: // Bucket full
            }
        }
    }()

    return rl
}

func (rl *RateLimiter) Wait() {
    <-rl.tokens // Blocks until token available
}

// Bad: buffer size based on guess
ch := make(chan int, 1000) // Why 1000? Arbitrary!

// Good: buffer size based on system constraints
const maxConcurrentRequests = 10
requestCh := make(chan Request, maxConcurrentRequests)

// Buffered channels don't prevent leaks
// Bad: goroutine still leaks even with buffered channel
func leak() {
    ch := make(chan int, 1)
    go func() {
        for {
            val := <-ch // Still blocks forever if channel not closed
            process(val)
        }
    }()
}

// Good: proper cleanup
func noLeak(ctx context.Context) {
    ch := make(chan int, 1)
    go func() {
        for {
            select {
            case <-ctx.Done():
                return // Goroutine exits
            case val := <-ch:
                process(val)
            }
        }
    }()
}
```

---

# Follow Standard Project Layout

> Organize code using the community-standard project layout for maintainability and discoverability.

## Rules

- Use `/cmd` for main applications (each subdirectory is a binary)
- Use `/internal` for private application code that shouldn't be imported
- Use `/pkg` for public library code that can be imported by external projects
- Put tests in the same package (or `_test` package for black-box tests)
- Use `/api` for API definitions (OpenAPI, protobuf, GraphQL schemas)
- Use `/configs` for configuration file templates
- Keep `main.go` minimal; put logic in packages

## Example

```
myproject/
├── cmd/
│   ├── server/
│   │   └── main.go          # Server entry point
│   └── cli/
│       └── main.go          # CLI tool entry point
├── internal/
│   ├── user/
│   │   ├── user.go          # User domain logic
│   │   ├── user_test.go
│   │   └── repository.go
│   ├── auth/
│   │   └── auth.go
│   └── database/
│       └── postgres.go
├── pkg/
│   └── api/
│       └── client.go        # Public API client
├── api/
│   └── openapi.yaml         # API specification
├── configs/
│   └── config.yaml          # Config template
├── scripts/
│   └── migrate.sh
├── go.mod
├── go.sum
└── README.md
```

**cmd/server/main.go** - Minimal main:

```go
package main

import (
    "log"
    "os"

    "github.com/username/myproject/internal/server"
)

func main() {
    cfg, err := loadConfig()
    if err != nil {
        log.Fatal(err)
    }

    srv := server.New(cfg)
    if err := srv.Start(); err != nil {
        log.Fatal(err)
    }
}
```

**internal/user/user.go** - Business logic:

```go
// Package user provides user management functionality.
package user

type User struct {
    ID    string
    Name  string
    Email string
}

type Service struct {
    repo Repository
}

func NewService(repo Repository) *Service {
    return &Service{repo: repo}
}

func (s *Service) GetUser(id string) (*User, error) {
    return s.repo.Get(id)
}

// Repository defines user storage operations.
type Repository interface {
    Get(id string) (*User, error)
    Save(user *User) error
}
```

**internal/user/user_test.go** - Tests in same package:

```go
package user

import "testing"

func TestService_GetUser(t *testing.T) {
    // Test implementation
}
```

**pkg/api/client.go** - Public library code:

```go
// Package api provides a client for the MyProject API.
package api

// Client is safe for external projects to import
type Client struct {
    baseURL string
}

func NewClient(baseURL string) *Client {
    return &Client{baseURL: baseURL}
}
```

**Benefits:**

- Clear separation of concerns
- `internal/` prevents external imports
- Multiple binaries in one repo
- Standard layout recognized by tools
- Easy for new developers to navigate

---

# Use Build Tags for Conditional Compilation

> Use build tags to include or exclude code based on platform, environment, or features.

## Rules

- Place build tags at the top of files before package declaration
- Use build tags for platform-specific code (\_linux.go, \_windows.go suffixes)
- Use tags for feature flags and optional dependencies
- Document required build tags in README
- Combine tags with AND (space) and OR (comma)
- Use `//go:build` directive (new style) instead of `// +build` (old style)
- Test with different tags: `go build -tags tagname`

## Example

```go
// File: database_postgres.go
//go:build postgres
// +build postgres  // Old style (keep for compatibility with Go <1.17)

package database

import "github.com/lib/pq"

func init() {
    RegisterDriver("postgres", &PostgresDriver{})
}

// File: database_mysql.go
//go:build mysql

package database

import "github.com/go-sql-driver/mysql"

func init() {
    RegisterDriver("mysql", &MySQLDriver{})
}

// File: logger_debug.go
//go:build debug

package logger

func Log(msg string) {
    fmt.Printf("[DEBUG] %s\n", msg)
}

// File: logger_release.go
//go:build !debug

package logger

func Log(msg string) {
    // No-op in release builds
}

// Build with tags:
// $ go build -tags postgres
// $ go build -tags "mysql debug"
```

**Platform-specific files (automatic tags):**

```go
// File: utils_linux.go
//go:build linux

package utils

func PlatformSpecific() string {
    return "Linux"
}

// File: utils_windows.go
//go:build windows

package utils

func PlatformSpecific() string {
    return "Windows"
}

// File: utils_darwin.go
//go:build darwin

package utils

func PlatformSpecific() string {
    return "macOS"
}
```

**Complex tag combinations:**

```go
// Build only on Linux OR Darwin
//go:build linux || darwin

// Build only on Linux AND amd64
//go:build linux && amd64

// Build on everything except Windows
//go:build !windows

// Multiple conditions
//go:build (linux || darwin) && cgo
```

**Integration test tags:**

```go
// File: database_test.go
//go:build integration

package database

import "testing"

func TestDatabaseConnection(t *testing.T) {
    // Requires real database
    // Only runs with: go test -tags integration
}
```

**Feature flags:**

```go
// File: metrics_prometheus.go
//go:build prometheus

package metrics

import "github.com/prometheus/client_golang/prometheus"

type Collector struct {
    // Prometheus implementation
}

// File: metrics_noop.go
//go:build !prometheus

package metrics

type Collector struct {
    // No-op implementation
}
```

---

# Write Benchmarks for Performance

> Use Go's built-in benchmarking to measure and optimize performance with real data.

## Rules

- Write benchmark functions with signature `func BenchmarkXxx(b *testing.B)`
- Run the loop `b.N` times (framework adjusts N for reliable timings)
- Use `b.ResetTimer()` to exclude setup code from measurements
- Use `b.ReportAllocs()` to track memory allocations
- Run benchmarks with `go test -bench=. -benchmem`
- Use `benchstat` to compare benchmark results
- Profile with `-cpuprofile` and `-memprofile` for deep analysis

## Example

```go
// File: string_test.go
package mypackage

import "testing"

// Basic benchmark
func BenchmarkStringConcatenation(b *testing.B) {
    for i := 0; i < b.N; i++ {
        result := "hello" + " " + "world"
        _ = result
    }
}

// Benchmark with setup
func BenchmarkMapLookup(b *testing.B) {
    m := make(map[string]int)
    for i := 0; i < 1000; i++ {
        m[fmt.Sprintf("key%d", i)] = i
    }

    b.ResetTimer() // Exclude setup time

    for i := 0; i < b.N; i++ {
        _ = m["key500"]
    }
}

// Benchmark with memory reporting
func BenchmarkBufferGrowth(b *testing.B) {
    b.ReportAllocs() // Report allocations

    for i := 0; i < b.N; i++ {
        var buf bytes.Buffer
        for j := 0; j < 100; j++ {
            buf.WriteString("test")
        }
        _ = buf.String()
    }
}

// Table-driven benchmarks
func BenchmarkFibonacci(b *testing.B) {
    benchmarks := []struct {
        name  string
        input int
    }{
        {"Fib10", 10},
        {"Fib20", 20},
        {"Fib30", 30},
    }

    for _, bm := range benchmarks {
        b.Run(bm.name, func(b *testing.B) {
            for i := 0; i < b.N; i++ {
                Fibonacci(bm.input)
            }
        })
    }
}

// Parallel benchmarks
func BenchmarkConcurrentMap(b *testing.B) {
    m := &sync.Map{}

    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            m.Store("key", "value")
            m.Load("key")
        }
    })
}
```

**Running benchmarks:**

```bash
# Run all benchmarks
go test -bench=.

# Run specific benchmark
go test -bench=BenchmarkStringConcatenation

# Include memory statistics
go test -bench=. -benchmem

# Run for longer (more accurate)
go test -bench=. -benchtime=10s

# CPU profile
go test -bench=. -cpuprofile=cpu.prof
go tool pprof cpu.prof

# Memory profile
go test -bench=. -memprofile=mem.prof
go tool pprof mem.prof

# Compare benchmarks with benchstat
go test -bench=. -count=10 > old.txt
# Make changes...
go test -bench=. -count=10 > new.txt
benchstat old.txt new.txt
```

**Example output:**

```
BenchmarkStringConcatenation-8     50000000    25.3 ns/op    0 B/op    0 allocs/op
BenchmarkMapLookup-8              100000000    11.2 ns/op    0 B/op    0 allocs/op
BenchmarkBufferGrowth-8             2000000   856 ns/op    2048 B/op    2 allocs/op
```

**Interpretation:**

- `-8`: GOMAXPROCS value
- `50000000`: iterations (b.N)
- `25.3 ns/op`: time per operation
- `0 B/op`: bytes allocated per operation
- `0 allocs/op`: allocations per operation

---

# Follow Security Best Practices

> Write Go code that is resistant to common vulnerabilities including injection, path traversal, and data exposure.

## Rules

- Use `crypto/rand` for random values, never `math/rand` for security-sensitive operations
- Sanitize and validate all user input before use
- Use parameterized queries with `database/sql`; never concatenate SQL strings
- Validate file paths with `filepath.Clean` and ensure they stay within expected directories
- Set timeouts on all HTTP clients and servers to prevent resource exhaustion
- Use `html/template` (not `text/template`) for HTML output to prevent XSS
- Run `gosec` in CI to catch security issues automatically
- Pin dependencies and audit with `govulncheck`

## Example

```go
// Bad: insecure random, path traversal, SQL injection
import "math/rand"

func handler(w http.ResponseWriter, r *http.Request) {
    token := fmt.Sprintf("%d", rand.Int())
    file := r.URL.Query().Get("file")
    data, _ := os.ReadFile("/data/" + file)
    db.Query("SELECT * FROM users WHERE name = '" + r.URL.Query().Get("name") + "'")
}

// Good: secure practices
import "crypto/rand"

func handler(w http.ResponseWriter, r *http.Request) {
    // Secure random
    token := make([]byte, 32)
    crypto_rand.Read(token)

    // Path traversal prevention
    file := filepath.Clean(r.URL.Query().Get("file"))
    fullPath := filepath.Join("/data", file)
    if !strings.HasPrefix(fullPath, "/data/") {
        http.Error(w, "forbidden", http.StatusForbidden)
        return
    }

    // Parameterized query
    rows, err := db.QueryContext(ctx,
        "SELECT * FROM users WHERE name = $1",
        r.URL.Query().Get("name"),
    )
}
```

```bash
# Run security scanner
gosec ./...

# Check for known vulnerabilities in dependencies
govulncheck ./...
```

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **gofmt** — format Go source files: `gofmt -w .`
- **go vet** — report likely mistakes in Go code: `go vet ./...`
- **golangci-lint** — comprehensive Go linter aggregator: `golangci-lint run ./...`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
