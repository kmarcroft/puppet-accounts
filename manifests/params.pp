# @summary OS-specific defaults for the accounts module.
#
# This class is kept for backward compatibility only.
# OS-specific defaults are now provided via module Hiera data (data/).
# A deprecation notice will appear if this class is included directly.
#
# @deprecated Use module Hiera data instead.
class accounts::params {
  # Home directory permissions differ by OS family.
  # This default is overridden by module data in data/os/<family>.yaml.
  $home_permissions = $facts['os']['family'] ? {
    'Debian' => '0755',
    default  => '0700',
  }
}
