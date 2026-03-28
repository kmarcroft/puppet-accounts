# @summary Manage a Linux/Unix group and optionally its members.
#
# @param groupname
#   The group name. Defaults to the resource title.
# @param ensure
#   Whether the group should be present or absent.
# @param members
#   List of usernames to be members of the group.
# @param auth_membership
#   Whether to enforce that only listed members belong to the group.
# @param gid
#   Optional numeric GID to force for the group.
# @param forcelocal
#   When true, forces management of local groups even when LDAP/AD is configured.
# @param provider
#   Group management provider. Defaults to 'gpasswd'.
define accounts::group (
  String                             $groupname = $title,
  Enum['present', 'absent']          $ensure = 'present',
  Array[String]                      $members = [],
  Boolean                            $auth_membership = true,
  Optional[Variant[String, Integer]] $gid = undef,
  Boolean                            $forcelocal = false,
  String                             $provider = 'gpasswd',
) {
  # avoid problems when group declared elsewhere
  ensure_resource('group', $groupname, {
      'ensure'          => $ensure,
      'gid'             => $gid,
      'members'         => sort(unique($members)),
      'auth_membership' => $auth_membership,
      'forcelocal'      => $forcelocal,
      'provider'        => $provider,
  })
}
