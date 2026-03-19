---
name: python-principles
description: "Use when writing, reviewing, or modifying Python code (.py, pyproject.toml, requirements.txt)"
globs: ["**/*.py", "**/pyproject.toml", "**/requirements*.txt", "**/setup.py", "**/setup.cfg"]
---

# Python Principles

These are non-negotiable coding standards -- if you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations.

# Use Type Hints

> Always use type hints to make code self-documenting, enable static type checking, and catch bugs before runtime.

## Rules

- Annotate all function parameters and return types with type hints
- Use `Optional[T]` for values that can be None, or use `T | None` in Python 3.10+
- Use generics like `list[str]`, `dict[str, int]` for container types (3.9+)
- Use `Protocol` from typing for structural subtyping (duck typing with types)
- Configure mypy in your project and run it in CI/CD pipelines
- Use `TypeAlias` for complex type expressions to improve readability
- Avoid using `Any` unless absolutely necessary; it defeats type checking

## Example

```python
# Bad: no type hints
def process_users(users, filter_active):
    result = []
    for user in users:
        if filter_active and user["active"]:
            result.append(user["name"])
    return result

# Good: with type hints
from typing import TypeAlias

UserDict: TypeAlias = dict[str, str | bool]

def process_users(
    users: list[UserDict],
    filter_active: bool = False
) -> list[str]:
    result: list[str] = []
    for user in users:
        if filter_active and user.get("active"):
            result.append(str(user["name"]))
    return result
```

**mypy.ini:**

```ini
[mypy]
python_version = 3.10
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
```

---

# Use Context Managers

> Always use context managers with the `with` statement for resource management to ensure proper cleanup even when errors occur.

## Rules

- Use `with` statements for all file operations, database connections, and network resources
- Create custom context managers using `@contextmanager` decorator or `__enter__/__exit__` methods
- Handle exceptions properly in `__exit__` method; return `True` to suppress, `False` to propagate
- Use `contextlib.ExitStack` for managing multiple context managers dynamically
- Never manually call `open()` and `close()` when a context manager is available
- Prefer context managers over try/finally blocks for resource cleanup

## Example

```python
# Bad: manual resource management
def read_file(path):
    f = open(path)
    data = f.read()
    f.close()  # Might not execute if read() raises
    return data

# Good: using context manager
def read_file(path: str) -> str:
    with open(path) as f:
        return f.read()

# Good: custom context manager
from contextlib import contextmanager
import time

@contextmanager
def timer(name: str):
    start = time.time()
    try:
        yield
    finally:
        elapsed = time.time() - start
        print(f"{name} took {elapsed:.2f}s")

with timer("data processing"):
    process_large_dataset()
```

---

# Follow PEP 8 Style Guide

> Adhere to PEP 8 style conventions for consistent, readable Python code that follows community standards.

## Rules

- Use 4 spaces for indentation (never tabs)
- Limit lines to 88 characters (Black formatter default) or 79 (PEP 8 strict)
- Use `snake_case` for functions and variables, `PascalCase` for classes, `UPPER_CASE` for constants
- Use 2 blank lines between top-level definitions, 1 blank line between methods
- Import order: standard library, third-party, local (separated by blank lines)
- Use Black formatter and Ruff linter to automatically enforce style
- Configure pre-commit hooks to run formatters before each commit

## Example

```python
# Bad: inconsistent style
import os,sys
from myapp import helpers

class myClass:
  def doSomething(self,x,y):
      return x+y

# Good: PEP 8 compliant
import os
import sys

from myapp import helpers


class MyClass:
    """A class that does something."""

    def do_something(self, x: int, y: int) -> int:
        """Add two numbers together."""
        return x + y
```

**pyproject.toml:**

```toml
[tool.black]
line-length = 88
target-version = ['py310']

[tool.ruff]
line-length = 88
select = ["E", "F", "I"]
```

---

# Use Virtual Environments

> Always use virtual environments to isolate project dependencies and avoid version conflicts between projects.

## Rules

- Create a virtual environment for every Python project using `venv`, `virtualenv`, or `conda`
- Never install project dependencies globally with `pip install` outside a virtual environment
- Add `.venv/`, `venv/`, or `env/` to `.gitignore` to avoid committing virtual environments
- Activate the virtual environment before running project code or installing dependencies
- Document the Python version requirement in `README.md` or `pyproject.toml`
- Use `python -m venv` instead of the `virtualenv` command for consistency with standard library

## Example

```bash
# Bad: installing globally
pip install requests flask

# Good: using virtual environment
# Create virtual environment
python3.10 -m venv .venv

# Activate (Linux/macOS)
source .venv/bin/activate

# Activate (Windows)
.venv\Scripts\activate

# Install dependencies
pip install requests flask

# Save dependencies
pip freeze > requirements.txt

# Deactivate when done
deactivate
```

**.gitignore:**

```
# Virtual environments
.venv/
venv/
env/
ENV/
```

---

# Write Comprehensive Docstrings

> Document all modules, classes, and functions with clear docstrings following Google or NumPy style conventions.

## Rules

- Write docstrings for all public modules, classes, methods, and functions
- Use triple-quoted strings (`"""docstring"""`) even for one-line docstrings
- Follow Google or NumPy docstring format consistently across the project
- Include parameters, return types, exceptions raised, and usage examples
- Use imperative mood ("Return" not "Returns") for function descriptions
- Keep first line as a brief summary; add detailed explanation after a blank line
- Use Sphinx or MkDocs to generate documentation from docstrings

## Example

```python
# Bad: no docstring
def calculate_discount(price, discount_percent, membership_level):
    if membership_level == "gold":
        discount_percent += 10
    return price * (1 - discount_percent / 100)

# Good: comprehensive docstring
def calculate_discount(
    price: float,
    discount_percent: float,
    membership_level: str = "standard"
) -> float:
    """Calculate final price after applying discount.

    Applies the base discount percentage to the price, with an additional
    10% discount for gold members.

    Args:
        price: Original price before discount
        discount_percent: Base discount percentage (0-100)
        membership_level: Customer membership tier (standard/gold)

    Returns:
        Final price after discount applied

    Raises:
        ValueError: If price is negative or discount_percent is not in 0-100 range

    Example:
        >>> calculate_discount(100.0, 20.0, "gold")
        70.0
    """
    if price < 0 or not 0 <= discount_percent <= 100:
        raise ValueError("Invalid price or discount percentage")

    if membership_level == "gold":
        discount_percent += 10

    return price * (1 - discount_percent / 100)
```

---

# Handle Exceptions Properly

> Catch specific exceptions, provide meaningful context, and ensure proper cleanup to make errors debuggable and systems resilient.

## Rules

- Always catch specific exceptions, never use bare `except:` clauses
- Use `finally` blocks for cleanup code that must run regardless of exceptions
- Re-raise exceptions with additional context using `raise ... from` to preserve the stack trace
- Log exceptions with full context before handling or re-raising
- Never silently ignore exceptions unless explicitly intended (document why)
- Use custom exception classes for domain-specific errors
- Prefer EAFP (Easier to Ask for Forgiveness than Permission) over LBYL (Look Before You Leap)

## Example

```python
# Bad: catching all exceptions without context
def load_config(path):
    try:
        f = open(path)
        return json.load(f)
    except:
        return {}

# Good: specific exceptions with context
import logging
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)

class ConfigError(Exception):
    """Raised when configuration cannot be loaded."""
    pass

def load_config(path: Path) -> dict[str, Any]:
    """Load configuration from JSON file."""
    try:
        with open(path) as f:
            return json.load(f)
    except FileNotFoundError as e:
        logger.error(f"Config file not found: {path}")
        raise ConfigError(f"Cannot find config at {path}") from e
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in config: {path}, line {e.lineno}")
        raise ConfigError(f"Invalid JSON in {path}") from e
    except Exception as e:
        logger.exception(f"Unexpected error loading config: {path}")
        raise
```

---

# Use pathlib Over os.path

> Use the modern `pathlib` module for path operations instead of string manipulation with `os.path` for cleaner, cross-platform code.

## Rules

- Import `Path` from `pathlib` and use it for all file path operations
- Use `/` operator to join paths instead of `os.path.join()`
- Use Path methods like `.exists()`, `.read_text()`, `.write_text()` for common operations
- Use `.glob()` and `.rglob()` for pattern matching instead of `glob.glob()`
- Convert Path objects to strings only when interfacing with legacy APIs
- Use `.resolve()` to get absolute paths instead of `os.path.abspath()`
- Leverage `.stem`, `.suffix`, `.parent`, `.name` properties for path components

## Example

```python
# Bad: using os.path with string manipulation
import os
import glob

config_dir = os.path.join(os.getcwd(), "config")
config_file = os.path.join(config_dir, "app.yaml")

if os.path.exists(config_file):
    with open(config_file) as f:
        content = f.read()

yaml_files = glob.glob(os.path.join(config_dir, "*.yaml"))

# Good: using pathlib
from pathlib import Path

config_dir = Path.cwd() / "config"
config_file = config_dir / "app.yaml"

if config_file.exists():
    content = config_file.read_text()

yaml_files = list(config_dir.glob("*.yaml"))

# Useful Path operations
filename = config_file.stem  # "app"
extension = config_file.suffix  # ".yaml"
parent = config_file.parent  # config_dir
absolute = config_file.resolve()  # full absolute path
```

---

# Use Structured Logging

> Use the `logging` module with structured formats instead of print statements for observable, debuggable production systems.

## Rules

- Never use `print()` for logging; use the `logging` module instead
- Configure logging at application entry point with appropriate levels and formats
- Use structured logging with context fields (JSON format) for production systems
- Include logger names using `__name__` to identify source of log messages
- Use appropriate log levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
- Add contextual information using extra parameters or structured loggers
- Configure separate handlers for different outputs (console, file, external services)

## Example

```python
# Bad: using print statements
def process_order(order_id):
    print(f"Processing order {order_id}")
    try:
        result = charge_payment(order_id)
        print(f"Payment successful: {result}")
    except Exception as e:
        print(f"ERROR: {e}")

# Good: structured logging
import logging
from pythonjsonlogger import jsonlogger

logger = logging.getLogger(__name__)

def configure_logging():
    """Configure structured JSON logging."""
    handler = logging.StreamHandler()
    formatter = jsonlogger.JsonFormatter(
        "%(asctime)s %(name)s %(levelname)s %(message)s"
    )
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)

def process_order(order_id: str) -> None:
    """Process customer order."""
    logger.info("Processing order", extra={
        "order_id": order_id,
        "action": "process_start"
    })
    try:
        result = charge_payment(order_id)
        logger.info("Payment successful", extra={
            "order_id": order_id,
            "amount": result.amount,
            "transaction_id": result.transaction_id
        })
    except PaymentError as e:
        logger.error("Payment failed", extra={
            "order_id": order_id,
            "error": str(e)
        }, exc_info=True)
        raise
```

---

# Avoid Mutable Default Arguments

> Never use mutable objects (lists, dicts, sets) as default function arguments; use None and create the object inside the function.

## Rules

- Never use `[]`, `{}`, or `set()` as default arguments
- Use `None` as the default and create the mutable object in the function body
- Understand that default arguments are evaluated once at function definition time, not each call
- Use immutable defaults only: `None`, `True`, `False`, numbers, strings, tuples
- This is one of Python's most common gotchas that leads to surprising behavior
- Linters like Ruff and Pylint will warn about mutable default arguments

## Example

```python
# Bad: mutable default argument
def add_item(item: str, items: list[str] = []) -> list[str]:
    items.append(item)
    return items

# This produces unexpected behavior:
first = add_item("apple")   # ["apple"]
second = add_item("banana")  # ["apple", "banana"] - SURPRISE!
# Both calls share the same list object!

# Good: use None and create inside function
def add_item(item: str, items: list[str] | None = None) -> list[str]:
    if items is None:
        items = []
    items.append(item)
    return items

# Now it works correctly:
first = add_item("apple")   # ["apple"]
second = add_item("banana")  # ["banana"]

# Good: another pattern with default factory
def process_data(data: dict[str, str] | None = None) -> dict[str, str]:
    if data is None:
        data = {}
    # Process data...
    return data
```

---

# Use Comprehensions Appropriately

> Prefer list/dict/set comprehensions over loops for simple transformations, but use regular loops for complex logic.

## Rules

- Use comprehensions for simple map and filter operations that fit on one readable line
- Switch to regular loops when logic becomes complex or nested
- Prefer generator expressions for large datasets to save memory
- Use dict comprehensions for transforming dictionaries
- Avoid deeply nested comprehensions (more than 2 levels)
- Never sacrifice readability for brevity; loops are perfectly fine
- Use walrus operator `:=` in comprehensions to avoid duplicate computation (Python 3.8+)

## Example

```python
# Bad: complex logic in comprehension
results = [
    process(x) for x in data
    if x.active and x.status == "valid"
    and x.timestamp > cutoff
    and validate(x)
]

# Good: use a loop for complex logic
results = []
for x in data:
    if not x.active:
        continue
    if x.status != "valid" or x.timestamp <= cutoff:
        continue
    if not validate(x):
        continue
    results.append(process(x))

# Good: simple transformations
squares = [x ** 2 for x in range(10)]
active_users = [u for u in users if u.is_active]
name_map = {u.id: u.name for u in users}

# Good: generator for large datasets
total = sum(x ** 2 for x in range(1_000_000))  # Memory efficient

# Good: walrus operator to avoid duplicate work
if results := [x for x in data if (processed := process(x)) is not None]:
    use_results(results)
```

---

# Use Dataclasses

> Use `@dataclass` or Pydantic models for data structures instead of plain classes or dictionaries to get automatic methods and validation.

## Rules

- Use `@dataclass` from the standard library for simple data containers
- Use Pydantic models when you need validation, serialization, or API schemas
- Prefer dataclasses over plain classes with `__init__` boilerplate
- Use `frozen=True` for immutable dataclasses that should be hashable
- Use `field(default_factory=...)` for mutable default values
- Leverage Pydantic for configuration management and API request/response models
- Use type hints on all fields for documentation and type checking

## Example

```python
# Bad: plain class with boilerplate
class User:
    def __init__(self, id, name, email, age=None):
        self.id = id
        self.name = name
        self.email = email
        self.age = age

    def __repr__(self):
        return f"User(id={self.id}, name={self.name})"

# Good: using dataclass
from dataclasses import dataclass, field

@dataclass
class User:
    id: int
    name: str
    email: str
    age: int | None = None
    tags: list[str] = field(default_factory=list)

# Better: using Pydantic for validation
from pydantic import BaseModel, EmailStr, Field

class User(BaseModel):
    id: int = Field(..., gt=0)
    name: str = Field(..., min_length=1)
    email: EmailStr
    age: int | None = Field(None, ge=0, le=150)
    tags: list[str] = Field(default_factory=list)

# Automatic validation
try:
    user = User(id=0, name="", email="invalid")
except ValueError as e:
    print(e)  # Validation errors with details
```

---

# Use f-strings for Formatting

> Use f-strings (formatted string literals) for string formatting instead of %-formatting or `.format()` for cleaner, faster code.

## Rules

- Always use f-strings for string interpolation in Python 3.6+
- Avoid old-style %-formatting (`"Hello %s" % name`) unless maintaining legacy code
- Avoid `.format()` method unless you need to separate format string from values
- Use f-string debugging syntax `f"{variable=}"` to print variable name and value
- Format numbers, dates, and floats inline: `f"{value:.2f}"`, `f"{dt:%Y-%m-%d}"`
- Use raw f-strings `fr"..."` or `rf"..."` when combining with regex patterns
- For extremely large or dynamic strings, consider `str.join()` instead

## Example

```python
# Bad: old-style formatting
name = "Alice"
age = 30
message = "Hello %s, you are %d years old" % (name, age)
price = "Price: $%.2f" % 19.99

# Bad: .format() method
message = "Hello {}, you are {} years old".format(name, age)

# Good: f-strings
message = f"Hello {name}, you are {age} years old"
price = f"Price: ${19.99:.2f}"

# Good: f-string debugging (Python 3.8+)
x = 10
y = 20
print(f"{x=}, {y=}, {x+y=}")  # Output: x=10, y=20, x+y=30

# Good: formatting numbers and dates
from datetime import datetime
pi = 3.14159
now = datetime.now()
print(f"Pi to 2 decimals: {pi:.2f}")
print(f"Today: {now:%Y-%m-%d %H:%M}")

# Good: multiline f-strings
report = f"""
User Report:
  Name: {user.name}
  Status: {user.status}
  Last login: {user.last_login:%Y-%m-%d}
"""
```

---

# Write Unit Tests with pytest

> Use pytest as your testing framework for clean, powerful tests with minimal boilerplate and excellent tooling.

## Rules

- Use pytest instead of unittest for new projects (cleaner syntax, better fixtures)
- Name test files `test_*.py` or `*_test.py` and functions `test_*`
- Use pytest fixtures for setup and teardown instead of classes
- Use `@pytest.mark.parametrize` to test multiple inputs without repeating code
- Mock external dependencies using `unittest.mock` or `pytest-mock`
- Organize tests in a `tests/` directory mirroring your source structure
- Run tests in CI/CD and aim for >80% code coverage
- Use `pytest-cov` for coverage reports and `pytest-xdist` for parallel execution

## Example

```python
# tests/test_calculator.py

import pytest
from myapp.calculator import add, divide

# Simple test
def test_add():
    assert add(2, 3) == 5
    assert add(-1, 1) == 0

# Parametrized test
@pytest.mark.parametrize("a,b,expected", [
    (2, 3, 5),
    (0, 0, 0),
    (-1, 1, 0),
    (100, 200, 300),
])
def test_add_parametrized(a, b, expected):
    assert add(a, b) == expected

# Test exceptions
def test_divide_by_zero():
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)

# Using fixtures
@pytest.fixture
def sample_data():
    """Fixture providing test data."""
    return {"users": [{"id": 1, "name": "Alice"}]}

def test_with_fixture(sample_data):
    assert len(sample_data["users"]) == 1
    assert sample_data["users"][0]["name"] == "Alice"

# Mocking external calls
from unittest.mock import patch

def test_api_call(mocker):
    mock_response = mocker.Mock()
    mock_response.json.return_value = {"status": "ok"}
    mocker.patch("requests.get", return_value=mock_response)

    result = fetch_api_data()
    assert result["status"] == "ok"
```

**pytest.ini:**

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_functions = test_*
addopts = --cov=myapp --cov-report=html
```

---

# Use Async/Await for I/O Operations

> Use asyncio with async/await for I/O-bound operations to improve performance through concurrency without threading complexity.

## Rules

- Use `async def` for functions that perform I/O operations (network, file, database)
- Use `await` keyword to call other async functions
- Use `asyncio.gather()` to run multiple async operations concurrently
- Use async libraries: `aiohttp` for HTTP, `asyncpg` for PostgreSQL, `aiofiles` for files
- Never mix blocking (sync) and non-blocking (async) code without proper handling
- Use `asyncio.run()` as the entry point for async programs
- Use `asyncio.create_task()` to run tasks in the background
- Avoid CPU-bound work in async functions; use `run_in_executor()` or multiprocessing

## Example

```python
# Bad: synchronous I/O (slow, sequential)
import requests

def fetch_urls(urls):
    results = []
    for url in urls:
        response = requests.get(url)  # Blocks for each request
        results.append(response.json())
    return results

# Good: asynchronous I/O (fast, concurrent)
import asyncio
import aiohttp

async def fetch_url(session: aiohttp.ClientSession, url: str) -> dict:
    """Fetch a single URL asynchronously."""
    async with session.get(url) as response:
        return await response.json()

async def fetch_urls(urls: list[str]) -> list[dict]:
    """Fetch multiple URLs concurrently."""
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_url(session, url) for url in urls]
        results = await asyncio.gather(*tasks)
        return results

# Entry point
if __name__ == "__main__":
    urls = ["https://api.example.com/1", "https://api.example.com/2"]
    results = asyncio.run(fetch_urls(urls))

# Good: background tasks
async def main():
    # Start background task
    task = asyncio.create_task(long_running_operation())

    # Do other work
    await do_something_else()

    # Wait for background task
    result = await task
```

---

# Manage Dependencies Properly

> Use modern dependency management tools and lock files to ensure reproducible builds and avoid version conflicts.

## Rules

- Use `requirements.txt` for simple projects, Poetry or PDM for complex projects
- Always pin dependencies with exact versions in production (`==` not `>=`)
- Use separate requirements files: `requirements.txt`, `requirements-dev.txt`, `requirements-test.txt`
- Generate lock files to ensure reproducible builds across environments
- Specify Python version requirements in `pyproject.toml` or `README.md`
- Regularly update dependencies and check for security vulnerabilities with tools like `pip-audit`
- Use dependency groups in Poetry to separate dev, test, and production dependencies

## Example

```bash
# Bad: unpinned dependencies
requests
flask
numpy

# Good: pinned dependencies with hashes
# requirements.txt
requests==2.31.0 \
    --hash=sha256:942c5a758f98d56f5a05c4
flask==3.0.0 \
    --hash=sha256:ceb27b0af3823b722842c8e3
numpy==1.26.2 \
    --hash=sha256:3ab67b7b2e0c82e8a9a

# Generate requirements with hashes
pip freeze > requirements.txt
pip-compile --generate-hashes requirements.in

# Good: using Poetry
# pyproject.toml
[tool.poetry.dependencies]
python = "^3.10"
requests = "^2.31.0"
flask = "^3.0.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.4.0"
black = "^23.0.0"
mypy = "^1.5.0"
```

**Best practices:**

```bash
# Install from lock file
pip install -r requirements.txt

# Or with Poetry
poetry install --no-root

# Check for vulnerabilities
pip-audit

# Update dependencies safely
pip list --outdated
poetry update --dry-run
```

---

# Use Static Type Checking

> Run mypy or pyright in CI/CD to catch type errors before runtime and improve code quality.

## Rules

- Configure mypy or pyright in your project and run it in pre-commit hooks and CI/CD
- Enable strict mode gradually: start with basic checks, increase strictness over time
- Use type hints on all public functions and methods
- Add `# type: ignore` comments sparingly and only when necessary (with explanation)
- Use stub files (`.pyi`) for third-party libraries without type hints
- Configure your IDE (VS Code, PyCharm) to show type errors in real-time
- Use `reveal_type()` in mypy to debug complex type inference issues

## Example

```python
# mypy will catch these errors at check time, not runtime

# Error: incompatible types
def greet(name: str) -> str:
    return f"Hello {name}"

result: int = greet("Alice")  # mypy error: Expected int, got str

# Error: missing return
def calculate(x: int) -> int:
    if x > 0:
        return x * 2
    # mypy error: Missing return statement

# Good: properly typed code
from typing import TypedDict

class UserDict(TypedDict):
    id: int
    name: str
    email: str

def process_user(user: UserDict) -> str:
    """Process user and return summary."""
    return f"User {user['name']} ({user['email']})"

# mypy catches dict key errors
user: UserDict = {"id": 1, "name": "Alice"}  # Error: missing 'email'
```

**mypy.ini:**

```ini
[mypy]
python_version = 3.10
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
disallow_any_unimported = True
no_implicit_optional = True
warn_redundant_casts = True
warn_unused_ignores = True
warn_no_return = True
check_untyped_defs = True
```

**Run in CI:**

```bash
# Pre-commit hook
mypy src/

# Or with pyright
pyright src/
```

---

# Follow Security Best Practices

> Validate inputs, avoid injection vulnerabilities, and handle secrets properly to prevent common security issues.

## Rules

- Never trust user input; validate and sanitize all external data
- Use parameterized queries for SQL to prevent SQL injection
- Avoid `eval()`, `exec()`, and `pickle` with untrusted data
- Never hardcode secrets; use environment variables or secret management services
- Use cryptographic libraries (cryptography, secrets) instead of rolling your own
- Keep dependencies updated and scan for vulnerabilities with `pip-audit` or Snyk
- Use HTTPS for all external API calls
- Implement proper authentication and authorization checks
- Log security events but never log sensitive data (passwords, tokens, PII)

## Example

```python
# Bad: SQL injection vulnerability
def get_user(username):
    query = f"SELECT * FROM users WHERE name = '{username}'"
    return db.execute(query)

# Bad: command injection
import os
def backup_file(filename):
    os.system(f"cp {filename} /backup/")  # Shell injection risk

# Good: parameterized query
def get_user(username: str) -> User | None:
    query = "SELECT * FROM users WHERE name = ?"
    return db.execute(query, (username,))

# Good: safe subprocess usage
import subprocess
from pathlib import Path

def backup_file(filename: Path) -> None:
    """Safely backup a file."""
    if not filename.exists():
        raise ValueError(f"File not found: {filename}")

    subprocess.run(
        ["cp", str(filename), "/backup/"],
        check=True,
        capture_output=True
    )

# Good: secrets management
import os
from cryptography.fernet import Fernet

# Load from environment, not hardcoded
API_KEY = os.getenv("API_KEY")
if not API_KEY:
    raise ValueError("API_KEY environment variable not set")

# Good: secure random generation
import secrets

# Not random.random() or random.randint()
token = secrets.token_urlsafe(32)
secure_int = secrets.randbelow(100)

# Good: input validation with Pydantic
from pydantic import BaseModel, validator, EmailStr

class UserInput(BaseModel):
    email: EmailStr
    age: int

    @validator('age')
    def validate_age(cls, v):
        if not 0 <= v <= 150:
            raise ValueError('Age must be between 0 and 150')
        return v
```

---

# Manage API Keys Securely

> Never hardcode API keys in source code; use environment variables and secret management systems to protect credentials.

## Rules

- Store API keys in environment variables, never commit them to version control
- Use `.env` files locally with `python-dotenv`, add `.env` to `.gitignore`
- Use secret management services in production (AWS Secrets Manager, HashiCorp Vault, Azure Key Vault)
- Rotate API keys regularly and have a process for key compromise
- Use different keys for development, staging, and production environments
- Never log API keys, even in debug mode
- Validate that required API keys are present at startup, fail fast if missing

## Example

```python
# Bad: hardcoded API key
import openai
openai.api_key = "sk-1234567890abcdef"  # NEVER DO THIS

# Good: using environment variables
import os
from openai import OpenAI

api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("OPENAI_API_KEY environment variable not set")

client = OpenAI(api_key=api_key)

# Better: using python-dotenv for local development
from dotenv import load_dotenv
import os

load_dotenv()  # Load from .env file

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")

if not OPENAI_API_KEY:
    raise ValueError("Required API keys not configured")

# Best: using Pydantic settings for validation
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    openai_api_key: str
    anthropic_api_key: str
    environment: str = "development"

    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()  # Validates all required keys exist
```

**.env.example:**

```bash
# Copy to .env and fill in your keys
OPENAI_API_KEY=sk-your-key-here
ANTHROPIC_API_KEY=sk-ant-your-key-here
ENVIRONMENT=development
```

**.gitignore:**

```
.env
.env.local
*.key
secrets/
```

---

# Handle API Rate Limits

> Implement exponential backoff and retry logic to handle rate limits gracefully and avoid overwhelming APIs.

## Rules

- Always handle HTTP 429 (Too Many Requests) responses from APIs
- Implement exponential backoff with jitter for retries
- Use libraries like `tenacity` or `backoff` for robust retry logic
- Respect `Retry-After` headers when provided by the API
- Track rate limit headers (X-RateLimit-Remaining, X-RateLimit-Reset)
- Implement client-side rate limiting to stay under API quotas
- Use queues or task schedulers for high-volume API calls

## Example

```python
# Bad: no retry logic
import requests

def call_api(prompt):
    response = requests.post(
        "https://api.openai.com/v1/chat/completions",
        json={"model": "gpt-4", "messages": [{"role": "user", "content": prompt}]}
    )
    return response.json()  # Fails on rate limit

# Good: using tenacity for retries
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type
)
import requests
from requests.exceptions import HTTPError

class RateLimitError(Exception):
    """Raised when API rate limit is hit."""
    pass

@retry(
    retry=retry_if_exception_type(RateLimitError),
    wait=wait_exponential(multiplier=1, min=2, max=60),
    stop=stop_after_attempt(5)
)
def call_api_with_retry(prompt: str) -> dict:
    """Call API with automatic retry on rate limits."""
    response = requests.post(
        "https://api.openai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {API_KEY}"},
        json={
            "model": "gpt-4",
            "messages": [{"role": "user", "content": prompt}]
        }
    )

    if response.status_code == 429:
        retry_after = int(response.headers.get("Retry-After", 60))
        raise RateLimitError(f"Rate limited, retry after {retry_after}s")

    response.raise_for_status()
    return response.json()

# Better: with rate limit tracking
import time
from collections import deque

class RateLimiter:
    """Simple token bucket rate limiter."""

    def __init__(self, max_calls: int, period: float):
        self.max_calls = max_calls
        self.period = period
        self.calls = deque()

    def wait_if_needed(self) -> None:
        """Block if rate limit would be exceeded."""
        now = time.time()

        # Remove old calls outside the period
        while self.calls and self.calls[0] < now - self.period:
            self.calls.popleft()

        if len(self.calls) >= self.max_calls:
            sleep_time = self.period - (now - self.calls[0])
            if sleep_time > 0:
                time.sleep(sleep_time)

        self.calls.append(time.time())

# Usage
limiter = RateLimiter(max_calls=10, period=60)  # 10 calls per minute

for prompt in prompts:
    limiter.wait_if_needed()
    result = call_api_with_retry(prompt)
```

---

# Use Streaming for Large Outputs

> Stream LLM responses instead of waiting for complete responses to improve user experience and handle large outputs efficiently.

## Rules

- Use streaming for LLM responses to show progress and reduce perceived latency
- Process chunks incrementally as they arrive instead of buffering everything
- Handle streaming errors gracefully (connection drops, incomplete responses)
- Use async streaming for better performance in web applications
- Display partial results to users immediately for better UX
- Implement timeout handling for streaming connections
- Close streaming connections properly to avoid resource leaks

## Example

```python
# Bad: waiting for complete response
from openai import OpenAI

client = OpenAI()

response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Write a long story"}]
)
print(response.choices[0].message.content)  # User waits for entire response

# Good: streaming response
from openai import OpenAI

client = OpenAI()

stream = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Write a long story"}],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)

# Better: async streaming with error handling
import asyncio
from anthropic import AsyncAnthropic

async def stream_response(prompt: str) -> str:
    """Stream LLM response with error handling."""
    client = AsyncAnthropic()
    full_response = []

    try:
        async with client.messages.stream(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            messages=[{"role": "user", "content": prompt}]
        ) as stream:
            async for text in stream.text_stream:
                print(text, end="", flush=True)
                full_response.append(text)

        return "".join(full_response)

    except asyncio.TimeoutError:
        print("\n[Stream timeout - partial response]")
        return "".join(full_response)
    except Exception as e:
        print(f"\n[Stream error: {e}]")
        raise

# Usage
asyncio.run(stream_response("Explain quantum computing"))

# Best: streaming in web application with SSE
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from anthropic import Anthropic

app = FastAPI()

@app.get("/chat")
async def chat_stream(prompt: str):
    """Server-sent events endpoint for streaming."""

    async def generate():
        client = Anthropic()
        with client.messages.stream(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            messages=[{"role": "user", "content": prompt}]
        ) as stream:
            for text in stream.text_stream:
                yield f"data: {text}\n\n"

    return StreamingResponse(
        generate(),
        media_type="text/event-stream"
    )
```

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **ruff** — fast Python linter and formatter, lint with auto-fix: `ruff check --fix .`
- **ruff** — format Python files: `ruff format .`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
