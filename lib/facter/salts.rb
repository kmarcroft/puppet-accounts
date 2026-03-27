# frozen_string_literal: true

# Custom fact: returns a hash of { username => salt } parsed from /etc/shadow.
# Used by accounts::user to reuse the existing password salt across Puppet runs.
Facter.add('salts') do
  confine kernel: 'Linux'
  confine { File.exist?('/etc/shadow') }

  setcode do
    salts = {}
    File.readlines('/etc/shadow').each do |line|
      parts = line.chomp.split(':')
      next unless parts.length >= 2
      next unless parts[1].include?('$')

      salt_parts = parts[1].split('$')
      salts[parts[0]] = salt_parts[2] if salt_parts.length >= 3
    end
    salts
  end
end
