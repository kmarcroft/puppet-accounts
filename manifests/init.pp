# @summary Manage user accounts, groups, and SSH authorized keys.
#
# @param manage_users
#   Whether to manage user accounts defined in $users.
# @param manage_groups
#   Whether to manage groups and group membership from $groups.
# @param users
#   Hash of user definitions, merged with Hiera data when $use_lookup is true.
# @param groups
#   Hash of group definitions, merged with Hiera data when $use_lookup is true.
# @param user_defaults
#   Default attributes merged into every user resource.
# @param options
#   System-wide configuration options forwarded to accounts::config.
# @param use_lookup
#   When true, class parameters are augmented from Hiera. Set false in tests.
# @param home_permissions
#   Default file mode for user home directories. Resolved from module Hiera data.
class accounts (
  Boolean $manage_users     = true,
  Boolean $manage_groups    = true,
  Hash    $users            = {},
  Hash    $groups           = {},
  Hash    $user_defaults    = {},
  Hash    $options          = {},
  Boolean $use_lookup       = true,
  String  $home_permissions = '0700',
) {
  # puppet should automatically resolve class parameters from hiera
  if $use_lookup {
    # merge behaviour (3rd argument) is intentionally omitted so it can be
    # overridden in hiera configs
    $users_h         = lookup('accounts::users', Hash, undef, {})
    $groups_h        = lookup('accounts::groups', Hash, undef, {})
    $user_defaults_h = lookup('accounts::user_defaults', Hash, undef, {})
    $options_h       = lookup('accounts::config', Hash, undef, {})
  } else {
    $users_h         = {}
    $groups_h        = {}
    $user_defaults_h = {}
    $options_h       = {}
  }

  $_users = merge($users, $users_h)

  class { 'accounts::config':
    options => merge($options, $options_h),
  }

  if $manage_users {
    $udef = merge($user_defaults, $user_defaults_h, {
        home_permissions => $home_permissions,
        require          => Class['accounts::config'],
    })
    create_resources(accounts::user, $_users, $udef)
  }

  if $manage_groups {
    $_groups = merge($groups, $groups_h)

    if has_key($user_defaults, 'groups') {
      $default_groups = $user_defaults['groups']
    } else {
      $default_groups = []
    }
    # Merge group definition with user assignments
    $members = accounts_group_members($_users, $_groups, $default_groups)
    create_resources(accounts::group, $members)
  }
}
