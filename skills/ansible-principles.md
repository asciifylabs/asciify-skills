---
name: ansible-principles
description: "Use when writing, reviewing, or modifying Ansible code (playbooks, roles, ansible.cfg)"
---

# Ansible Principles

These are non-negotiable coding standards -- if you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations.

# Use Roles Over Monolithic Playbooks

> Organize Ansible code into single-purpose, reusable roles instead of large monolithic playbooks.

## Rules

- Organize related tasks, handlers, variables, and templates into roles
- Keep playbooks thin -- they should primarily call roles
- Roles must be single-purpose and reusable
- Use role dependencies for composition
- Store roles in separate directories or collections

## Example

```yaml
# playbook.yml (thin playbook)
- name: Configure web server
  hosts: webservers
  roles:
    - common
    - nginx
    - ssl

# roles/nginx/tasks/main.yml
- name: Install nginx
  package:
    name: nginx
    state: present
```

---

# Write Idempotent Tasks

> Ensure every task produces the same result regardless of how many times it runs.

## Rules

- Use Ansible modules instead of raw commands when possible
- Use `state` parameters (present/absent) rather than create/delete commands
- Check conditions before making changes
- Use `changed_when` and `failed_when` for complex scenarios
- Avoid `command` and `shell` modules unless necessary

## Example

```yaml
# Good: Idempotent
- name: Ensure user exists
  user:
    name: appuser
    state: present
    shell: /bin/bash

# Bad: Not idempotent
- name: Create user
  command: useradd appuser

# Good: Idempotent with condition
- name: Install package if not present
  package:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - python3
```

---

# Use Variables and Defaults Effectively

> Parameterize all configurable values with variables and provide sensible defaults.

## Rules

- Define defaults in `defaults/main.yml` in roles
- Use `group_vars` and `host_vars` for environment-specific values
- Provide sensible defaults for every variable
- Document all variables
- Use variable precedence correctly
- Validate variables when appropriate

## Example

```yaml
# roles/nginx/defaults/main.yml
nginx_port: 80
nginx_worker_processes: auto
nginx_user: www-data

# group_vars/production.yml
nginx_port: 443
nginx_ssl_enabled: true

# tasks/main.yml
- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  vars:
    port: "{{ nginx_port }}"
```

---

# Use Handlers for Service Notifications

> Trigger service restarts and reloads through handlers so they only run when configuration actually changes.

## Rules

- Define handlers in `handlers/main.yml`
- Notify handlers only when changes occur
- Handlers run once at the end of the play, even if notified multiple times
- Use `restarted` for full restarts, `reloaded` for graceful reloads
- Handlers are idempotent by default

## Example

```yaml
# tasks/main.yml
- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: restart nginx

- name: Update SSL certificate
  copy:
    src: cert.pem
    dest: /etc/nginx/ssl/cert.pem
  notify: reload nginx

# handlers/main.yml
- name: restart nginx
  systemd:
    name: nginx
    state: restarted

- name: reload nginx
  systemd:
    name: nginx
    state: reloaded
```

---

# Use Templates Over Static Files

> Use Jinja2 templates for configuration files instead of copying static files.

## Rules

- Use `template` module instead of `copy` for config files
- Leverage Jinja2 templating for dynamic content
- Store templates in `templates/` directory
- Use conditionals, loops, and filters in templates
- Keep templates readable and well-documented

## Example

```yaml
# tasks/main.yml
- name: Configure application
  template:
    src: app.conf.j2
    dest: /etc/app/app.conf
    owner: root
    group: root
    mode: '0644'

# templates/app.conf.j2
server {
    listen {{ app_port }};
    server_name {{ app_domain }};

    {% if ssl_enabled %}
    ssl_certificate {{ ssl_cert_path }};
    ssl_certificate_key {{ ssl_key_path }};
    {% endif %}

    {% for location in app_locations %}
    location {{ location.path }} {
        proxy_pass {{ location.backend }};
    }
    {% endfor %}
}
```

---

# Use Tags for Selective Execution

> Tag tasks for logical grouping so playbooks can be run selectively with `--tags` and `--skip-tags`.

## Rules

- Tag related tasks for logical grouping
- Use descriptive tag names
- Tag tasks that are commonly run independently
- Use `--tags` and `--skip-tags` for selective execution
- Consider using `always` and `never` tags for tasks that should always or never run by default

## Example

```yaml
- name: Install packages
  package:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - python3
  tags:
    - packages
    - install

- name: Configure application
  template:
    src: app.conf.j2
    dest: /etc/app/app.conf
  tags:
    - config
    - deploy

- name: Restart service
  systemd:
    name: app
    state: restarted
  tags:
    - deploy
    - restart
```

---

# Use Facts Wisely

> Leverage Ansible facts for host-aware conditional logic, but disable gathering when not needed for performance.

## Rules

- Facts are gathered automatically unless `gather_facts: false`
- Use `setup` module to inspect available facts
- Cache facts when possible using fact caching
- Use facts for conditional logic based on host properties
- Create custom facts when needed
- Disable fact gathering when not needed for performance

## Example

```yaml
- name: Configure based on OS
  hosts: all
  gather_facts: true
  tasks:
    - name: Install package (Debian)
      apt:
        name: nginx
        state: present
      when: ansible_os_family == "Debian"

    - name: Install package (RedHat)
      yum:
        name: nginx
        state: present
      when: ansible_os_family == "RedHat"

    - name: Configure based on memory
      template:
        src: config.j2
        dest: /etc/app/config
      vars:
        worker_processes: "{{ (ansible_memtotal_mb / 512) | int }}"
```

---

# Use Blocks for Error Handling

> Group related tasks in blocks with `rescue` and `always` sections for structured error handling and guaranteed cleanup.

## Rules

- Group related tasks in blocks
- Use `rescue` section for error handling and rollback
- Use `always` section for cleanup tasks that must run regardless of success or failure
- Combine with `ignore_errors` sparingly
- Do not hide real errors behind overly broad rescue blocks

## Example

```yaml
- name: Deploy application
  block:
    - name: Stop application
      systemd:
        name: app
        state: stopped

    - name: Copy new version
      copy:
        src: app.jar
        dest: /opt/app/app.jar

    - name: Start application
      systemd:
        name: app
        state: started

  rescue:
    - name: Restore previous version
      command: cp /opt/app/app.jar.backup /opt/app/app.jar

    - name: Start application
      systemd:
        name: app
        state: started

    - name: Notify failure
      debug:
        msg: "Deployment failed, restored previous version"

  always:
    - name: Cleanup temporary files
      file:
        path: /tmp/deploy
        state: absent
```

---

# Use Vault for Secrets

> Encrypt all sensitive data with Ansible Vault -- never commit unencrypted secrets.

## Rules

- Encrypt sensitive variables with `ansible-vault encrypt`
- Store encrypted files in version control safely
- Use separate vault files for different environments
- Use `--ask-vault-pass` or vault password files for decryption
- Never commit unencrypted secrets
- Rotate vault passwords regularly

## Example

```bash
# Create encrypted variable file
ansible-vault create group_vars/production/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/production/vault.yml

# Encrypt existing file
ansible-vault encrypt group_vars/production/secrets.yml
```

```yaml
# group_vars/production/vault.yml (encrypted)
db_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  663864396539663164356362656636...

api_key: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  3234323432343234323432343234...
```

---

# Use Inventories Effectively

> Organize inventories with logical host grouping and use `group_vars`/`host_vars` for per-group configuration.

## Rules

- Use INI or YAML format for inventories
- Group hosts logically by environment, function, or location
- Use `group_vars` and `host_vars` for configuration
- Use inventory plugins for dynamic inventories
- Keep inventories in version control

## Example

```ini
# inventories/production/hosts.ini
[webservers]
web1.example.com ansible_host=10.0.1.10
web2.example.com ansible_host=10.0.1.11

[dbservers]
db1.example.com ansible_host=10.0.2.10

[webservers:vars]
nginx_version=1.20
ssl_enabled=true

[dbservers:vars]
mysql_version=8.0
```

```yaml
# inventories/production/hosts.yml
all:
  children:
    webservers:
      hosts:
        web1.example.com:
          ansible_host: 10.0.1.10
        web2.example.com:
          ansible_host: 10.0.1.11
      vars:
        nginx_version: 1.20
    dbservers:
      hosts:
        db1.example.com:
          ansible_host: 10.0.2.10
```

---

# Use Conditional Logic Appropriately

> Use `when` clauses to make tasks adapt to different OS families, environments, and host states.

## Rules

- Use `when` clause for task-level conditionals
- Combine conditions with `and`, `or`, `not`
- Use facts and variables in conditions
- Keep conditions readable
- Use `failed_when` and `changed_when` for complex scenarios
- Avoid deeply nested conditionals

## Example

```yaml
- name: Install package (Debian)
  apt:
    name: nginx
    state: present
  when: ansible_os_family == "Debian"

- name: Install package (RedHat)
  yum:
    name: nginx
    state: present
  when: ansible_os_family == "RedHat"

- name: Configure SSL
  template:
    src: ssl.conf.j2
    dest: /etc/nginx/ssl.conf
  when:
    - ssl_enabled | default(false)
    - ssl_cert_path is defined
    - ssl_key_path is defined

- name: Restart service
  systemd:
    name: nginx
    state: restarted
  when: nginx_config_changed | default(false)
```

---

# Use Loops Efficiently

> Use `loop` for iteration over lists and `until` for retries -- prefer `loop` over the deprecated `with_items`.

## Rules

- Use `loop` for simple iteration (preferred over `with_items`)
- Use `loop_control` for better variable names and labels
- Use `until` for retry loops
- Combine with `when` for conditional loops
- Use `include_tasks` with loops for complex scenarios
- Avoid nested loops when possible

## Example

```yaml
- name: Install multiple packages
  package:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - python3
    - curl
  loop_control:
    label: "{{ item }}"

- name: Create users
  user:
    name: "{{ item.name }}"
    uid: "{{ item.uid }}"
    groups: "{{ item.groups }}"
  loop:
    - name: alice
      uid: 1001
      groups: sudo,www-data
    - name: bob
      uid: 1002
      groups: www-data

- name: Wait for service
  uri:
    url: "http://localhost:{{ item }}/health"
    status_code: 200
  loop: [8080, 8081, 8082]
  until: result.status == 200
  retries: 10
  delay: 5
```

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **ansible-lint** — lint Ansible playbooks and roles: `ansible-lint`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
