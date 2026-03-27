# frozen_string_literal: true

# @summary Returns the parent directory portion of a file path.
#
# @param path [String] An absolute file path.
# @return [String] The directory component (everything up to the last '/').
Puppet::Functions.create_function(:accounts_parent_dir) do
  dispatch :accounts_parent_dir do
    param 'String', :path
    return_type 'String'
  end

  def accounts_parent_dir(path)
    idx = path.rindex('/')
    raise Puppet::ParseError, 'accounts_parent_dir(): path must contain a / separator' if idx.nil?

    path[0...idx]
  end
end
