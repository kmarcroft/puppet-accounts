# @summary Manage authorized SSH keys for a user account.
#
# @param home_dir
#   The user's home directory path.
# @param ssh_keys
#   Hash of SSH public keys to authorise. Each key entry should include 'type' and 'key'.
# @param gid
#   The primary group ID (used for file ownership when ssh_dir is templated).
# @param ssh_dir_owner
#   Owner of the .ssh directory and authorized_keys file. Defaults to the resource title.
# @param ssh_dir_group
#   Group of the .ssh directory and authorized_keys file. Defaults to the resource title.
# @param ssh_key_source
#   Optional path to a file providing the full authorized_keys content (overrides ssh_keys).
# @param username
#   The user account name. Defaults to the resource title.
# @param authorized_keys_file
#   Optional absolute path to the authorized_keys file. Defaults to ~/.ssh/authorized_keys.
# @param ensure
#   Whether the authorized_keys file should be present or absent.
# @param manage_ssh_dir
#   Whether this define should manage the .ssh directory resource.
define accounts::authorized_keys (
  Stdlib::Absolutepath $home_dir,
  Hash $ssh_keys = {},
  Variant[String, Integer] $gid = $title,
  Variant[String, Integer] $ssh_dir_owner = $title,
  Variant[String, Integer] $ssh_dir_group = $title,
  Optional[Stdlib::Absolutepath] $ssh_key_source = undef,
  String $username = $title,
  Optional[String] $authorized_keys_file = undef,
  Enum['present', 'absent'] $ensure = 'present',
  Boolean $manage_ssh_dir = true,
) {
  if $authorized_keys_file {
    $ssh_dir = accounts_parent_dir($authorized_keys_file)
    $auth_key_file = $authorized_keys_file
  } else {
    $ssh_dir = "${home_dir}/.ssh"
    $auth_key_file = "${ssh_dir}/authorized_keys"
  }

  if $manage_ssh_dir {
    ensure_resource('file', $ssh_dir, {
        'ensure'  => directory,
        'owner'   => $ssh_dir_owner,
        'group'   => $ssh_dir_group,
        'mode'    => '0700',
        'require' => File[$home_dir],
    })
  }

  $key_require = $manage_ssh_dir ? {
    true  => File[$ssh_dir],
    false => File[$home_dir],
  }

  # Error: Use of reserved word: type, must be quoted if intended to be a String value
  $ssh_key_defaults = {
    ensure  => present,
    user    => $username,
    'type'  => 'ssh-rsa', # intentional quotes! (Puppet 4 compatibility)
    target  => $auth_key_file,
    require => $key_require,
  }

  if ($ssh_dir_owner != $title or $ssh_dir_group != $gid) {
    # manage authorized keys from template
    File<| title == $auth_key_file |> {
      content => template("${module_name}/authorized_keys.erb"),
    }
  } elsif !empty($ssh_keys) {
    # ssh_authorized_key does not support changing key owner
    create_resources('ssh_authorized_key', $ssh_keys, $ssh_key_defaults)
  }

  if $ssh_key_source {
    File<| title == $auth_key_file |> {
      source  => $ssh_key_source,
    }
  }

  file { $auth_key_file:
    ensure  => $ensure,
    owner   => $ssh_dir_owner,
    group   => $ssh_dir_group,
    mode    => '0600',
    require => File[$home_dir],
  }
}
