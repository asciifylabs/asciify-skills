---
name: rust-principles
description: "Use when writing, reviewing, or modifying Rust code (.rs, Cargo.toml)"
globs: ["**/*.rs", "**/Cargo.toml", "**/Cargo.lock"]
---

# Rust Principles

These are non-negotiable coding standards -- if you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations.

# Embrace Ownership and Borrowing

> Understand and leverage Rust's ownership system to write memory-safe code without garbage collection.

## Rules

- Each value has exactly one owner at a time
- Use borrowing (`&T`) for read-only access, mutable borrowing (`&mut T`) for write access
- Cannot have mutable and immutable borrows simultaneously
- References must always be valid (no dangling pointers)
- Use `.clone()` explicitly when you need ownership of data
- Prefer borrowing over cloning for performance
- Let the compiler guide you to correct ownership patterns

## Example

```rust
// Bad: trying to use value after move
fn main() {
    let s = String::from("hello");
    take_ownership(s);
    println!("{}", s); // ERROR: s moved
}

fn take_ownership(s: String) {
    println!("{}", s);
}

// Good: borrowing instead of moving
fn main() {
    let s = String::from("hello");
    borrow_value(&s);
    println!("{}", s); // OK: s still owned here
}

fn borrow_value(s: &str) {
    println!("{}", s);
}

// Good: returning ownership
fn main() {
    let s = String::from("hello");
    let s = append_world(s);
    println!("{}", s); // OK: got ownership back
}

fn append_world(mut s: String) -> String {
    s.push_str(" world");
    s
}

// Mutable borrowing
fn main() {
    let mut data = vec![1, 2, 3];
    modify_data(&mut data); // Mutable borrow
    println!("{:?}", data); // [1, 2, 3, 4]
}

fn modify_data(data: &mut Vec<i32>) {
    data.push(4);
}

// Cannot have simultaneous mutable and immutable borrows
fn main() {
    let mut s = String::from("hello");
    let r1 = &s;     // OK: immutable borrow
    let r2 = &s;     // OK: multiple immutable borrows
    // let r3 = &mut s; // ERROR: cannot borrow as mutable while immutably borrowed
    println!("{} {}", r1, r2);

    let r3 = &mut s; // OK: immutable borrows no longer used
    r3.push_str(" world");
}
```

---

# Use Result and Option for Error Handling

> Use `Result<T, E>` for operations that can fail and `Option<T>` for values that may be absent instead of exceptions or null.

## Rules

- Return `Result<T, E>` from functions that can fail
- Use `Option<T>` for values that may or may not exist
- Use the `?` operator to propagate errors concisely
- Avoid `.unwrap()` in production code; use proper error handling
- Use `.expect()` only when failure is truly impossible
- Implement custom error types with `thiserror` or `anyhow`
- Use pattern matching to handle different error cases

## Example

```rust
use std::fs::File;
use std::io::{self, Read};

// Bad: unwrap panics on error
fn read_file_bad(path: &str) -> String {
    let mut file = File::open(path).unwrap(); // Panics!
    let mut contents = String::new();
    file.read_to_string(&mut contents).unwrap();
    contents
}

// Good: propagate errors with Result
fn read_file(path: &str) -> Result<String, io::Error> {
    let mut file = File::open(path)?;
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;
    Ok(contents)
}

// Good: handle errors explicitly
fn main() {
    match read_file("config.txt") {
        Ok(contents) => println!("File contents: {}", contents),
        Err(e) => eprintln!("Failed to read file: {}", e),
    }
}

// Using Option for nullable values
fn find_user(id: u64, users: &[User]) -> Option<&User> {
    users.iter().find(|u| u.id == id)
}

fn main() {
    let users = vec![User { id: 1, name: "Alice" }];

    match find_user(1, &users) {
        Some(user) => println!("Found: {}", user.name),
        None => println!("User not found"),
    }

    // Or use if let
    if let Some(user) = find_user(1, &users) {
        println!("Found: {}", user.name);
    }
}

// Custom error types with thiserror
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ConfigError {
    #[error("File not found: {0}")]
    FileNotFound(String),

    #[error("Parse error: {0}")]
    ParseError(String),

    #[error(transparent)]
    IoError(#[from] std::io::Error),
}

fn load_config(path: &str) -> Result<Config, ConfigError> {
    let contents = std::fs::read_to_string(path)
        .map_err(|_| ConfigError::FileNotFound(path.to_string()))?;

    parse_config(&contents)
        .map_err(|e| ConfigError::ParseError(e.to_string()))
}

// Acceptable: expect with explanation
fn main() {
    let config = std::env::var("CONFIG_PATH")
        .expect("CONFIG_PATH environment variable must be set");
}
```

---

# Leverage the Type System

> Use Rust's powerful type system to encode invariants and prevent bugs at compile time.

## Rules

- Use newtypes to wrap primitives and add type safety
- Use enums to represent state and alternatives
- Make invalid states unrepresentable
- Use zero-sized types for compile-time guarantees
- Leverage traits to define shared behavior
- Use the type system to enforce business rules
- Prefer compile-time errors over runtime errors

## Example

```rust
// Bad: primitives don't prevent mistakes
fn transfer(from: u64, to: u64, amount: f64) {
    // Can accidentally swap from/to
    // Amount could be negative
}

// Good: newtypes for type safety
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct UserId(u64);

#[derive(Debug, Clone, Copy, PartialEq)]
struct Amount(u64); // Stored in cents

impl Amount {
    fn new(cents: u64) -> Self {
        Amount(cents)
    }

    fn from_dollars(dollars: f64) -> Self {
        Amount((dollars * 100.0) as u64)
    }
}

fn transfer(from: UserId, to: UserId, amount: Amount) {
    // Type system prevents swapping from/to with amount
    // Amount cannot be negative
}

// Make invalid states unrepresentable with enums
// Bad: can be in invalid state
struct Connection {
    connected: bool,
    socket: Option<TcpStream>,
}

// Good: enum enforces valid states
enum Connection {
    Disconnected,
    Connected { socket: TcpStream },
}

impl Connection {
    fn send(&mut self, data: &[u8]) -> Result<(), Error> {
        match self {
            Connection::Connected { socket } => socket.write_all(data),
            Connection::Disconnected => Err(Error::NotConnected),
        }
    }
}

// Use enums for state machines
enum Order {
    Pending { items: Vec<Item> },
    Confirmed { items: Vec<Item>, total: Amount },
    Shipped { tracking_number: String },
    Delivered,
}

impl Order {
    fn confirm(self) -> Result<Order, Error> {
        match self {
            Order::Pending { items } => {
                let total = calculate_total(&items)?;
                Ok(Order::Confirmed { items, total })
            }
            _ => Err(Error::InvalidState),
        }
    }
}

// Zero-sized types for compile-time guarantees
struct Validated;
struct Unvalidated;

struct Email<State = Unvalidated> {
    address: String,
    _state: PhantomData<State>,
}

impl Email<Unvalidated> {
    fn new(address: String) -> Self {
        Email {
            address,
            _state: PhantomData,
        }
    }

    fn validate(self) -> Result<Email<Validated>, Error> {
        if self.address.contains('@') {
            Ok(Email {
                address: self.address,
                _state: PhantomData,
            })
        } else {
            Err(Error::InvalidEmail)
        }
    }
}

impl Email<Validated> {
    fn send(&self, msg: &str) {
        // Can only call send on validated emails!
    }
}
```

---

# Use Cargo Effectively

> Leverage Cargo for dependency management, building, testing, and publishing Rust projects.

## Rules

- Use `Cargo.toml` for all project configuration and dependencies
- Pin dependencies with version constraints (semantic versioning)
- Use workspaces for multi-crate projects
- Run `cargo clippy` for linting and `cargo fmt` for formatting
- Use `cargo build --release` for optimized production builds
- Lock dependencies with `Cargo.lock` (commit for binaries, ignore for libraries)
- Use feature flags to make dependencies optional

## Example

**Cargo.toml:**

```toml
[package]
name = "myapp"
version = "0.1.0"
edition = "2021"
authors = ["Your Name <you@example.com>"]

[dependencies]
# Semantic versioning constraints
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1.35", features = ["full"] }
reqwest = "0.11"

[dev-dependencies]
# Development/test-only dependencies
mockall = "0.12"

[build-dependencies]
# Build script dependencies
cc = "1.0"

[features]
default = ["json"]
json = ["serde_json"]
xml = ["quick-xml"]

[[bin]]
name = "myapp"
path = "src/main.rs"

[profile.release]
opt-level = 3
lto = true
codegen-units = 1
```

**Common Cargo commands:**

```bash
# Create new project
cargo new myapp
cargo new --lib mylib

# Build project
cargo build              # Debug build
cargo build --release    # Optimized build

# Run project
cargo run
cargo run --release

# Test project
cargo test              # Run all tests
cargo test test_name    # Run specific test

# Lint and format
cargo clippy            # Lint
cargo fmt               # Format code

# Update dependencies
cargo update

# Check without building
cargo check             # Fast syntax check

# Build documentation
cargo doc --open

# Publish to crates.io
cargo publish
```

**Workspace setup (Cargo.toml in root):**

```toml
[workspace]
members = [
    "crates/core",
    "crates/api",
    "crates/cli",
]

[workspace.dependencies]
# Shared dependency versions
tokio = { version = "1.35", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
```

**Using workspace dependencies:**

```toml
# crates/core/Cargo.toml
[package]
name = "myapp-core"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { workspace = true }
serde = { workspace = true }

# Internal dependency
myapp-api = { path = "../api" }
```

**Feature flags:**

```rust
// src/lib.rs
#[cfg(feature = "json")]
pub mod json_handler;

#[cfg(feature = "xml")]
pub mod xml_handler;

// Build with features
// cargo build --features json
// cargo build --features "json,xml"
```

---

# Follow Rust API Guidelines

> Adhere to Rust API Guidelines for consistent, idiomatic, and ergonomic APIs.

## Rules

- Use `snake_case` for functions, variables, modules; `CamelCase` for types
- Name getters without `get_` prefix (`.name()` not `.get_name()`)
- Use `_mut` suffix for mutable variants (`.iter()` and `.iter_mut()`)
- Return borrowed data from getters, not owned clones
- Implement common traits: `Debug`, `Clone`, `Default`, `PartialEq`
- Use `IntoIterator` for types that can be iterated
- Accept `impl Trait` or generics for flexibility in parameters

## Example

```rust
// Bad: non-idiomatic naming
pub struct UserData {
    user_id: u64,
    user_name: String,
}

impl UserData {
    pub fn get_name(&self) -> String {
        self.user_name.clone() // Unnecessary clone
    }

    pub fn GetId(&self) -> u64 { // Wrong case
        self.user_id
    }
}

// Good: idiomatic naming and borrowing
pub struct User {
    id: u64,
    name: String,
}

impl User {
    pub fn new(id: u64, name: String) -> Self {
        Self { id, name }
    }

    // Getter without get_ prefix
    pub fn name(&self) -> &str {
        &self.name // Return borrowed data
    }

    pub fn id(&self) -> u64 {
        self.id
    }
}

// Implement common traits
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Point {
    pub x: i32,
    pub y: i32,
}

impl Default for Point {
    fn default() -> Self {
        Self { x: 0, y: 0 }
    }
}

// Mutable and immutable variants
pub struct Container {
    items: Vec<String>,
}

impl Container {
    pub fn iter(&self) -> impl Iterator<Item = &String> {
        self.items.iter()
    }

    pub fn iter_mut(&mut self) -> impl Iterator<Item = &mut String> {
        self.items.iter_mut()
    }
}

// Accept impl Trait for flexibility
pub fn process_items(items: impl IntoIterator<Item = String>) {
    for item in items {
        println!("{}", item);
    }
}

// Can be called with Vec, array, iterator, etc.
process_items(vec!["a".to_string(), "b".to_string()]);
process_items(["a".to_string(), "b".to_string()]);

// Builder pattern for complex construction
pub struct Config {
    host: String,
    port: u16,
    timeout: Duration,
}

impl Config {
    pub fn builder() -> ConfigBuilder {
        ConfigBuilder::default()
    }
}

pub struct ConfigBuilder {
    host: String,
    port: u16,
    timeout: Duration,
}

impl Default for ConfigBuilder {
    fn default() -> Self {
        Self {
            host: "localhost".to_string(),
            port: 8080,
            timeout: Duration::from_secs(30),
        }
    }
}

impl ConfigBuilder {
    pub fn host(mut self, host: impl Into<String>) -> Self {
        self.host = host.into();
        self
    }

    pub fn port(mut self, port: u16) -> Self {
        self.port = port;
        self
    }

    pub fn build(self) -> Config {
        Config {
            host: self.host,
            port: self.port,
            timeout: self.timeout,
        }
    }
}

// Usage
let config = Config::builder()
    .host("example.com")
    .port(443)
    .build();
```

---

# Use rustfmt and clippy

> Run rustfmt for consistent formatting and clippy for catching common mistakes and suggesting improvements.

## Rules

- Run `cargo fmt` before every commit
- Configure rustfmt in `rustfmt.toml` or `.rustfmt.toml`
- Run `cargo clippy` regularly and fix warnings
- Enable clippy in CI/CD pipelines
- Use `#[allow(clippy::lint_name)]` sparingly with justification
- Configure clippy lints in `Cargo.toml` or `clippy.toml`
- Aim for zero clippy warnings in production code

## Example

**rustfmt.toml:**

```toml
edition = "2021"
max_width = 100
tab_spaces = 4
newline_style = "Unix"
use_small_heuristics = "Default"
```

**Cargo.toml - Clippy configuration:**

```toml
[lints.clippy]
# Deny common mistakes
unwrap_used = "deny"
expect_used = "warn"
panic = "deny"

# Pedantic lints
pedantic = "warn"
nursery = "warn"

# Allow some pedantic lints
module_name_repetitions = "allow"
```

```rust
// Run cargo fmt
// $ cargo fmt

// Run clippy
// $ cargo clippy

// Run clippy with all targets
// $ cargo clippy --all-targets --all-features

// Fix warnings automatically (where possible)
// $ cargo clippy --fix

// CI/CD integration
// $ cargo fmt -- --check  # Fails if not formatted
// $ cargo clippy -- -D warnings  # Treat warnings as errors
```

**Clippy examples:**

```rust
// Clippy warning: use of unwrap
let value = some_option.unwrap(); // Warning: avoid unwrap

// Better: handle the Option
let value = some_option.unwrap_or_default();
// Or use pattern matching
let value = match some_option {
    Some(v) => v,
    None => return Err(Error::MissingValue),
};

// Clippy warning: redundant clone
let s = String::from("hello");
let s2 = s.clone(); // Warning if s is not used after

// Better: move instead of clone
let s2 = s;

// Clippy warning: needless borrow
fn print_str(s: &str) {
    println!("{}", s);
}
print_str(&"hello"); // Warning: &str literal doesn't need &

// Better:
print_str("hello");

// Allow clippy lint with justification
#[allow(clippy::too_many_arguments)]
fn complex_function(
    arg1: u32, arg2: u32, arg3: u32,
    arg4: u32, arg5: u32, arg6: u32,
    arg7: u32, arg8: u32,
) {
    // Justification: Required for backward compatibility
}

// Clippy suggestion: use matches! macro
if let Some(42) = some_value {
    true
} else {
    false
}

// Better:
matches!(some_value, Some(42))

// Clippy suggestion: use if let instead of match
match some_option {
    Some(value) => process(value),
    None => {}
}

// Better:
if let Some(value) = some_option {
    process(value);
}
```

**Common clippy lints:**

- `unwrap_used`: Avoid unwrap() in production
- `expect_used`: Prefer proper error handling
- `panic`: Avoid panic!() in libraries
- `todo`: Remove TODO markers before release
- `dbg_macro`: Remove debug prints
- `print_stdout`: Avoid println! in libraries

---

# Write Comprehensive Tests

> Write unit tests, integration tests, and documentation tests to ensure code correctness and maintainability.

## Rules

- Write unit tests in the same file using `#[cfg(test)]` module
- Put integration tests in `tests/` directory
- Use `#[test]` attribute for test functions
- Use `assert!`, `assert_eq!`, and `assert_ne!` for assertions
- Test error cases with `#[should_panic]` or `Result<(), Error>`
- Write documentation tests in doc comments
- Use `cargo test` to run all tests

## Example

```rust
// src/calculator.rs
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

pub fn divide(a: i32, b: i32) -> Result<i32, String> {
    if b == 0 {
        Err("Division by zero".to_string())
    } else {
        Ok(a / b)
    }
}

// Unit tests in same file
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(2, 3), 5);
        assert_eq!(add(-1, 1), 0);
        assert_eq!(add(0, 0), 0);
    }

    #[test]
    fn test_divide_success() {
        assert_eq!(divide(10, 2).unwrap(), 5);
        assert_eq!(divide(0, 5).unwrap(), 0);
    }

    #[test]
    fn test_divide_by_zero() {
        assert!(divide(10, 0).is_err());
    }

    // Alternative: test with Result
    #[test]
    fn test_divide_result() -> Result<(), String> {
        assert_eq!(divide(10, 2)?, 5);
        Ok(())
    }

    // Test that should panic
    #[test]
    #[should_panic(expected = "Division by zero")]
    fn test_panics() {
        divide(10, 0).unwrap();
    }

    // Ignored test (run with --ignored)
    #[test]
    #[ignore]
    fn expensive_test() {
        // Long-running test
    }
}
```

**Integration tests:**

```rust
// tests/integration_test.rs
use myapp::Calculator;

#[test]
fn test_calculator_integration() {
    let calc = Calculator::new();
    assert_eq!(calc.compute("2 + 3"), 5);
}

// Test helper module
mod common;

#[test]
fn test_with_helpers() {
    let data = common::setup();
    assert!(data.is_valid());
}
```

**Documentation tests:**

````rust
/// Adds two numbers together.
///
/// # Examples
///
/// ```
/// use myapp::add;
///
/// assert_eq!(add(2, 3), 5);
/// ```
///
/// # Panics
///
/// This function doesn't panic.
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

/// Divides two numbers.
///
/// # Errors
///
/// Returns an error if `b` is zero.
///
/// ```
/// use myapp::divide;
///
/// assert!(divide(10, 2).is_ok());
/// assert!(divide(10, 0).is_err());
/// ```
pub fn divide(a: i32, b: i32) -> Result<i32, Error> {
    if b == 0 {
        return Err(Error::DivisionByZero);
    }
    Ok(a / b)
}
````

**Test organization:**

```rust
// Use test fixtures
#[cfg(test)]
mod tests {
    use super::*;

    fn setup() -> TestData {
        TestData {
            users: vec![
                User::new(1, "Alice"),
                User::new(2, "Bob"),
            ],
        }
    }

    #[test]
    fn test_with_fixture() {
        let data = setup();
        assert_eq!(data.users.len(), 2);
    }
}
```

**Running tests:**

```bash
# Run all tests
cargo test

# Run specific test
cargo test test_add

# Run tests with output
cargo test -- --nocapture

# Run ignored tests
cargo test -- --ignored

# Run tests with specific thread count
cargo test -- --test-threads=1

# Run doc tests only
cargo test --doc
```

---

# Use Traits for Shared Behavior

> Define traits to specify shared behavior and enable polymorphism through trait objects and generics.

## Rules

- Use traits to define shared interfaces across types
- Implement standard library traits (`Debug`, `Clone`, `Display`, etc.)
- Use trait bounds to constrain generic types
- Prefer trait bounds over trait objects when performance matters
- Use `dyn Trait` for trait objects with dynamic dispatch
- Implement custom traits for domain-specific behavior
- Use associated types in traits for type-level programming

## Example

```rust
// Define a custom trait
pub trait Summary {
    fn summarize(&self) -> String;

    // Default implementation
    fn preview(&self) -> String {
        format!("{}...", &self.summarize()[..50])
    }
}

// Implement trait for types
pub struct Article {
    pub title: String,
    pub content: String,
}

impl Summary for Article {
    fn summarize(&self) -> String {
        format!("{}: {}", self.title, self.content)
    }
}

pub struct Tweet {
    pub username: String,
    pub content: String,
}

impl Summary for Tweet {
    fn summarize(&self) -> String {
        format!("@{}: {}", self.username, self.content)
    }

    // Override default implementation
    fn preview(&self) -> String {
        format!("@{}...", self.username)
    }
}

// Function with trait bound
fn print_summary<T: Summary>(item: &T) {
    println!("{}", item.summarize());
}

// Multiple trait bounds
fn process<T: Summary + Clone>(item: &T) {
    let copy = item.clone();
    println!("{}", copy.summarize());
}

// Where clause for complex bounds
fn complex_function<T, U>(t: &T, u: &U)
where
    T: Summary + Clone,
    U: Summary + Display,
{
    // Function body
}

// Trait objects for dynamic dispatch
fn print_summaries(items: Vec<Box<dyn Summary>>) {
    for item in items {
        println!("{}", item.summarize());
    }
}

// Usage with trait objects
let summaries: Vec<Box<dyn Summary>> = vec![
    Box::new(Article {
        title: "News".to_string(),
        content: "Content".to_string(),
    }),
    Box::new(Tweet {
        username: "user".to_string(),
        content: "Tweet".to_string(),
    }),
];
print_summaries(summaries);

// Associated types in traits
pub trait Iterator {
    type Item;

    fn next(&mut self) -> Option<Self::Item>;
}

pub struct Counter {
    count: u32,
}

impl Iterator for Counter {
    type Item = u32;

    fn next(&mut self) -> Option<Self::Item> {
        self.count += 1;
        Some(self.count)
    }
}

// Derive common traits
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Point {
    x: i32,
    y: i32,
}

// Implement Display manually
use std::fmt;

impl fmt::Display for Point {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "({}, {})", self.x, self.y)
    }
}

// Trait with associated functions
pub trait Factory {
    fn create() -> Self;
}

impl Factory for Point {
    fn create() -> Self {
        Point { x: 0, y: 0 }
    }
}

// Usage
let point = Point::create();
```

---

# Prefer Iterators Over Loops

> Use iterator methods and functional patterns instead of manual loops for more concise and often faster code.

## Rules

- Use iterator methods (`.map()`, `.filter()`, `.fold()`) over for loops
- Chain iterator methods for complex transformations
- Iterators are zero-cost abstractions (compile to same code as loops)
- Use `.collect()` to consume iterators into collections
- Use `.iter()` for borrowing, `.into_iter()` for consuming
- Avoid `.collect()` when not needed; iterators are lazy
- Use iterator adapters for efficient data processing

## Example

```rust
// Bad: manual loop
let numbers = vec![1, 2, 3, 4, 5];
let mut doubled = Vec::new();
for n in &numbers {
    doubled.push(n * 2);
}

// Good: iterator map
let doubled: Vec<_> = numbers.iter()
    .map(|n| n * 2)
    .collect();

// Bad: manual filtering and summing
let mut sum = 0;
for n in &numbers {
    if n % 2 == 0 {
        sum += n;
    }
}

// Good: iterator chain
let sum: i32 = numbers.iter()
    .filter(|n| *n % 2 == 0)
    .sum();

// Complex transformations with iterator chains
let result: Vec<_> = vec!["1", "2", "three", "4"]
    .iter()
    .filter_map(|s| s.parse::<i32>().ok())  // Parse, skip errors
    .map(|n| n * 2)                          // Double
    .filter(|n| n > &2)                      // Keep > 2
    .collect();

// fold for custom accumulation
let sum = numbers.iter().fold(0, |acc, x| acc + x);

// find for early termination
let first_even = numbers.iter().find(|&&n| n % 2 == 0);

// any/all for boolean checks
let has_even = numbers.iter().any(|&n| n % 2 == 0);
let all_positive = numbers.iter().all(|&n| n > 0);

// Borrowing vs consuming
let vec = vec![1, 2, 3];

// iter() - borrows elements
for item in vec.iter() {
    println!("{}", item); // &i32
}
// vec still valid here

// into_iter() - consumes vec
for item in vec.into_iter() {
    println!("{}", item); // i32
}
// vec moved, no longer valid

// Avoid unnecessary collect
// Bad: intermediate collection
let result = numbers.iter()
    .map(|n| n * 2)
    .collect::<Vec<_>>();  // Allocates Vec
let sum: i32 = result.iter().sum();

// Good: stay lazy
let sum: i32 = numbers.iter()
    .map(|n| n * 2)
    .sum();  // No intermediate allocation

// Efficient processing with take/skip
let first_five: Vec<_> = (1..)
    .take(5)
    .collect();

let skip_first: Vec<_> = numbers.iter()
    .skip(2)
    .collect();

// enumerate for indices
for (index, value) in numbers.iter().enumerate() {
    println!("{}: {}", index, value);
}

// zip for parallel iteration
let names = vec!["Alice", "Bob"];
let ages = vec![30, 25];

for (name, age) in names.iter().zip(ages.iter()) {
    println!("{} is {}", name, age);
}

// Custom iterators
struct Counter {
    count: u32,
}

impl Iterator for Counter {
    type Item = u32;

    fn next(&mut self) -> Option<Self::Item> {
        self.count += 1;
        if self.count <= 5 {
            Some(self.count)
        } else {
            None
        }
    }
}

let sum: u32 = Counter { count: 0 }.sum();
```

---

# Use Pattern Matching

> Leverage Rust's powerful pattern matching for expressive, safe, and exhaustive conditional logic.

## Rules

- Use `match` for exhaustive pattern matching on enums
- Use `if let` for matching single patterns
- Use `while let` for loops with pattern matching
- Use `let` bindings with patterns for destructuring
- Use `@` bindings to capture values while matching
- Use guards for additional conditions in match arms
- Compiler enforces exhaustiveness; handle all cases

## Example

```rust
// Exhaustive enum matching
enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
    ChangeColor(u8, u8, u8),
}

fn process_message(msg: Message) {
    match msg {
        Message::Quit => println!("Quit"),
        Message::Move { x, y } => println!("Move to ({}, {})", x, y),
        Message::Write(text) => println!("Write: {}", text),
        Message::ChangeColor(r, g, b) => println!("Color: rgb({}, {}, {})", r, g, b),
    }
    // Compiler ensures all variants handled
}

// Match with Option
fn divide(a: i32, b: i32) -> Option<i32> {
    if b == 0 {
        None
    } else {
        Some(a / b)
    }
}

match divide(10, 2) {
    Some(result) => println!("Result: {}", result),
    None => println!("Cannot divide by zero"),
}

// if let for single pattern
if let Some(result) = divide(10, 2) {
    println!("Result: {}", result);
}

// while let for loops
let mut stack = vec![1, 2, 3];
while let Some(top) = stack.pop() {
    println!("{}", top);
}

// Destructuring in let bindings
let point = (3, 5);
let (x, y) = point;

let user = User {
    name: "Alice".to_string(),
    age: 30,
};
let User { name, age } = user;

// Match with guards
fn categorize(n: i32) -> &'static str {
    match n {
        n if n < 0 => "negative",
        0 => "zero",
        n if n < 10 => "small positive",
        n if n < 100 => "medium positive",
        _ => "large positive",
    }
}

// @ bindings to capture and match
enum Status {
    Active { user_id: u64 },
    Inactive,
}

match status {
    Status::Active { user_id: id @ 100..=999 } => {
        println!("VIP user {}", id);
    }
    Status::Active { user_id } => {
        println!("Regular user {}", user_id);
    }
    Status::Inactive => println!("Inactive"),
}

// Match with references
let reference = &Some(5);
match reference {
    Some(val) => println!("Got: {}", val),
    None => println!("None"),
}

// Destructuring references
match reference {
    &Some(val) => println!("Got: {}", val),
    &None => println!("None"),
}

// Multiple patterns with |
match number {
    1 | 2 | 3 => println!("Small"),
    4 | 5 | 6 => println!("Medium"),
    _ => println!("Large"),
}

// Range patterns
match age {
    0..=12 => println!("Child"),
    13..=19 => println!("Teenager"),
    20..=65 => println!("Adult"),
    _ => println!("Senior"),
}

// Nested patterns
match event {
    Event::Message(Message::Write(text)) => println!("Write: {}", text),
    Event::Message(_) => println!("Other message"),
    Event::Quit => println!("Quit"),
}

// Ignoring values
let (x, _, z) = (1, 2, 3); // Ignore middle value
let (first, .., last) = (1, 2, 3, 4, 5); // Ignore middle values

match some_value {
    Some(_) => println!("Has value"),
    None => println!("None"),
}

// Match Result
match file_operation() {
    Ok(data) => process(data),
    Err(e) => eprintln!("Error: {}", e),
}
```

---

# Avoid unwrap in Production

> Never use `.unwrap()` or `.expect()` in production code; handle errors explicitly to prevent panics.

## Rules

- Use `.unwrap()` only in examples, tests, or prototypes
- Replace `.unwrap()` with proper error handling using `?` operator
- Use `.unwrap_or()`, `.unwrap_or_else()`, or `.unwrap_or_default()` for safe defaults
- Use pattern matching to handle `Option` and `Result` explicitly
- Use `.expect()` only when failure is truly impossible (with clear message)
- Enable clippy lint `unwrap_used` to catch unwrap usage
- Return `Result` from functions that can fail

## Example

```rust
// Bad: unwrap panics on None or Err
fn process_data(path: &str) -> String {
    let contents = std::fs::read_to_string(path).unwrap(); // Panics on error!
    let data = parse_data(&contents).unwrap(); // Panics on error!
    data.name
}

// Good: propagate errors with ?
fn process_data(path: &str) -> Result<String, Box<dyn std::error::Error>> {
    let contents = std::fs::read_to_string(path)?;
    let data = parse_data(&contents)?;
    Ok(data.name)
}

// Good: provide safe defaults
fn get_config_value(key: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| "default".to_string())
}

fn get_timeout() -> u64 {
    std::env::var("TIMEOUT")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(30) // Safe default
}

// Good: pattern matching for explicit handling
fn find_user(id: u64) -> Option<User> {
    // ...
}

match find_user(42) {
    Some(user) => println!("Found: {}", user.name),
    None => println!("User not found"),
}

// Or with if let
if let Some(user) = find_user(42) {
    println!("Found: {}", user.name);
} else {
    println!("User not found");
}

// Acceptable: expect with clear message when failure is impossible
fn main() {
    let config_path = std::env::var("CONFIG_PATH")
        .expect("CONFIG_PATH must be set"); // OK: clear requirement

    // Parse at compile time - can't fail at runtime
    let addr: SocketAddr = "127.0.0.1:8080"
        .parse()
        .expect("Hard-coded address is valid");
}

// Bad: chaining unwraps
let value = map.get("key").unwrap().parse::<i32>().unwrap();

// Good: early returns with ?
fn get_value(map: &HashMap<String, String>, key: &str) -> Result<i32, Error> {
    let value_str = map.get(key).ok_or(Error::KeyNotFound)?;
    let value = value_str.parse()?;
    Ok(value)
}

// Good: use ok_or to convert Option to Result
fn lookup(key: &str) -> Result<String, Error> {
    database
        .get(key)
        .ok_or(Error::NotFound)?
        .clone()
}

// Safe alternatives to unwrap
// unwrap_or - provide default value
let value = some_option.unwrap_or(0);

// unwrap_or_else - compute default lazily
let value = some_option.unwrap_or_else(|| expensive_computation());

// unwrap_or_default - use Default trait
let vec: Vec<i32> = some_option.unwrap_or_default();

// Cargo.toml - enable clippy lint
[lints.clippy]
unwrap_used = "deny"
expect_used = "warn"

// Handle multiple Results
fn load_config() -> Result<Config, Error> {
    let host = std::env::var("HOST")?;
    let port = std::env::var("PORT")?.parse()?;
    let db_url = std::env::var("DATABASE_URL")?;

    Ok(Config { host, port, db_url })
}
```

---

# Use Smart Pointers Appropriately

> Use `Box`, `Rc`, `Arc`, `RefCell`, and other smart pointers when ownership patterns require indirection or shared ownership.

## Rules

- Use `Box<T>` for heap allocation and recursive types
- Use `Rc<T>` for shared ownership in single-threaded contexts
- Use `Arc<T>` for shared ownership across threads
- Use `RefCell<T>` for interior mutability with runtime borrow checking
- Use `Mutex<T>` or `RwLock<T>` for thread-safe interior mutability
- Combine `Arc<Mutex<T>>` for shared mutable state across threads
- Avoid smart pointers when simple references suffice

## Example

```rust
use std::rc::Rc;
use std::sync::{Arc, Mutex};
use std::cell::RefCell;

// Box for heap allocation
fn box_example() {
    // Large data on heap instead of stack
    let large_data = Box::new([0u8; 1_000_000]);

    // Recursive types require indirection
    enum List {
        Cons(i32, Box<List>),
        Nil,
    }

    let list = List::Cons(1, Box::new(List::Cons(2, Box::new(List::Nil))));
}

// Rc for shared ownership (single-threaded)
fn rc_example() {
    let data = Rc::new(vec![1, 2, 3]);

    let reference1 = Rc::clone(&data); // Increment reference count
    let reference2 = Rc::clone(&data);

    println!("Reference count: {}", Rc::strong_count(&data)); // 3

    // All references can read the data
    println!("{:?}", reference1);
    println!("{:?}", reference2);
} // When last Rc drops, data is deallocated

// Arc for shared ownership (multi-threaded)
use std::thread;

fn arc_example() {
    let data = Arc::new(vec![1, 2, 3]);

    let mut handles = vec![];

    for _ in 0..3 {
        let data_clone = Arc::clone(&data);
        let handle = thread::spawn(move || {
            println!("{:?}", data_clone);
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }
}

// RefCell for interior mutability (single-threaded)
fn refcell_example() {
    let data = RefCell::new(vec![1, 2, 3]);

    // Borrow mutably at runtime
    data.borrow_mut().push(4);

    // Borrow immutably
    println!("{:?}", data.borrow());

    // Runtime panic if borrowing rules violated
    // let mut_ref = data.borrow_mut();
    // let immut_ref = data.borrow(); // PANIC: already borrowed mutably
}

// Arc<Mutex<T>> for shared mutable state across threads
fn shared_state() {
    let counter = Arc::new(Mutex::new(0));
    let mut handles = vec![];

    for _ in 0..10 {
        let counter_clone = Arc::clone(&counter);
        let handle = thread::spawn(move || {
            let mut num = counter_clone.lock().unwrap();
            *num += 1;
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }

    println!("Result: {}", *counter.lock().unwrap()); // 10
}

// RwLock for read-heavy workloads
fn rwlock_example() {
    let data = Arc::new(RwLock::new(vec![1, 2, 3]));

    // Multiple readers
    let data1 = Arc::clone(&data);
    let handle1 = thread::spawn(move || {
        let vec = data1.read().unwrap();
        println!("{:?}", vec);
    });

    let data2 = Arc::clone(&data);
    let handle2 = thread::spawn(move || {
        let vec = data2.read().unwrap();
        println!("{:?}", vec);
    });

    // One writer (exclusive)
    let data3 = Arc::clone(&data);
    let handle3 = thread::spawn(move || {
        let mut vec = data3.write().unwrap();
        vec.push(4);
    });

    handle1.join().unwrap();
    handle2.join().unwrap();
    handle3.join().unwrap();
}

// When NOT to use smart pointers
// Bad: unnecessary Box
fn bad_example(data: Box<Vec<i32>>) {
    // Just use &Vec<i32> or &[i32]
}

// Good: simple reference
fn good_example(data: &[i32]) {
    // More flexible, no heap allocation needed
}

// Combining smart pointers
struct Node {
    data: i32,
    children: RefCell<Vec<Rc<Node>>>,
}

impl Node {
    fn new(data: i32) -> Rc<Self> {
        Rc::new(Node {
            data,
            children: RefCell::new(vec![]),
        })
    }

    fn add_child(&self, child: Rc<Node>) {
        self.children.borrow_mut().push(child);
    }
}
```

---

# Use async/await for Concurrency

> Use async/await with an async runtime (Tokio, async-std) for efficient concurrent I/O operations.

## Rules

- Use `async fn` for asynchronous functions
- Use `.await` to wait for async operations
- Use Tokio or async-std as your async runtime
- Use `tokio::spawn` to run tasks concurrently
- Use `tokio::select!` for concurrent operations with cancellation
- Avoid blocking operations in async code; use `spawn_blocking` instead
- Use `async` blocks for inline asynchronous code

## Example

```rust
use tokio::time::{sleep, Duration};
use reqwest;

// Basic async function
async fn fetch_url(url: &str) -> Result<String, reqwest::Error> {
    let response = reqwest::get(url).await?;
    let body = response.text().await?;
    Ok(body)
}

// Async main with Tokio
#[tokio::main]
async fn main() {
    match fetch_url("https://example.com").await {
        Ok(body) => println!("Body length: {}", body.len()),
        Err(e) => eprintln!("Error: {}", e),
    }
}

// Concurrent tasks with spawn
async fn concurrent_fetches() {
    let handle1 = tokio::spawn(async {
        fetch_url("https://example.com").await
    });

    let handle2 = tokio::spawn(async {
        fetch_url("https://example.org").await
    });

    // Wait for both to complete
    let (result1, result2) = tokio::join!(handle1, handle2);

    println!("Results: {:?}, {:?}", result1, result2);
}

// Select for racing operations
use tokio::select;

async fn with_timeout() {
    select! {
        result = fetch_url("https://example.com") => {
            println!("Got result: {:?}", result);
        }
        _ = sleep(Duration::from_secs(5)) => {
            println!("Timeout!");
        }
    }
}

// Spawn multiple tasks
async fn process_urls(urls: Vec<String>) {
    let mut handles = vec![];

    for url in urls {
        let handle = tokio::spawn(async move {
            fetch_url(&url).await
        });
        handles.push(handle);
    }

    // Wait for all
    for handle in handles {
        match handle.await {
            Ok(Ok(body)) => println!("Success: {} bytes", body.len()),
            Ok(Err(e)) => eprintln!("Fetch error: {}", e),
            Err(e) => eprintln!("Task error: {}", e),
        }
    }
}

// Use spawn_blocking for CPU-intensive work
async fn cpu_intensive_task(data: Vec<u8>) -> Vec<u8> {
    tokio::task::spawn_blocking(move || {
        // Blocking/CPU-intensive operation
        expensive_computation(data)
    })
    .await
    .unwrap()
}

// Async blocks
async fn async_blocks() {
    let future = async {
        sleep(Duration::from_secs(1)).await;
        42
    };

    let result = future.await;
    println!("Result: {}", result);
}

// Async traits (requires async-trait crate)
use async_trait::async_trait;

#[async_trait]
trait AsyncRepository {
    async fn get_user(&self, id: u64) -> Result<User, Error>;
    async fn save_user(&self, user: &User) -> Result<(), Error>;
}

struct PostgresRepo {
    pool: sqlx::PgPool,
}

#[async_trait]
impl AsyncRepository for PostgresRepo {
    async fn get_user(&self, id: u64) -> Result<User, Error> {
        let user = sqlx::query_as!(
            User,
            "SELECT * FROM users WHERE id = $1",
            id as i64
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(user)
    }

    async fn save_user(&self, user: &User) -> Result<(), Error> {
        sqlx::query!(
            "INSERT INTO users (name, email) VALUES ($1, $2)",
            user.name,
            user.email
        )
        .execute(&self.pool)
        .await?;

        Ok(())
    }
}

// Async iterators with streams
use tokio_stream::StreamExt;

async fn process_stream() {
    let mut stream = tokio_stream::iter(vec![1, 2, 3, 4, 5]);

    while let Some(value) = stream.next().await {
        println!("Got: {}", value);
    }
}

// Graceful shutdown
async fn server_with_shutdown() {
    let (tx, mut rx) = tokio::sync::oneshot::channel();

    let server_task = tokio::spawn(async move {
        loop {
            select! {
                _ = &mut rx => {
                    println!("Shutting down...");
                    break;
                }
                _ = handle_request() => {}
            }
        }
    });

    // Signal shutdown after some condition
    sleep(Duration::from_secs(10)).await;
    let _ = tx.send(());

    server_task.await.unwrap();
}
```

**Cargo.toml:**

```toml
[dependencies]
tokio = { version = "1", features = ["full"] }
reqwest = "0.11"
async-trait = "0.1"
tokio-stream = "0.1"
```

---

# Implement Error Types Properly

> Create custom error types with `thiserror` or `anyhow` for clear, composable error handling.

## Rules

- Use `thiserror` for library error types
- Use `anyhow` for application error handling
- Implement `std::error::Error` trait for custom errors
- Use `#[error]` attribute with `thiserror` for display messages
- Use `#[from]` attribute for automatic error conversions
- Provide context with error chains using `.context()`
- Make errors actionable by including relevant information

## Example

```rust
// Using thiserror for library errors
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ConfigError {
    #[error("Configuration file not found: {path}")]
    FileNotFound { path: String },

    #[error("Invalid configuration: {0}")]
    InvalidConfig(String),

    #[error("Parse error at line {line}: {message}")]
    ParseError { line: usize, message: String },

    #[error(transparent)]
    IoError(#[from] std::io::Error),

    #[error(transparent)]
    ParseIntError(#[from] std::num::ParseIntError),
}

pub fn load_config(path: &str) -> Result<Config, ConfigError> {
    let contents = std::fs::read_to_string(path)
        .map_err(|_| ConfigError::FileNotFound {
            path: path.to_string(),
        })?;

    parse_config(&contents)
}

fn parse_config(contents: &str) -> Result<Config, ConfigError> {
    if contents.is_empty() {
        return Err(ConfigError::InvalidConfig(
            "Config file is empty".to_string(),
        ));
    }

    // Parse and return config...
    Ok(Config::default())
}

// Using anyhow for applications
use anyhow::{Context, Result};

fn run_app() -> Result<()> {
    let config = load_config("config.toml")
        .context("Failed to load configuration")?;

    let connection = connect_database(&config.db_url)
        .context("Failed to connect to database")?;

    process_data(connection)
        .context("Failed to process data")?;

    Ok(())
}

fn main() {
    if let Err(e) = run_app() {
        eprintln!("Error: {:?}", e);
        // Prints full error chain:
        // Error: Failed to load configuration
        // Caused by:
        //     Configuration file not found: config.toml
        std::process::exit(1);
    }
}

// Custom error with context
#[derive(Error, Debug)]
pub enum DatabaseError {
    #[error("Connection failed: {0}")]
    ConnectionFailed(String),

    #[error("Query failed: {query}")]
    QueryFailed {
        query: String,
        #[source]
        source: sqlx::Error,
    },

    #[error("User not found: {id}")]
    UserNotFound { id: u64 },
}

pub async fn get_user(pool: &PgPool, id: u64) -> Result<User, DatabaseError> {
    sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id as i64)
        .fetch_one(pool)
        .await
        .map_err(|e| DatabaseError::QueryFailed {
            query: format!("SELECT * FROM users WHERE id = {}", id),
            source: e,
        })?
        .ok_or(DatabaseError::UserNotFound { id })
}

// Error with multiple causes
#[derive(Error, Debug)]
pub enum AppError {
    #[error("Configuration error")]
    Config(#[from] ConfigError),

    #[error("Database error")]
    Database(#[from] DatabaseError),

    #[error("Network error")]
    Network(#[from] reqwest::Error),

    #[error("IO error")]
    Io(#[from] std::io::Error),
}

// Combining errors in application
fn complex_operation() -> Result<(), AppError> {
    // Errors automatically converted to AppError
    let config = load_config("config.toml")?;
    let user = get_user(&pool, 42).await?;
    let response = reqwest::get("https://api.example.com").await?;

    Ok(())
}

// Manual error implementation
#[derive(Debug)]
pub struct ValidationError {
    pub field: String,
    pub message: String,
}

impl std::fmt::Display for ValidationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Validation failed for {}: {}", self.field, self.message)
    }
}

impl std::error::Error for ValidationError {}

// Error with backtrace (nightly feature)
use std::backtrace::Backtrace;

#[derive(Debug)]
pub struct DetailedError {
    message: String,
    backtrace: Backtrace,
}

impl DetailedError {
    pub fn new(message: impl Into<String>) -> Self {
        Self {
            message: message.into(),
            backtrace: Backtrace::capture(),
        }
    }
}

impl std::fmt::Display for DetailedError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.message)
    }
}

impl std::error::Error for DetailedError {
    fn backtrace(&self) -> Option<&Backtrace> {
        Some(&self.backtrace)
    }
}
```

**Cargo.toml:**

```toml
[dependencies]
thiserror = "1.0"
anyhow = "1.0"
```

---

# Use Macros Sparingly

> Use macros only when functions and generics are insufficient; prefer simple, maintainable code over macro magic.

## Rules

- Use functions or generics first; macros as last resort
- Use declarative macros (`macro_rules!`) for simple patterns
- Use procedural macros for derive, attributes, and function-like macros
- Document macro inputs and outputs clearly
- Keep macros simple and focused on one task
- Use `cargo expand` to inspect macro expansions
- Test macros thoroughly with various inputs

## Example

```rust
// When NOT to use macros
// Bad: macro for simple function
macro_rules! add {
    ($a:expr, $b:expr) => {
        $a + $b
    };
}

// Good: just use a function
fn add(a: i32, b: i32) -> i32 {
    a + b
}

// When macros are appropriate
// Good: reducing boilerplate for similar code
macro_rules! impl_from_str {
    ($type:ty) => {
        impl std::str::FromStr for $type {
            type Err = String;

            fn from_str(s: &str) -> Result<Self, Self::Err> {
                s.parse().map_err(|e| format!("Parse error: {}", e))
            }
        }
    };
}

impl_from_str!(UserId);
impl_from_str!(OrderId);

// Declarative macro with repetition
macro_rules! vec_of_strings {
    ($($x:expr),* $(,)?) => {
        vec![$($x.to_string()),*]
    };
}

let strings = vec_of_strings!["hello", "world"];

// Pattern matching in macros
macro_rules! calculate {
    (add $a:expr, $b:expr) => {
        $a + $b
    };
    (sub $a:expr, $b:expr) => {
        $a - $b
    };
    (mul $a:expr, $b:expr) => {
        $a * $b
    };
}

let result = calculate!(add 10, 5);
let result = calculate!(mul 10, 5);

// Custom derive procedural macro
// In separate crate: my-derive
use proc_macro::TokenStream;
use quote::quote;
use syn;

#[proc_macro_derive(Builder)]
pub fn derive_builder(input: TokenStream) -> TokenStream {
    let input = syn::parse_macro_input!(input as syn::DeriveInput);
    let name = &input.ident;

    let expanded = quote! {
        impl #name {
            pub fn builder() -> #name Builder {
                #name Builder::default()
            }
        }
    };

    TokenStream::from(expanded)
}

// Usage
#[derive(Builder)]
struct User {
    name: String,
    age: u32,
}

let user = User::builder()
    .name("Alice".to_string())
    .age(30)
    .build();

// Attribute macro
#[proc_macro_attribute]
pub fn log_calls(attr: TokenStream, item: TokenStream) -> TokenStream {
    let input = syn::parse_macro_input!(item as syn::ItemFn);
    let name = &input.sig.ident;

    let expanded = quote! {
        #input

        // Log function calls
        println!("Calling {}", stringify!(#name));
    };

    TokenStream::from(expanded)
}

// Usage
#[log_calls]
fn my_function() {
    println!("Function body");
}

// Debugging macros
// Use cargo expand to see macro output
// $ cargo install cargo-expand
// $ cargo expand

// Testing macros
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_vec_of_strings() {
        let result = vec_of_strings!["a", "b", "c"];
        assert_eq!(result, vec!["a", "b", "c"]);
    }

    #[test]
    fn test_calculate_macro() {
        assert_eq!(calculate!(add 5, 3), 8);
        assert_eq!(calculate!(sub 10, 3), 7);
        assert_eq!(calculate!(mul 4, 5), 20);
    }
}

// Built-in macros to use
println!("Print with newline");
eprintln!("Print to stderr");
format!("Create formatted string: {}", value);
vec![1, 2, 3];
assert_eq!(a, b);
assert!(condition);
panic!("Unrecoverable error");
todo!("Not yet implemented");
unimplemented!("Function stub");
unreachable!("Should never reach here");
dbg!(variable); // Debug print

// Conditional compilation
#[cfg(target_os = "linux")]
fn platform_specific() {
    // Linux-specific code
}

#[cfg(test)]
mod tests {
    // Test-only code
}
```

**When to use macros:**

- Reducing repetitive boilerplate (derive macros)
- Domain-specific languages (DSLs)
- Conditional compilation
- Generating code at compile time

**When NOT to use macros:**

- Simple logic that functions can handle
- Type conversions (use traits)
- Code organization (use modules)
- Runtime behavior (use functions)

---

# Follow Module Organization

> Organize code into modules with clear visibility rules for maintainable, well-structured projects.

## Rules

- One module per file or use `mod.rs` for directories
- Use `pub` to export items from modules
- Use `pub(crate)` for crate-internal visibility
- Use `pub(super)` for parent-module visibility
- Organize modules by feature or domain, not by type
- Put unit tests in the same file with `#[cfg(test)]`
- Put integration tests in `tests/` directory

## Example

```
myapp/
├── Cargo.toml
├── src/
│   ├── main.rs
│   ├── lib.rs
│   ├── config/
│   │   ├── mod.rs       # or config.rs
│   │   └── parser.rs
│   ├── database/
│   │   ├── mod.rs
│   │   ├── postgres.rs
│   │   └── migrations.rs
│   ├── models/
│   │   ├── mod.rs
│   │   ├── user.rs
│   │   └── order.rs
│   └── api/
│       ├── mod.rs
│       ├── handlers.rs
│       └── middleware.rs
└── tests/
    ├── integration_test.rs
    └── common/
        └── mod.rs
```

**lib.rs - Crate root:**

```rust
// Public modules
pub mod config;
pub mod models;
pub mod api;

// Private module
mod database;

// Re-export commonly used items
pub use models::{User, Order};
pub use config::Config;

// Crate-internal utilities
pub(crate) mod utils;
```

**models/mod.rs:**

```rust
// Declare submodules
mod user;
mod order;

// Re-export public items
pub use user::User;
pub use order::Order;

// Module-private items
pub(super) fn internal_helper() {
    // Only visible to parent module
}
```

**models/user.rs:**

```rust
// Public struct
#[derive(Debug, Clone)]
pub struct User {
    pub id: u64,
    pub name: String,
    email: String,  // Private field
}

impl User {
    // Public constructor
    pub fn new(id: u64, name: String, email: String) -> Self {
        Self { id, name, email }
    }

    // Public method
    pub fn email(&self) -> &str {
        &self.email
    }

    // Crate-internal method
    pub(crate) fn validate(&self) -> bool {
        !self.name.is_empty() && self.email.contains('@')
    }

    // Private helper
    fn normalize_name(&mut self) {
        self.name = self.name.trim().to_string();
    }
}

// Unit tests in same file
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_user_creation() {
        let user = User::new(1, "Alice".to_string(), "alice@example.com".to_string());
        assert_eq!(user.name, "Alice");
    }

    #[test]
    fn test_validation() {
        let user = User::new(1, "Alice".to_string(), "alice@example.com".to_string());
        assert!(user.validate());
    }
}
```

**database/mod.rs:**

```rust
mod postgres;
mod migrations;

// Conditional compilation
#[cfg(feature = "postgres")]
pub use postgres::PostgresConnection;

#[cfg(feature = "sqlite")]
pub use sqlite::SqliteConnection;

// Trait for database abstraction
pub trait Database {
    fn connect(&self, url: &str) -> Result<Connection, Error>;
    fn execute(&self, query: &str) -> Result<(), Error>;
}
```

**config/mod.rs:**

```rust
mod parser;

use std::path::Path;

#[derive(Debug, Clone)]
pub struct Config {
    pub database_url: String,
    pub port: u16,
}

impl Config {
    pub fn from_file(path: impl AsRef<Path>) -> Result<Self, Error> {
        parser::parse_config_file(path)
    }

    pub(crate) fn validate(&self) -> Result<(), Error> {
        // Validation logic
        Ok(())
    }
}
```

**main.rs:**

```rust
use myapp::{Config, User, api};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Load config
    let config = Config::from_file("config.toml")?;

    // Start server
    api::start_server(config)?;

    Ok(())
}
```

**tests/integration_test.rs:**

```rust
// Integration test
use myapp::{Config, User};

#[test]
fn test_full_workflow() {
    let config = Config::from_file("test_config.toml").unwrap();
    let user = User::new(1, "Alice".to_string(), "alice@example.com".to_string());

    // Test full application workflow
    assert!(user.email().contains('@'));
}
```

**tests/common/mod.rs - Shared test utilities:**

```rust
// Helper functions for integration tests
pub fn setup_test_db() -> Database {
    // Setup code
}

pub fn teardown_test_db(db: Database) {
    // Cleanup code
}
```

**Visibility modifiers:**

```rust
pub fn public_function() {}           // Public to everyone
pub(crate) fn crate_function() {}     // Public within crate
pub(super) fn parent_function() {}    // Public to parent module
fn private_function() {}              // Private to this module

pub struct PublicStruct {
    pub public_field: i32,
    pub(crate) crate_field: i32,
    private_field: i32,
}
```

---

# Use Lifetimes When Necessary

> Add lifetime annotations when the compiler needs help understanding reference validity, but let lifetime elision work when possible.

## Rules

- Let the compiler infer lifetimes when possible (lifetime elision)
- Add explicit lifetimes when holding references in structs
- Use `'static` for references that live for the entire program
- Name lifetimes descriptively when there are multiple
- Understand the three lifetime elision rules
- Use lifetime bounds with generics when needed
- Keep lifetime relationships simple and understandable

## Example

```rust
// Lifetime elision - compiler infers lifetimes
// No annotation needed for simple cases
fn first_word(s: &str) -> &str {
    s.split_whitespace().next().unwrap_or("")
}

// Explicit lifetime when needed
// Multiple input lifetimes, unclear which output relates to
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}

// Struct with lifetime
struct User<'a> {
    name: &'a str,
    email: &'a str,
}

impl<'a> User<'a> {
    fn new(name: &'a str, email: &'a str) -> Self {
        Self { name, email }
    }

    // Method with lifetime
    fn name(&self) -> &str {
        self.name  // Elided lifetime: same as &'a str
    }
}

// Multiple lifetimes
struct Context<'a, 'b> {
    data: &'a str,
    config: &'b Config,
}

fn process<'a, 'b>(ctx: &Context<'a, 'b>) -> &'a str {
    ctx.data
}

// 'static lifetime - lives for entire program
const CONSTANT: &'static str = "I live forever";

fn get_static_str() -> &'static str {
    "This is a 'static str literal"
}

// Lifetime bounds with generics
fn process_data<'a, T>(data: &'a T) -> &'a T
where
    T: std::fmt::Debug,
{
    println!("{:?}", data);
    data
}

// Complex lifetime relationships
struct Parser<'a> {
    input: &'a str,
    position: usize,
}

impl<'a> Parser<'a> {
    fn new(input: &'a str) -> Self {
        Parser { input, position: 0 }
    }

    // Output lifetime tied to self
    fn peek(&self) -> Option<&'a str> {
        if self.position < self.input.len() {
            Some(&self.input[self.position..])
        } else {
            None
        }
    }
}

// Lifetime elision rules
// 1. Each reference parameter gets its own lifetime
// 2. If one input lifetime, it's assigned to all output lifetimes
// 3. If &self or &mut self, its lifetime is assigned to outputs

// Rule 1 & 2: one input lifetime
fn example1(s: &str) -> &str {  // Elided
    s
}
// Expands to:
fn example1_explicit<'a>(s: &'a str) -> &'a str {
    s
}

// Rule 3: self lifetime
impl User {
    fn name(&self) -> &str {  // Elided
        &self.name
    }
}
// Expands to:
impl User {
    fn name<'a>(&'a self) -> &'a str {
        &self.name
    }
}

// When explicit lifetimes are needed
// Different output lifetime relationships
fn choose<'a, 'b>(
    first: &'a str,
    _second: &'b str,
    use_first: bool,
) -> &'a str {
    // Output only related to first parameter
    if use_first {
        first
    } else {
        first  // Can't return second due to lifetime
    }
}

// Lifetime subtyping
fn parse_until<'a, 'b>(input: &'a str, delimiter: &'b str) -> &'a str
where
    'a: 'b,  // 'a outlives 'b
{
    // Implementation
    input
}

// Common lifetime errors
// Error: returning reference to local variable
fn dangle() -> &String {
    let s = String::from("hello");
    &s  // ERROR: s dropped here
}

// Fix: return owned value
fn no_dangle() -> String {
    let s = String::from("hello");
    s  // OK: ownership transferred
}

// Error: conflicting lifetimes
fn problematic<'a>(x: &'a str, y: &str) -> &'a str {
    // Cannot mix 'a and elided lifetime
    if x.len() > y.len() {
        x
    } else {
        y  // ERROR: y has different lifetime
    }
}

// Fix: same lifetime for both
fn fixed<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y  // OK: both have 'a
    }
}
```

---

# Prefer &str Over String for Parameters

> Accept `&str` in function parameters instead of `String` or `&String` for maximum flexibility.

## Rules

- Use `&str` for function parameters that only read strings
- Use `String` only when the function needs ownership
- Use `&mut String` when the function needs to modify the string
- Never use `&String` as a parameter (use `&str` instead)
- Use `impl AsRef<str>` or `impl Into<String>` for even more flexibility
- Return `String` for owned data, `&str` for borrowed data
- Use `.as_str()` to convert `&String` to `&str`

## Example

```rust
// Bad: takes String (requires ownership)
fn print_message(msg: String) {
    println!("{}", msg);
}
// Caller must give up ownership or clone
let message = String::from("hello");
print_message(message);  // message moved
// print_message(message);  // ERROR: already moved

// Bad: takes &String (unnecessarily specific)
fn print_message(msg: &String) {
    println!("{}", msg);
}
// Can't call with &str
let msg = "hello";
// print_message(&msg);  // ERROR: expected &String

// Good: takes &str (most flexible)
fn print_message(msg: &str) {
    println!("{}", msg);
}
// Works with both &str and &String
print_message("hello");                     // &str literal
print_message(&String::from("hello"));      // &String
print_message(&message);                    // &String
let s = String::from("hello");
print_message(&s);                          // &String
print_message(s.as_str());                  // &str

// When to use String parameter
fn take_ownership(s: String) -> String {
    // Function needs ownership to modify or store
    format!("{} world", s)
}

// When to use &mut String
fn append_world(s: &mut String) {
    s.push_str(" world");
}

// Even more flexible: accept anything string-like
fn print_flexible(msg: impl AsRef<str>) {
    println!("{}", msg.as_ref());
}

print_flexible("hello");               // &str
print_flexible(String::from("hello")); // String
print_flexible(&String::from("hello"));// &String

// For functions that need to store the string
fn store_message(msg: impl Into<String>) -> StoredMessage {
    StoredMessage {
        content: msg.into(),
    }
}

store_message("hello");               // &str -> String
store_message(String::from("hello")); // String

// Return types
// Return &str when returning a reference
fn get_name<'a>(user: &'a User) -> &'a str {
    &user.name
}

// Return String when returning owned data
fn build_greeting(name: &str) -> String {
    format!("Hello, {}!", name)
}

// Pattern: builder that accepts flexible strings
struct ConfigBuilder {
    host: String,
    database: String,
}

impl ConfigBuilder {
    fn host(mut self, host: impl Into<String>) -> Self {
        self.host = host.into();
        self
    }

    fn database(mut self, db: impl Into<String>) -> Self {
        self.database = db.into();
        self
    }

    fn build(self) -> Config {
        Config {
            host: self.host,
            database: self.database,
        }
    }
}

// Usage - very flexible
let config = ConfigBuilder::default()
    .host("localhost")                    // &str
    .database(String::from("mydb"))       // String
    .build();

// Comparing string types
fn compare_strings(a: &str, b: &str) -> bool {
    a == b
}

let s1 = "hello";
let s2 = String::from("hello");
let s3 = "hello".to_string();

assert!(compare_strings(s1, &s2));
assert!(compare_strings(&s2, &s3));

// Converting between types
let owned = String::from("hello");
let borrowed: &str = &owned;
let borrowed2: &str = owned.as_str();

// Common patterns
// Bad: unnecessary cloning
fn process_bad(input: &String) -> String {
    let s = input.clone();  // Unnecessary clone
    s.to_uppercase()
}

// Good: borrow what you need
fn process_good(input: &str) -> String {
    input.to_uppercase()  // No clone needed
}

// Method chaining with strings
fn build_query(table: &str, filter: &str) -> String {
    format!("SELECT * FROM {} WHERE {}", table, filter)
}

// Works with any string type
build_query("users", "active = true");
build_query(&String::from("users"), &String::from("active = true"));
```

**Summary:**

- **&str**: Read-only access, most flexible
- **String**: Need ownership
- **&mut String**: Need to modify in place
- **&String**: Never use (use &str instead)
- **impl Into<String>**: Builder patterns
- **impl AsRef<str>**: Maximum flexibility

---

# Use Arc and Mutex for Shared State

> Use `Arc<Mutex<T>>` or `Arc<RwLock<T>>` for safely sharing mutable state across threads.

## Rules

- Use `Arc` (Atomic Reference Counting) for shared ownership across threads
- Use `Mutex` for exclusive mutable access to shared data
- Use `RwLock` when reads greatly outnumber writes
- Always lock for the shortest duration possible
- Handle lock() unwrap carefully; consider using try_lock()
- Be aware of deadlock risks with multiple locks
- Use channels as an alternative to shared state when possible

## Example

```rust
use std::sync::{Arc, Mutex, RwLock};
use std::thread;

// Basic shared mutable state
fn basic_example() {
    let counter = Arc::new(Mutex::new(0));
    let mut handles = vec![];

    for _ in 0..10 {
        let counter_clone = Arc::clone(&counter);
        let handle = thread::spawn(move || {
            let mut num = counter_clone.lock().unwrap();
            *num += 1;
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }

    println!("Result: {}", *counter.lock().unwrap()); // 10
}

// Shared application state
struct AppState {
    users: Vec<String>,
    request_count: u64,
}

type SharedState = Arc<Mutex<AppState>>;

fn handle_request(state: SharedState) {
    let mut state = state.lock().unwrap();
    state.request_count += 1;
    println!("Request #{}", state.request_count);
}

fn run_server() {
    let state = Arc::new(Mutex::new(AppState {
        users: vec![],
        request_count: 0,
    }));

    let mut handles = vec![];
    for _ in 0..5 {
        let state_clone = Arc::clone(&state);
        let handle = thread::spawn(move || {
            handle_request(state_clone);
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }
}

// RwLock for read-heavy workloads
fn rwlock_example() {
    let data = Arc::new(RwLock::new(vec![1, 2, 3]));
    let mut handles = vec![];

    // Multiple readers
    for i in 0..5 {
        let data_clone = Arc::clone(&data);
        let handle = thread::spawn(move || {
            let vec = data_clone.read().unwrap();
            println!("Reader {}: {:?}", i, vec);
        });
        handles.push(handle);
    }

    // One writer
    let data_clone = Arc::clone(&data);
    let handle = thread::spawn(move || {
        let mut vec = data_clone.write().unwrap();
        vec.push(4);
        println!("Writer added 4");
    });
    handles.push(handle);

    for handle in handles {
        handle.join().unwrap();
    }
}

// Lock for shortest duration
// Bad: holding lock too long
fn bad_lock_duration(data: Arc<Mutex<Vec<i32>>>) {
    let mut vec = data.lock().unwrap();
    // Long computation while holding lock
    expensive_computation();
    vec.push(1);
}

// Good: release lock during computation
fn good_lock_duration(data: Arc<Mutex<Vec<i32>>>) {
    let result = expensive_computation();

    // Lock only for the update
    let mut vec = data.lock().unwrap();
    vec.push(result);
}

// Avoid deadlocks
// Bad: lock ordering can cause deadlock
fn potential_deadlock(
    data1: Arc<Mutex<i32>>,
    data2: Arc<Mutex<i32>>,
) {
    thread::spawn(move || {
        let _a = data1.lock().unwrap();
        let _b = data2.lock().unwrap(); // Might deadlock
    });

    thread::spawn(move || {
        let _b = data2.lock().unwrap();
        let _a = data1.lock().unwrap(); // Might deadlock
    });
}

// Good: consistent lock ordering
fn no_deadlock(
    data1: Arc<Mutex<i32>>,
    data2: Arc<Mutex<i32>>,
) {
    thread::spawn(move || {
        let _a = data1.lock().unwrap();
        let _b = data2.lock().unwrap();
    });

    thread::spawn(move || {
        let _a = data1.lock().unwrap(); // Same order
        let _b = data2.lock().unwrap();
    });
}

// try_lock to avoid blocking
fn try_lock_example(data: Arc<Mutex<Vec<i32>>>) {
    match data.try_lock() {
        Ok(mut vec) => {
            vec.push(1);
            println!("Acquired lock");
        }
        Err(_) => {
            println!("Lock busy, skipping");
        }
    }
}

// Scope-based locking
fn scoped_lock(data: Arc<Mutex<Vec<i32>>>) {
    {
        let mut vec = data.lock().unwrap();
        vec.push(1);
    } // Lock released here

    // Do other work without holding lock
    do_other_work();
}

// Alternative: use channels instead of shared state
use std::sync::mpsc;

fn channel_alternative() {
    let (tx, rx) = mpsc::channel();

    // Spawner thread
    thread::spawn(move || {
        tx.send(42).unwrap();
    });

    // Receiver thread
    let received = rx.recv().unwrap();
    println!("Received: {}", received);
}

// Real-world example: connection pool
use std::collections::VecDeque;

struct ConnectionPool {
    connections: Arc<Mutex<VecDeque<Connection>>>,
}

impl ConnectionPool {
    fn new(size: usize) -> Self {
        let mut connections = VecDeque::new();
        for _ in 0..size {
            connections.push_back(Connection::new());
        }

        ConnectionPool {
            connections: Arc::new(Mutex::new(connections)),
        }
    }

    fn get(&self) -> Option<Connection> {
        let mut pool = self.connections.lock().unwrap();
        pool.pop_front()
    }

    fn return_connection(&self, conn: Connection) {
        let mut pool = self.connections.lock().unwrap();
        pool.push_back(conn);
    }
}

// Implementing Clone for shared state
impl Clone for ConnectionPool {
    fn clone(&self) -> Self {
        ConnectionPool {
            connections: Arc::clone(&self.connections),
        }
    }
}
```

**When to use what:**

- **Arc<Mutex<T>>**: Shared mutable state, writes common
- **Arc<RwLock<T>>**: Shared state, reads outnumber writes 10:1+
- **Arc<T>**: Shared immutable state
- **Channels**: Message passing, producer-consumer patterns
- **Atomic types**: Simple counters (AtomicU64, AtomicBool)

---

# Leverage Zero-Cost Abstractions

> Use Rust's high-level abstractions knowing they compile to efficient low-level code with no runtime overhead.

## Rules

- Use iterators instead of manual loops (same performance, better readability)
- Trust that generics have zero runtime cost (monomorphization)
- Use enums and pattern matching freely (optimized away)
- Leverage trait abstractions without worrying about virtual dispatch overhead
- Use newtype patterns for type safety at no runtime cost
- Prefer high-level code; the compiler optimizes it to machine code
- Profile before optimizing; don't assume abstractions are slow

## Example

```rust
// Iterators vs loops - same performance
// Both compile to identical machine code

// Manual loop
fn sum_manual(numbers: &[i32]) -> i32 {
    let mut sum = 0;
    for i in 0..numbers.len() {
        sum += numbers[i];
    }
    sum
}

// Iterator (zero-cost abstraction)
fn sum_iterator(numbers: &[i32]) -> i32 {
    numbers.iter().sum()
}

// Complex iterator chains - still zero cost
fn process_data(numbers: &[i32]) -> Vec<i32> {
    numbers
        .iter()
        .filter(|&&x| x > 0)
        .map(|&x| x * 2)
        .take(10)
        .collect()
}

// Generics - monomorphization (separate copy per type)
// No runtime overhead, no dynamic dispatch
fn print_value<T: std::fmt::Display>(value: T) {
    println!("{}", value);
}

// Compiler generates specialized versions:
// print_value::<i32>(42)       - one version for i32
// print_value::<String>(s)     - one version for String

// Newtype pattern - zero runtime cost
struct UserId(u64);
struct OrderId(u64);

fn process_user(id: UserId) {
    // Type safety at compile time, zero cost at runtime
    // UserId and u64 have identical memory layout
}

// Can't mix up IDs due to type system
let user_id = UserId(42);
let order_id = OrderId(100);
// process_user(order_id); // ERROR: type mismatch

// Enums - optimized memory layout
enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
}

// Compiler optimizes to smallest possible size
// Pattern matching compiles to jump tables or switches
fn handle_message(msg: Message) {
    match msg {
        Message::Quit => quit(),
        Message::Move { x, y } => move_to(x, y),
        Message::Write(s) => write_message(s),
    }
}

// Option and Result - zero cost
// Compiler optimizes null pointer checks
fn divide(a: i32, b: i32) -> Option<i32> {
    if b == 0 {
        None
    } else {
        Some(a / b)
    }
}

// match on Option compiles to efficient null check
fn use_result(result: Option<i32>) {
    match result {
        Some(value) => println!("{}", value),
        None => println!("No value"),
    }
}

// Static dispatch (zero cost)
trait Calculate {
    fn calculate(&self, x: i32) -> i32;
}

struct Doubler;
impl Calculate for Doubler {
    fn calculate(&self, x: i32) -> i32 {
        x * 2
    }
}

// Monomorphized - compiler knows exact type
fn process<C: Calculate>(calc: &C, value: i32) {
    let result = calc.calculate(value);
    // Direct call, no vtable lookup
}

// Dynamic dispatch (has small cost)
fn process_dyn(calc: &dyn Calculate, value: i32) {
    let result = calc.calculate(value);
    // Virtual call through vtable
}

// Inline functions - zero overhead
#[inline]
fn add(a: i32, b: i32) -> i32 {
    a + b
}

// #[inline(always)] for critical hot paths
#[inline(always)]
fn critical_function() {
    // This will always be inlined
}

// Const evaluation - computed at compile time
const BUFFER_SIZE: usize = 1024 * 1024;
const MAX_USERS: usize = compute_max_users();

const fn compute_max_users() -> usize {
    1000 * 100  // Computed at compile time
}

// Smart pointers - efficient
// Box<T> is just a pointer (size of usize)
fn use_box() {
    let value = Box::new(42);  // Heap allocation
    // Single pointer on stack, no overhead
}

// Rc<T> is pointer + reference count
// Arc<T> is pointer + atomic reference count

// Trait objects - when you need dynamic dispatch
fn process_shapes(shapes: Vec<Box<dyn Shape>>) {
    for shape in shapes {
        shape.draw();  // Dynamic dispatch
    }
}
// Use when you need heterogeneous collections
// Small cost: vtable lookup per call

// Benchmarking to verify zero cost
#[cfg(test)]
mod benches {
    use super::*;

    #[bench]
    fn bench_manual_loop(b: &mut test::Bencher) {
        let numbers: Vec<i32> = (1..1000).collect();
        b.iter(|| sum_manual(&numbers));
    }

    #[bench]
    fn bench_iterator(b: &mut test::Bencher) {
        let numbers: Vec<i32> = (1..1000).collect();
        b.iter(|| sum_iterator(&numbers));
    }
    // Results should be identical or very close
}

// Closure optimization
fn apply_operation<F>(numbers: &[i32], op: F) -> Vec<i32>
where
    F: Fn(i32) -> i32,
{
    numbers.iter().map(|&x| op(x)).collect()
}

// Closure inlined - no function call overhead
let doubled = apply_operation(&[1, 2, 3], |x| x * 2);

// Match optimization
fn categorize(value: i32) -> &'static str {
    match value {
        0..=10 => "small",
        11..=100 => "medium",
        _ => "large",
    }
    // Compiles to efficient range checks
}

// Type state pattern - compile-time guarantees
struct Unlocked;
struct Locked;

struct Door<State> {
    state: PhantomData<State>,
}

impl Door<Unlocked> {
    fn lock(self) -> Door<Locked> {
        Door { state: PhantomData }
    }
}

impl Door<Locked> {
    fn unlock(self) -> Door<Unlocked> {
        Door { state: PhantomData }
    }
}

// Type system prevents invalid operations
// PhantomData has zero size - no runtime cost
```

**Key takeaways:**

- Write idiomatic, high-level code
- Compiler optimizes abstractions to machine code
- Use iterators, generics, and enums freely
- Profile first, optimize later
- Trust the compiler's optimizer
- Zero-cost doesn't mean zero assembly - it means no overhead vs hand-written low-level code

---

# Follow Security Best Practices

> Write Rust code that leverages the type system and ecosystem tools to prevent common security vulnerabilities.

## Rules

- Use `cargo audit` to check dependencies for known vulnerabilities
- Minimize `unsafe` blocks; document safety invariants with `// SAFETY:` comments
- Validate and sanitize all external input before processing
- Use parameterized queries with `sqlx` or `diesel`; never build SQL with `format!`
- Use `secrecy::Secret<T>` to prevent accidental logging of sensitive values
- Set timeouts on all network operations to prevent resource exhaustion
- Use `cargo-deny` to enforce license compliance and ban problematic crates
- Pin dependencies with `Cargo.lock` and review updates before merging

## Example

```rust
// Bad: SQL injection, no input validation, secret in logs
fn get_user(name: &str) -> Result<User> {
    let query = format!("SELECT * FROM users WHERE name = '{}'", name);
    let password = "hunter2";
    log::info!("Authenticating with password: {}", password);
    db.query(&query)
}

// Good: parameterized query, input validation, secret protection
use secrecy::{ExposeSecret, Secret};
use sqlx::query_as;

fn get_user(pool: &PgPool, name: &str) -> Result<User> {
    // Validate input
    if name.len() > 255 || name.contains('\0') {
        return Err(Error::InvalidInput("invalid username"));
    }

    // Parameterized query
    query_as!(User, "SELECT * FROM users WHERE name = $1", name)
        .fetch_one(pool)
        .await
}

fn authenticate(password: Secret<String>) -> Result<()> {
    // Secret is redacted in Debug/Display output
    log::info!("Authenticating user"); // password not logged
    verify_hash(password.expose_secret())
}
```

```bash
# Audit dependencies for vulnerabilities
cargo audit

# Check for banned crates, duplicate deps, license issues
cargo deny check
```

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **rustfmt** — format Rust source code: `cargo fmt`
- **clippy** — catch common Rust mistakes and improve code: `cargo clippy -- -D warnings`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
