# Accounts Module CHANGELOG

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
