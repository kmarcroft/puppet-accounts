# frozen_string_literal: true

# @summary
#   From a Hash of all users and their configuration, assign users to the group
#   definitions given as the second argument. An optional third argument provides
#   default groups for all users.
#
# @param users [Hash] Map of username => user attribute hash.
# @param groups [Hash] Map of groupname => group attribute hash.
# @param default_groups [Array] Groups to assign to every user (optional).
# @return [Hash] Merged group hash with member lists populated.
Puppet::Functions.create_function(:accounts_group_members) do
  dispatch :accounts_group_members do
    param 'Hash', :users
    param 'Hash', :groups
    optional_param 'Array', :default_groups
    return_type 'Hash'
  end

  def accounts_group_members(users, groups, default_groups = [])
    # Helper: add +user+ to group +g+ inside the result hash +res+.
    assign_helper = lambda do |res, g, user|
      unless res.key?(g)
        res[g] = { 'members' => [], 'require' => [] }
      else
        res[g]['members'] ||= []
        res[g]['require'] ||= []
      end
      unless user.nil?
        res[g]['members'] << user unless res[g]['members'].include?(user)
        res[g]['require'] << "User[#{user}]"
      end
    end

    res = groups.dup
    users.each do |user, val|
      # Don't assign users marked for removal to groups.
      next if val.key?('ensure') && val['ensure'] == 'absent'

      val = val.dup
      val['primary_group'] = user.to_s unless val.key?('primary_group')
      val['manage_group']  = true       unless val.key?('manage_group')

      if val['manage_group']
        g = val['primary_group']
        assign_helper.call(res, g, nil)
        res[g]['gid'] = val['gid'] if val.key?('gid')
      end

      if val.key?('groups')
        val['groups'].each { |g| assign_helper.call(res, g, user) }
      elsif !default_groups.empty?
        default_groups.each { |g| assign_helper.call(res, g, user) }
      end
    end

    res
  end
end
