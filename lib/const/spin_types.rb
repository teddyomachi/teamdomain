# coding: utf-8
# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'const/vfs_const'
require 'const/acl_const'

module Types
  include Vfs
  include Acl
  
  # group data types
  # for group list
  GROUP_LIST_ALL = 1
  GROUP_LIST_FOLDER = 2
  GROUP_LIST_FILE = 3
  GROUP_LIST_CREATED = 4
  GROUP_MEMBER_LIST_SELECTED = 5
  
end
