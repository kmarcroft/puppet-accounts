# Accounts Module CHANGELOG

## 3.1.0 - March 28th 2026

### New features

 * **`ssh_key_groups` parameter** — Define reusable collections of SSH keys at the
   class level and assign them to users by group name:
   ```yaml
   accounts::ssh_key_groups:
     devops:
       deployer_key:
         type: ssh-rsa
         key: "AAAA..."
   accounts::users:
     john:
       ssh_key_groups:
         - devops
   ```
   Implemented from upstream PR #100.
 * **`forcelocal` parameter** on `accounts::user` and `accounts::group` — Pass
   through to native Puppet `user`/`group` resources for managing local accounts
   when LDAP/AD is configured. Defaults to `false`. Implemented from upstream
   PR #90.

### Bug fixes

 * **GID now correctly set on user resources** — Uncommented `gid => $real_gid` in
   the User resource override so that `primary_group` is actually applied.
   Fixes upstream issues #87 and #77. Implemented from upstream PR #93.
 * **Quoted `$home_dir` in `rm -rf` exec** — The home-directory removal command
   on user absent now properly quotes the path, preventing command breakage from
   paths with spaces or special characters. Addresses upstream issue #84.

## 3.0.1 - March 28th 2026

### Cleanup & alignment

 * **Removed legacy CI/testing leftovers:**
   - Deleted `.travis.yml` (replaced by GitHub Actions).
   - Deleted all Beaker acceptance nodesets (`spec/acceptance/nodesets/`) —
     referenced EOL operating systems (CentOS 7, Debian 8/9, SLES 13, Ubuntu 14.04)
     and Puppet 3.x–6.x.
   - Deleted `spec/spec_helper_acceptance.rb` (beaker-rspec) and
     `spec/spec_helper_system.rb` (rspec-system-puppet) — both deprecated frameworks.
   - Deleted `Puppetfile` — redundant with `.fixtures.yml`.
   - Deleted `Makefile` — trivial YAML checker not used in CI.
 * **Removed Puppet 3.x parser functions:**
   - Deleted `lib/puppet/parser/functions/accounts_group_members.rb` and
     `lib/puppet/parser/functions/accounts_parent_dir.rb` — modern
     `Puppet::Functions` API versions already exist in `lib/puppet/functions/`.
 * **Removed `assert_private` stub** from `spec/spec_helper.rb` — not needed for
   Puppet 7+.
 * **Removed `serverspec` gem** from Gemfile (beaker leftover).
 * **Removed `:acceptance` rake task** from Rakefile (depended on deleted beaker
   infrastructure).
 * **Modernized `spec/spec_helper.rb`** to PDK-standard pattern: default_facts
   merging from YAML files, strict mode, `strict_variables`, coverage reporting,
   and backtrace filtering.
 * **Aligned CI env var** `PUPPET_VERSION` → `PUPPET_GEM_VERSION` to match the PDK
   convention.
 * **Added OracleLinux 8/9/10** to `operatingsystem_support` in metadata.json.
 * **Added PDK standard files:** `.gitattributes`, `.pdkignore`, `pdk.yaml`.
 * **Added `tags` and `pdk-version`/`template-url`/`template-ref`** fields to
   metadata.json.
 * **GitHub Actions:** Updated `actions/checkout` from v4 to v5 (Node.js 22);
   added `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true` to eliminate deprecation
   warnings for `actions/upload-artifact@v4` and `softprops/action-gh-release@v2`.
 * **Updated README:** added Oracle Linux to OS table, modernized Testing section
   to reference PDK and GitHub Actions CI, removed references to deleted
   acceptance test infrastructure.

## 3.0.0 - March 28th 2026

This is a maintained fork of [deric/puppet-accounts](https://github.com/deric/puppet-accounts).
Many thanks to **Tomas Barton** (original author) and all previous contributors.

### Breaking changes
 * **Minimum Puppet version raised to 7.0** — Puppet 4/5/6 are no longer supported.
 * `accounts::params` class is **deprecated**; OS-specific defaults are now provided
   via module-level Hiera data (`data/os/<family>.yaml`).  The `inherits
   accounts::params` pattern has been removed from `accounts` in favour of a
   plain `$home_permissions` parameter resolved through module data.
 * `$::osfamily` top-scope fact replaced with `$facts['os']['family']` throughout
   all manifests.
 * `$::salts` top-scope fact replaced with `$facts['salts']` in `accounts::user`.
 * `validate_re()` / `validate_string()` (deprecated stdlib functions) replaced
   with Puppet native type enforcement.

### New features & improvements
 * **Puppet 8.x / OpenVox 8.x** fully supported.
 * Custom functions `accounts_group_members` and `accounts_parent_dir` rewritten
   using the modern `Puppet::Functions` API (`lib/puppet/functions/`).
 * Custom Facter fact `salts` updated to the Facter 4 API — no longer uses the
   removed `Facter::Util::Resolution.exec` or `confine :facterversion` block.
 * Module-level `hiera.yaml` and `data/` directory added for OS-family defaults.
 * `Gemfile` updated for PDK 3.x, rspec-puppet 4.x, and puppet_litmus acceptance
   testing (replaces Beaker).
 * `Rakefile` modernised — removed dependency on removed
   `puppet/vendor/semantic` and `librarian-puppet`.
 * `.fixtures.yml` added with Forge module references (replaces Puppetfile +
   librarian-puppet for unit-test fixtures).
 * Spec facts updated from legacy `:osfamily` symbols to modern structured
   `os: { family: '...' }` hashes.
 * `operatingsystem_support` extended: RHEL/CentOS/Rocky/AlmaLinux 8–9,
   Debian 10–12, Ubuntu 20.04–24.04.
 * stdlib dependency updated to `>= 8.0.0 < 10.0.0`.

## 2.1.0

 * remove `assert_private` ([#99](https://github.com/deric/puppet-accounts/issues/99))
 * disable removing home by default ([#84](https://github.com/deric/puppet-accounts/issues/84))

## 2.0.0

 * [BC] drop Puppet 3 compatibility (using Puppet 4 types)
 * `hiera` function replaced by `lookup`
 * [BC] removed `ssh_key` parameter from class `user` (use `ssh_keys` instead)
 * added acceptance tests for Debian
 * tested on Hiera 5 (Hiera 3 supported, but not included in test suites)
