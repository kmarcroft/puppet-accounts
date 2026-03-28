# Puppet Accounts Management

A Puppet module for managing user accounts, groups, and SSH authorized keys with
full Hiera support.

> **Fork notice:** This module is a maintained fork of
> [deric/puppet-accounts](https://github.com/deric/puppet-accounts), updated for
> Puppet 7.x / Puppet 8.x / OpenVox 8.x compatibility with modern PDK tooling.
> See the [Attribution](#attribution) section for the full list of previous
> maintainers and contributors.

## Compatibility

| Module version | Puppet 4.x | Puppet 5/6.x | Puppet 7.x | Puppet 8.x / OpenVox 8.x |
| -------------- | :--------: | :----------: | :--------: | :-----------------------: |
| `1.5.x`        | ✓          | ?            | ✗          | ✗                         |
| `2.0.x`        | ✓          | ✓            | ✗          | ✗                         |
| `2.1.x`        | ?          | ✓            | ✓ (partial)| ✗                         |
| `3.0.x` (this) | ✗          | ✗            | ✓          | ✓                         |

**Requires:** Puppet >= 7.0.0, puppetlabs-stdlib >= 8.0.0

### Supported operating systems

| OS                        | Versions    |
| ------------------------- | ----------- |
| Red Hat Enterprise Linux  | 7, 8, 9, 10 |
| CentOS                    | 7, 8, 9, 10 |
| Oracle Linux              | 8, 9, 10    |
| Rocky Linux               | 8, 9, 10    |
| AlmaLinux                 | 8, 9, 10    |
| Debian                    | 10, 11, 12, 13 |
| Ubuntu                    | 20.04, 22.04, 24.04 |

Origin: https://github.com/deric/puppet-accounts

## Basic usage

```puppet
class { 'accounts': }
```

Or with pure Hiera — include the class in `site.pp`:

```puppet
lookup('classes', { merge => unique }).include
```

Then configure everything in your Hiera hierarchy:

```yaml
classes:
  - 'accounts'

accounts::users:
  myuser:
    groups: ['users']
```

## User accounts

Hiera example with common defaults and per-user configuration:

```yaml
accounts::user_defaults:
  shell: '/bin/bash'
  purge_ssh_keys: true

accounts::groups:
  www-data:
    gid: 33
    members: ['john']

accounts::users:
  john:
    comment: "John Doe"
    groups: ["sudo", "users"]
    shell: "/bin/bash"
    pwhash: "$6$GDH43O5m$FaJsdjUta1wXcITgKekNGUIfrqxYogW"
    ssh_keys:
      'john@doe':
        type: "ssh-rsa"
        key: "AAAA..."
  alice:
    comment: "Alice"
```

For more examples see the [test fixtures](spec/fixtures/hiera/default.yaml).

### Custom home

When no `home` is specified, the directory defaults to `/home/{username}`.

```yaml
accounts::users:
  alice:
    comment: 'Alice'
    home: '/var/alice'
```

### Group management

By default each user has a primary group with the same name.  Disable with
`manage_group`:

```yaml
accounts::users:
  john:
    manage_group: false
    groups:
      - 'users'
      - 'www-data'
```

### Primary group

```yaml
accounts::users:
  john:
    primary_group: 'doe'
    manage_group: true
    groups:
      - 'sudo'
```

The value may be a group name or a numeric GID.  Setting `gid` directly has the
same effect; `manage_group` is ignored when `gid` is set.

### Account removal

```yaml
accounts::users:
  john:
    ensure: 'absent'
    managehome: true
```

Setting `managehome: true` also removes the home directory.

### Root account

```yaml
accounts::users:
  root:
    ssh_keys:
      'mykey1':
        type: 'ssh-rsa'
        key: 'AAAA....'
      'otherkey':
        type: 'ssh-dsa'
        key: 'AAAAB...'
```

### Additional SSH key options

See the [sshd authorized_keys documentation](http://man.openbsd.org/sshd.8#AUTHORIZED_KEYS_FILE_FORMAT)
for a full list of options.

```yaml
accounts::users:
  foo:
    ssh_keys:
      'mykey1':
        type: 'ssh-rsa'
        key: 'AAAA....'
        options:
          - 'permitopen="10.4.3.29:3306"'
          - 'no-port-forwarding'
          - 'no-X11-forwarding'
          - 'command="/path/to/script.sh arg1 $SSH_ORIGINAL_COMMAND"'
```

### Password management

Provide a pre-hashed password:

```yaml
accounts::users:
  john:
    pwhash: "$6$GDH43O5m$FaJsdjUta1wXcITgKekNGUIfrqxYogW"
```

Or a cleartext password via hiera-eyaml (never commit plaintext):

```yaml
accounts::users:
  john:
    password: >
      ENC[PKCS7,MIIBe...]
    ensure: present
```

The hashing salt is generated with `fqdn_rand_string` on first run and then
persisted via the custom `salts` Facter fact, so password changes reuse the
same salt.

## User parameter reference

| Parameter               | Default                   | Description |
| ----------------------- | ------------------------- | ----------- |
| `authorized_keys_file`  | `~/.ssh/authorized_keys`  | Custom authorized_keys path |
| `purge_ssh_keys`        | `false`                   | Remove keys not listed in Puppet |
| `ssh_key_source`        | —                         | File source for authorized_keys |
| `pwhash`                | `''`                      | Pre-hashed password |
| `password`              | —                         | Cleartext password (mutually exclusive with `pwhash`) |
| `salt`                  | random / fact-based       | Salt for hashing (max 16 chars: `[A-Za-z0-9./]`) |
| `hash`                  | `'SHA-512'`               | Hash function for `password` (see stdlib `pw_hash`) |
| `force_removal`         | `true`                    | Kill user processes before account removal |
| `hushlogin`             | `false`                   | Create `.hushlogin` to suppress MOTD |
| `ssh_dir_owner`         | username                  | Owner of `.ssh/` directory |
| `ssh_dir_group`         | username                  | Group of `.ssh/` directory |
| `manage_ssh_dir`        | `true`                    | Whether to manage `.ssh/` directory |

### `umask`

Per-user umask via `~/.bash_profile` and `~/.bashrc`:

```yaml
accounts::users:
  john:
    manageumask: true
    umask: '022'
```

## Global settings

```yaml
accounts::user_defaults:
  shell: '/bin/dash'
  groups: ['users']
  hushlogin: true
```

### System-wide configuration

Affects all user accounts, including those managed outside this module.

```yaml
accounts::config:
  first_uid: 1000
  last_uid:  99999
  first_gid: 1000
  last_gid:  99999
  umask: '077'
```

### Populate home folder

```yaml
accounts::users:
  john:
    populate_home: true
    home_directory_contents: 'puppet:///modules/accounts'
```

Defaults to `puppet:///modules/accounts/{username}`.

## Hiera configuration

Hiera 5 example `hiera.yaml`:

```yaml
---
version: 5
defaults:
  datadir: hieradata
  data_hash: yaml_data
hierarchy:
  - name: "Common"
    path: "common.yaml"
```

Use `lookup_options` for deep merging:

```yaml
lookup_options:
  "^accounts::(.*)":
    merge:
      strategy: deep
```

## Without Hiera

```puppet
class { 'accounts':
  users => { 'john' => { 'comment' => 'John Doe' } },
}
```

With multiple groups:

```puppet
class { 'accounts':
  groups => {
    'users'  => { 'gid' => 100 },
    'puppet' => { 'gid' => 111 },
  },
  users => {
    'john' => {
      'shell'    => '/bin/bash',
      'groups'   => ['users', 'puppet'],
      'ssh_keys' => {
        'johns_key' => { 'type' => 'ssh-rsa', 'key' => 'public_ssh_key_xxx' },
      },
    },
  },
}
```

## Testing

### Run validation and unit tests

```bash
pdk validate
pdk test unit
```

Or with Bundler directly:

```bash
bundle install
bundle exec rake lint
bundle exec rake spec
```

### CI

This module uses [GitHub Actions](.github/workflows/ci.yml) for automated
metadata validation, syntax checking, puppet-lint, rubocop, and unit tests.
On version tags (`v*`), a module package is built and published as a GitHub
Release.

## Attribution

This module is a fork of [deric/puppet-accounts](https://github.com/deric/puppet-accounts),
originally created and long maintained by **Tomas Barton** and a wide community
of contributors.

We are grateful to all previous maintainers and contributors who made this
module what it is today:

Craig Dunn,
Henning Henkel,
Jeremy T. Bouse,
John Bartko,
Michael Clay,
Michael Gaber,
Oliver Bertuch,
Onur Cem Celebi,
Salimane Adjao Moustapha,
Sebastian Gumprich,
Simon Beirnaert,
Simon Peeters,
Sonia Hamilton,
Stefan Zipkid Goethals,
Steve ESSO,
**Tomas Barton** (original author),
and everyone who filed issues, opened pull requests, or sent feedback.

## License

Apache 2.0
