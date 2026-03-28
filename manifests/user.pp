# @summary Manage a Linux/Unix user account with optional SSH keys and password.
#
# @param username
#   The user account name. Defaults to the resource title.
# @param ensure
#   Whether the user should be present or absent.
# @param uid
#   Optional numeric or string UID to force.
# @param gid
#   Optional GID to force for the user's login group.
# @param primary_group
#   Name or ID of the user's primary group. Defaults to the username.
# @param comment
#   GECOS/description field, typically the user's full name.
# @param groups
#   Additional groups the user should belong to.
# @param ssh_key_source
#   Path to a file to use as the authorized_keys source (overrides ssh_keys).
# @param ssh_keys
#   Hash of SSH public keys to add to the user's authorized_keys file.
# @param ssh_key_groups
#   Array of SSH key group names (defined in accounts::ssh_key_groups) whose keys
#   are merged into this user's authorized_keys. Individual ssh_keys take precedence.
# @param purge_ssh_keys
#   When true, remove any SSH keys not explicitly listed in ssh_keys.
# @param shell
#   Login shell for the user.
# @param pwhash
#   Pre-hashed password string. Mutually exclusive with $password.
# @param password
#   Cleartext password; hashed using $hash and $salt. Mutually exclusive with $pwhash.
# @param salt
#   Optional explicit salt for hashing $password (max 16 chars: A-Za-z0-9./).
#   When unset the salt is read from the salts fact or generated on first run.
# @param hash
#   Hash algorithm for $password. See stdlib pw_hash() for valid values.
# @param managehome
#   Whether to manage the user's home directory.
# @param hushlogin
#   When true, create a .hushlogin file in the home directory to suppress MOTD.
# @param manage_group
#   When true, create a primary group matching the account name (or $primary_group).
# @param manageumask
#   When true, set the user's umask via ~/.bash_profile and ~/.bashrc.
# @param umask
#   Umask value to write when $manageumask is true.
# @param home
#   Absolute path to the user's home directory. Defaults to /home/$username.
# @param recurse_permissions
#   Whether to recursively manage permissions on the home directory.
# @param authorized_keys_file
#   Absolute path to a custom authorized_keys file.
# @param force_removal
#   When true, kill the user's running processes before removing the account.
# @param destroy_home_on_remove
#   When true and ensure => absent, remove the home directory with rm -rf.
# @param populate_home
#   When true, populate the home directory from $home_directory_contents.
# @param home_directory_contents
#   Puppet file source URI used when $populate_home is true.
# @param password_max_age
#   Maximum number of days before the password must be changed.
# @param allowdupe
#   Whether to allow duplicate UIDs.
# @param home_permissions
#   File mode for the home directory.
# @param manage_ssh_dir
#   Whether to manage the .ssh directory inside the home directory.
# @param forcelocal
#   When true, forces management of local accounts even when LDAP/AD is configured.
# @param ssh_dir_owner
#   Owner of the .ssh directory and authorized_keys file.
# @param ssh_dir_group
#   Group of the .ssh directory and authorized_keys file.
#
define accounts::user (
  # lint:ignore:only_variable_string
  # Workaround for https://tickets.puppetlabs.com/browse/PUP-4332
  # See https://github.com/deric/puppet-accounts/pull/11 for details
  String                             $username               = "${title}",
  # lint:endignore
  Enum['present', 'absent']          $ensure                 = 'present',
  Optional[Variant[String, Integer]] $uid                    = undef,
  Optional[Variant[String, Integer]] $gid                    = undef,
  Optional[Variant[String, Integer]] $primary_group          = undef,
  Optional[String]                   $comment                = undef,
  Array                              $groups                 = [],
  Optional[Stdlib::Absolutepath]     $ssh_key_source         = undef,
  Hash                               $ssh_keys               = {},
  Array                              $ssh_key_groups         = [],
  Boolean                            $purge_ssh_keys         = false,
  String                             $shell                  = '/bin/bash',
  Optional[String]                  $pwhash                 = undef,
  Optional[String]                   $password               = undef,
  Optional[String]                   $salt                   = undef,
  String                             $hash                   = 'SHA-512',
  Boolean                            $managehome             = true,
  Boolean                            $hushlogin              = false,
  Boolean                            $manage_group           = true,
  Boolean                            $manageumask            = false,
  String                             $umask                  = '0022',
  Optional[Stdlib::Absolutepath]     $home                   = undef,
  Boolean                            $recurse_permissions    = false,
  Optional[Stdlib::Absolutepath]     $authorized_keys_file   = undef,
  Boolean                            $force_removal          = true,
  Boolean                            $destroy_home_on_remove = false,
  Boolean                            $populate_home          = false,
  String                             $home_directory_contents = 'puppet:///modules/accounts',
  Optional[Integer]                  $password_max_age       = undef,
  Boolean                            $allowdupe              = false,
  String                             $home_permissions       = '0700',
  Boolean                            $manage_ssh_dir         = true,
  Boolean                            $forcelocal             = false,
  Optional[Variant[String, Integer]] $ssh_dir_owner          = undef,
  Optional[Variant[String, Integer]] $ssh_dir_group          = undef,
) {
  if $pwhash and $password {
    fail("You cannot set both \$pwhash and \$password for ${username}.")
  }
  if $password {
    # explicit salt given — validate format then use it.
    if $salt {
      unless $salt =~ /^[A-Za-z0-9\.\/]{0,16}$/ {
        fail("Salt for ${username} must be up to 16 characters from [A-Za-z0-9./].")
      }
      $_salt = $salt
      # if no explicit salt is given, try to get it from fact or generate
      # (generation thus only on first run, when user is not present)
    } else {
      if $facts['salts'] =~ Hash {
        $_salts = $facts['salts']
      } else {
        $_salts = {}
      }
      if ! $_salts[$title] {
        $_salt = fqdn_rand_string(16, undef, "User[${title}]")
      } else {
        $_salt = $_salts[$title]
      }
    }
    if !$hash {
      fail('You need to specify a hash function for hashing cleartext passwords.')
    }
  }

  if ($gid) {
    $real_gid = $gid
  } else {
    # Actuall primary group assignment is done later
    # intentionally omitting primary group in order to avoid dependency cycles
    # see https://github.com/deric/puppet-accounts/issues/39
    if $ensure == 'present' and $manage_group == true {
      # choose first non empty argument
      $real_gid = pick($primary_group, $username)
    } else {
      # see https://github.com/deric/puppet-accounts/issues/41
      $real_gid = undef
    }
  }

  $_ssh_dir_owner = pick($ssh_dir_owner, $username)
  $_ssh_dir_group = pick($ssh_dir_group, $real_gid, $username)

  if $home {
    $home_dir = $home
  } else {
    $home_dir = $username ? {
      'root'  => '/root',
      default => "/home/${username}",
    }
  }

  User<| title == $username |> {
    gid        => $real_gid,
    comment    => $comment,
    managehome => $managehome,
    home       => $home_dir,
  }

  case $ensure {
    'absent': {
      if $managehome == true and $destroy_home_on_remove == true {
        exec { "rm -rf ${home_dir}":
          path   => ['/bin', '/usr/bin'],
          onlyif => "test -d ${home_dir}",
        }
      }

      # when user is logged in we couldn't remove the account, issue #23
      user { $username:
        ensure => absent,
        uid    => $uid,
      }

      if $force_removal {
        exec { "killproc ${name}":
          command     => "pkill -TERM -u ${name}; sleep 1; skill -KILL -u ${name}",
          path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
          onlyif      => "id ${name}",
          refreshonly => true,
          before      => User[$username],
        }
      }

      if $manage_group == true {
        $pg_name = $primary_group ? {
          undef   => $username,
          default => $primary_group
        }
        group { $pg_name:
          ensure  => absent,
          gid     => $real_gid,
          require => User[$username],
        }
      }
    }
    'present': {
      user { $username:
        ensure           => present,
        uid              => $uid,
        shell            => $shell,
        allowdupe        => $allowdupe,
        forcelocal       => $forcelocal,
        purge_ssh_keys   => $purge_ssh_keys,
        password_max_age => $password_max_age,
      }

      # Set password if available
      if $pwhash {
        User<| title == $username |> { password => $pwhash }
      }
      # Work on cleartext password if available
      if $password {
        $pwh = pw_hash($password, $hash, $_salt)
        User<| title == $username |> { password => $pwh }
      }

      if $managehome == true {
        if $populate_home == true {
          file { $home_dir:
            ensure  => directory,
            owner   => $username,
            group   => $real_gid,
            recurse => 'remote',
            mode    => $home_permissions,
            source  => "${home_directory_contents}/${username}",
          }
        }
        else {
          file { $home_dir:
            ensure  => directory,
            owner   => $username,
            group   => $real_gid,
            recurse => $recurse_permissions,
            mode    => $home_permissions,
          }
        }

        # see https://github.com/deric/puppet-accounts/pull/44
        if $manageumask == true {
          file_line { "umask_line_profile_${username}":
            ensure  => present,
            path    => "${home_dir}/.bash_profile",
            line    => "umask ${umask}",
            match   => '^umask \+[0-9][0-9][0-9]',
            require => File[$home_dir],
          }
          -> file_line { "umask_line_bashrc_${username}":
            ensure => present,
            path   => "${home_dir}/.bashrc",
            line   => "umask ${umask}",
            match  => '^umask \+[0-9][0-9][0-9]',
          }
        }

        if $hushlogin == true {
          file { "${home_dir}/.hushlogin":
            ensure => file,
            owner  => $username,
            group  => $real_gid,
            mode   => $home_permissions,
          }
        } else {
          file { "${home_dir}/.hushlogin":
            ensure => absent,
          }
        }

        # Resolve SSH key groups into a merged hash of keys
        $mapped_ssh_keys = $ssh_key_groups.reduce({}) |$memo, $key_group| {
          if ($key_group in $accounts::ssh_key_groups) {
            $memo + $accounts::ssh_key_groups[$key_group]
          } else {
            fail("accounts::user ${username}: ssh_key_group '${key_group}' does not exist!")
          }
        }

        accounts::authorized_keys { $username:
          ssh_keys             => $mapped_ssh_keys + $ssh_keys,
          ssh_key_source       => $ssh_key_source,
          authorized_keys_file => $authorized_keys_file,
          home_dir             => $home_dir,
          manage_ssh_dir       => $manage_ssh_dir,
          ssh_dir_owner        => $_ssh_dir_owner,
          ssh_dir_group        => $_ssh_dir_group,
          gid                  => $real_gid,
          require              => File[$home_dir],
        }
      }
    }
    # other ensure value is not possible (exception would be thrown earlier)
    default: {}
  }
}
