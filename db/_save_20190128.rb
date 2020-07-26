# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'tasks/security'

# read configuration parameters from secret_files_server_conf.yml file
conf_file_path = './config/secret_files_server_conf.yml'
cf = YAML.load_file(conf_file_path)
server_config = cf['config']

virtual_file_system_config = server_config['virtual_file_systems']
storage_config = server_config['storages']
virtual_storage_config = server_config['virtual_storages']
thumbnail_storage_config = server_config['thumbnail_storages']
virtual_file_server_config = server_config['virtual_file_servers']
virtual_domain_config = server_config['virtual_domains']

# root user
super_user = server_config['super_user']
super_user_passwd = server_config['super_user_passwd']
super_user_home = server_config['super_user_home']
super_user_virtual_home = server_config['super_user_virtual_home']
super_user_domain = virtual_domain_config[0]
super_user_id = server_config['super_user_id']

def self.get_access_mode(mode_str)
# VFS access modes
#   READ_WRITE
#   READ_ONLY
#   WRITE_ONLY
#   WRITE_ONCE
# 'Don't change the order of items in the table!''
  vfs_access_modes = ["DUMMY_MODE", "READ_ONLY", "WRITE_ONLY", "READ_WRITE", "WRITE_ONCE"]

  mode = 0
  vfs_access_modes.each_with_index {|am, idx| am
  if am == mode_str
    mode = idx
    break
  end
  }
  return mode
end

def self.get_storage_logic(logic_str)
# VFS storage logic
#   SPANNING
#   ILM
#   METRIC under LOAD_BALANCE:
#     ROUND_ROBIN ( default )
#     LEAST_FILES
#     LEAST_USAGE
#     FASTEST ( not implemented yet, use default )
# 'Don't change the order of items in the table!''
  vfs_storage_logics = ["SPANNING", "ILM", "ROUND_ROBIN", "LEAST_FILES", "LEAST_USAGE", "FASTEST"]

  mode = 0
  vfs_storage_logics.each_with_index {|sl, idx| sl
  if sl == logic_str
    mode = idx
    break
  end
  }
  return mode
end

#######################################################################################################################
#
# Skip user, group settings.
#
#######################################################################################################################

# => get folder record from the last session
root_user_rec = SpinUser.find_or_create_by(spin_uid: 0, spin_gid: 0, spin_uname: super_user) {|nf|
  nf[:spin_uid] = 0
  nf[:spin_gid] = 0
  nf[:spin_uname] = super_user
  nf[:spin_passwd] = super_user_passwd
  nf[:spin_login_directory] = super_user_virtual_home['hash_key']
  nf[:spin_default_domain] = super_user_domain['domain_hash_key']
  nf[:user_level_x] = 10000
  nf[:user_level_y] = 10000
  nf[:spin_projid] = 0
  nf[:spin_default_server] = "127.0.0.1"
  nf[:activated] = true
}
if root_user_rec.present?
  SpinUser.where(spin_uid: 0, spin_gid: 0, spin_uname: super_user).update_all(spin_passwd: super_user_passwd, user_level_x: 10000, user_level_y: 10000, spin_projid: 0, activated: true)
end

root_user_group_rec = SpinGroup.find_or_create_by(spin_gid: 0) {|nf|
  nf[:spin_gid] = 0
  nf[:spin_group_name] = "super_user"
  nf[:group_descr] = "super user group"
  nf[:owner_id] = 0
  nf[:id_type] = 2
  nf[:lock_version] = 0
}
if root_user_rec.present?
  SpinUser.where(spin_gid: 0).update_all(spin_gid: 0)
end

# setup virtual file systems
#
virtual_file_system_config.each {|svr|
  vfr = SpinVirtualFileSystem.find_or_create_by(spin_vfs_id: svr['vfs_id']) {|vfsr|
    vfsr[:spin_vfs_id] = svr['vfs_id']
    vfsr[:spin_vfs_type] = svr['vfs_type']
    vfsr[:spin_vfs_access_mode] = svr['vfs_access_mode']
    vfsr[:spin_vfs_name] = svr['vfs_name']
    vfsr[:spin_vfs_attributes] = svr['vfs_attributes']
    vfsr[:spin_vfs_storage_logic] = svr['vfs_storage_logic']
    vfsr[:spin_vfs_size] = svr['vfs_size']
    vfsr[:spin_vfs_max_entries] = svr['vfs_max_entries']
    vfsr[:is_default] = svr['vfs_is_default']
  }
  if vfr.present?
    vfr[:spin_vfs_id] = svr['vfs_id']
    vfr[:spin_vfs_type] = svr['vfs_type']
    vfr[:spin_vfs_access_mode] = svr['vfs_access_mode']
    vfr[:spin_vfs_name] = svr['vfs_name']
    vfr[:spin_vfs_attributes] = svr['vfs_attributes']
    vfr[:spin_vfs_storage_logic] = svr['vfs_storage_logic']
    vfr[:spin_vfs_size] = svr['vfs_size']
    vfr[:spin_vfs_max_entries] = svr['vfs_max_entries']
    vfr[:is_default] = svr['vfs_is_default']
    vfr.save
  end
}

# setup virtual storages
#
virtual_storage_config.each {|svr|
  vst = SpinStorage.find_or_create_by(spin_storage_id: svr['storage_id']) {|vr|
    vr[:spin_storage_id] = svr['storage_id']
    vr[:storage_root] = svr['storage_root']
    vr[:spin_vfs_id] = svr['storage_info']['vfs_id']
    vr[:storage_server] = svr['file_storage_server']['host'] + svr['file_storage_server']['port'].to_s
    vr[:master_spin_storage_id] = "MASTER"
    vr[:storage_attributes] = svr['storage_attributes']
    vr[:mapping_logic] = svr['storage_mapping_logic']
    vr[:storage_tmp] = svr['storage_tmp']
    vr[:is_master] = true
    vr[:is_default] = true
    vr[:storage_name] = svr['storage_info']['storage_name']
    vr[:storage_group_max_size] = -1
    vr[:storage_group_max_size_sub] = -1
    vr[:storage_group_max_directories] = -1
    vr[:storage_group_max_directories_sub] = -1
    vr[:storage_group_max_entries] = -1
    vr[:storage_group_max_entries_sub] = -1
    vr[:storage_group_max_entries_per_directory] = 0
    vr[:storage_group_max_entries_per_directory_sub] = 1000
  }
  if vst.present?
    vst[:spin_storage_id] = svr['storage_id']
    vst[:storage_root] = svr['storage_root']
    vst[:spin_vfs_id] = svr['storage_info']['vfs_id']
    vst[:storage_server] = svr['file_storage_server']['host'] + svr['file_storage_server']['port'].to_s
    vst[:master_spin_storage_id] = "MASTER"
    vst[:storage_attributes] = svr['storage_attributes']
    vst[:mapping_logic] = svr['storage_mapping_logic']
    vst[:storage_tmp] = svr['storage_tmp']
    vst[:is_master] = true
    vst[:is_default] = true
    vst[:storage_name] = svr['storage_info']['storage_name']
    vst[:storage_group_max_size] = -1
    vst[:storage_group_max_size_sub] = -1
    vst[:storage_group_max_directories] = -1
    vst[:storage_group_max_directories_sub] = -1
    vst[:storage_group_max_entries] = -1
    vst[:storage_group_max_entries_sub] = -1
    vst[:storage_group_max_entries_per_directory] = 0
    vst[:storage_group_max_entries_per_directory_sub] = 1000
    vst.save
  end
}

# setup thumbnail storages for files
#
thumbnail_storage_config.each {|svr|
  vst = SpinStorage.find_or_create_by(spin_storage_id: svr['storage_id']) {|vr|
    vr[:spin_storage_id] = svr['storage_id']
    vr[:thumbnail_root] = svr['storage_root']
    vr[:spin_vfs_id] = svr['storage_info']['vfs_id']
    vr[:storage_server] = svr['thumbnail_storage_server']['host'] + svr['thumbnail_storage_server']['port'].to_s
    vr[:master_spin_storage_id] = "MASTER"
    vr[:storage_attributes] = svr['storage_attributes']
    vr[:mapping_logic] = svr['storage_mapping_logic']
    vr[:storage_tmp] = svr['storage_tmp']
    vr[:is_master] = true
    vr[:is_default] = true
    vr[:storage_name] = svr['storage_info']['storage_name']
    vr[:storage_group_max_size] = -1
    vr[:storage_group_max_size_sub] = -1
    vr[:storage_group_max_directories] = -1
    vr[:storage_group_max_directories_sub] = -1
    vr[:storage_group_max_entries] = -1
    vr[:storage_group_max_entries_sub] = -1
    vr[:storage_group_max_entries_per_directory] = 0
    vr[:storage_group_max_entries_per_directory_sub] = 1000
  }
  if vst.present?
    vst[:spin_storage_id] = svr['storage_id']
    vst[:thumbnail_root] = svr['storage_root']
    vst[:spin_vfs_id] = svr['storage_info']['vfs_id']
    vst[:storage_server] = svr['thumbnail_storage_server']['host'] + svr['thumbnail_storage_server']['port'].to_s
    vst[:master_spin_storage_id] = "MASTER"
    vst[:storage_attributes] = svr['storage_attributes']
    vst[:mapping_logic] = svr['storage_mapping_logic']
    vst[:storage_tmp] = svr['storage_tmp']
    vst[:is_master] = true
    vst[:is_default] = true
    vst[:storage_name] = svr['storage_info']['storage_name']
    vst[:storage_group_max_size] = -1
    vst[:storage_group_max_size_sub] = -1
    vst[:storage_group_max_directories] = -1
    vst[:storage_group_max_directories_sub] = -1
    vst[:storage_group_max_entries] = -1
    vst[:storage_group_max_entries_sub] = -1
    vst[:storage_group_max_entries_per_directory] = 0
    vst[:storage_group_max_entries_per_directory_sub] = 1000
    vst.save
  end
}

# setup virtual file servers
#
virtual_file_server_config.each {|svr|
  vfs = SpinFileServer.find_or_create_by(server_name: svr['vfs_server_name']) {|vfsc|
    vfsc[:server_host_name] = svr['vfs_server_host_name']
    vfsc[:server_protocol] = svr['server_protocol']
    vfsc[:server_alt_protocols] = svr['server_alt_protocols']
    vfsc[:server_port] = svr['server_port']
    vfsc[:root_user] = super_user
    vfsc[:root_password] = super_user_passwd
    vfsc[:api_path] = svr['api_path']
    vfsc[:max_connections] = svr['max_connections']
    vfsc[:max_pg_connections] = svr['max_pg_connections']
    vfsc[:spin_url_server_name] = svr['spin_url_server_name']
    vfsc[:receive_timeout] = svr['receive_timeout']
    vfsc[:send_timeout] = svr['send_timeout']
    vfsc[:session_timeout] = svr['session_timeout']
  }
  if vfs.present?
    vfs[:server_host_name] = svr['vfs_server_host_name']
    vfs[:server_protocol] = svr['server_protocol']
    vfs[:server_alt_protocols] = svr['server_alt_protocols']
    vfs[:server_port] = svr['server_port']
    vfs[:root_user] = super_user
    vfs[:root_password] = super_user_passwd
    vfs[:api_path] = svr['api_path']
    vfs[:max_connections] = svr['max_connections']
    vfs[:max_pg_connections] = svr['max_pg_connections']
    vfs[:spin_url_server_name] = svr['spin_url_server_name']
    vfs[:receive_timeout] = svr['receive_timeout']
    vfs[:send_timeout] = svr['send_timeout']
    vfs[:session_timeout] = svr['session_timeout']
    vfs.save
  end
}

# setup virtual root node
#
spin_root_node_name = super_user_home['node_name']
spin_root_node_hash_key = super_user_home['hash_key']
spin_virtual_root_node_name = super_user_virtual_home['node_name']
spin_virtual_root_node_hash_key = super_user_virtual_home['hash_key']
spin_root_node_vfs = SpinVirtualFileSystem.find_by_is_default true
spin_root_node_vstorage = SpinStorage.find_by_spin_vfs_id_and_thumbnail_root spin_root_node_vfs[:spin_vfs_id], ''
vrnode = SpinNode.find_or_create_by(node_x_coord: 0, node_y_coord: 0) {|vrn|
  vrn[:spin_node_hashkey] = spin_root_node_hash_key
  vrn[:node_x_coord] = 0
  vrn[:node_y_coord] = 0
  vrn[:node_name] = spin_root_node_name
  vrn[:node_type] = Vfs::NODE_DIRECTORY
  vrn[:node_version] = 0
  vrn[:node_x_pr_coord] = 0
  vrn[:in_trash_flag] = false
  vrn[:is_dirty_flag] = false
  vrn[:is_under_maintenance_flag] = false
  vrn[:in_use_uid] = -1
  vrn[:spin_uid] = 0
  vrn[:spin_gid] = 0
  vrn[:spin_uid_access_right] = 15
  vrn[:spin_gid_access_right] = 7
  vrn[:spin_world_access_right] = 0
  vrn[:created_by] = -1
  vrn[:updated_by] = -1
  vrn[:spin_private_key] = "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAvuhIb4v0iPEjNIuz4up/awweqoLCz1i3l5xJh7YDi/5uwso7
4lr+DVefqWAj8gVcf6m7Sk7qMGYEguzbDUXUmaxUpLC/Hb6dBMar7vT/MTRvqDv0
GDJGrIFwB+PP6gHQh5MeXmt+f8Aaq226gvVCQVf7DJmomFFgm0pVTYd4NQW8Vu8G
ebKrs31MuPZN+LiJi0/j5pjwwvbNIQ9u0sC9f+CDAett6zYbnVs2P3MtcjhRzhhD
/3K+nj8YkPFJrPbuKODFb1eMcFy+wet8zXnNoKxf5qhJ4OgV5KK5+DGf5Mi6MLCY
8Qv6mV+MwNG99SKE6bjysdVzu/BEUzuRT+saUQIDAQABAoIBAD88GaI5LYqetRaW
n8MuAX6nyRCZt4WO0WE6t3BobcxVPsLu0d8sXLJ2r8AexElKVVVEF3GJqjDV2fC0
G+rNkppEZtUWZnenx8LpO9Iu/MiDoeiL01KgdKB3T3CNmTTd3QDLTmfgG0qdizf1
ZK40JvoV9mY6D4pEikdl29OOZ9bHuCoTt2+kvNDmYVOOjfGU8hoAIVbqmBh2bvgl
/IHAAg1/SE6gIsQCciH2WYBa2qoNcfN6R/HT55kmrA37aCJxJT/rjOdW8AHv140y
rUdrIUS6of+mxTysMdhU+9+Hv9zxKm/kYTtbGjTOdQAQB0sh7ebsWoFWfGSTIAUM
AzJe/7ECgYEA+AlT5+2BZs1RgH01XTVRWFAEBxZe2afNjPOMxmyRoJQRpLeW9WOZ
1bHj9KntayF4lEqMDNP9FN3xxJchbksjkr7GcGXB2PSSOSr9+JM+AotwV2eTibko
bXRrd/deYwK6SF0gkAaQHOMuSQJ/93KgHQQLGojb3E7hKSSaAa1eGpcCgYEAxQll
tAq0Wnv/Vf+olQ9o2Ng1sx/+qm8Yv1JjI7VtGUVrFEd+lB+VOCQQ5nbDMB6+8DZf
UKQgUBzff5oPX0CB5Ty24oScK9rkBiq8tkB0lGmsON4TUzIP9h+pIKWZjd5RV1nH
lvPd9ucB1f4hYpAsuui3+CtqjAWF7J8umePnl1cCgYEAhYb3/aZ1gDNOCf7dyJTY
etNwp6QaYdAdLyE6CuQNrcWojeUrxmTdPxZqIp+MKZ02PZa4OHuzBhXJfszheW/H
8cr0JzQQnExln5MOcFBMFLCeRN+EpKLiKbJ/3HB2BpVEVYqU6hQuZu7CTxmibELw
AU7Y72r3+W0Zd721juuW+ncCgYEAjdcn+aXDE2gz9WqnpzaCmad7cMlVgMedHw1m
BOyz7v9ECEM3YdYii1mbOOzBskBP34iksN6VzFYcpjT3X/CGEcnVNdeUvRVEFRRq
6SAZTEWODxn++2MMjndYPwI3OiOSlrkwrwA7B2Rgs/XPfq6fJKYm2WYXu1i2ghJN
b8bajt0CgYB573TzoC3zdK33gYPX8UMrdWk1O5moTmRXoX/nHLUGeJahL/cY5bKv
B74Sqv8ib52+qTFeLtkw+lyzLYmOGSQ37I0fhhmZ9/nhyejaqmRgZhb7uODYNmog
Y0xplrEtK77C3ezKX5/2DKshuzNck31xvrW8H28r/m9dVDoJE5imhw==

-----END RSA PRIVATE KEY-----
"
  vrn[:spin_public_key] = "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvuhIb4v0iPEjNIuz4up/
awweqoLCz1i3l5xJh7YDi/5uwso74lr+DVefqWAj8gVcf6m7Sk7qMGYEguzbDUXU
maxUpLC/Hb6dBMar7vT/MTRvqDv0GDJGrIFwB+PP6gHQh5MeXmt+f8Aaq226gvVC
QVf7DJmomFFgm0pVTYd4NQW8Vu8GebKrs31MuPZN+LiJi0/j5pjwwvbNIQ9u0sC9
f+CDAett6zYbnVs2P3MtcjhRzhhD/3K+nj8YkPFJrPbuKODFb1eMcFy+wet8zXnN
oKxf5qhJ4OgV5KK5+DGf5Mi6MLCY8Qv6mV+MwNG99SKE6bjysdVzu/BEUzuRT+sa
UQIDAQAB
-----END PUBLIC KEY-----
"
  vrn[:rsa_key] = "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAyh357RDK4/Zj9J8S+AQW0Xp++sr2FCbnANZ8TIDJfoE7AmRv
mKG4ZgSj9DF106xop1vmTNgGEg8+7guxxLsf0jPGKJKyGJg6+i065+eWVoS8YY7b
qihqSUFdUygoAlUWlYjrG1UrCLlzryN5WuK8/aYwGN0tH0A+bI8/vzJPYtPOFVtx
nktE2KguxTBb7dY2alTJQZh2K+9qgUZyVN88sOpHMnUEoypmut5wR9F1hYPfql2Z
FwWYEi04v7mTx7Wel7SwfpjHiL2mn7t/XuLn4TL1WDFE7Pl8WMDyQ5DjQO19K0bU
/eMbC6s8uWrbUGEwAsibHWCnmtkn9keYa1WykwIDAQABAoIBAQCtlXMZG+v0Pp73
70qeQPzL6dV2VKtlAUgx2wOjvJPQlvJ0CoghYPr6ew/IYFYedhrnaTDwXDNSfU+B
p/+Dw2X/5MFSBTL5lnxIcmH921KteZBEhSm5CL7HrWCWU42Q+zzLLm0k609rTcLB
7siBuuuvOHRkVkgzZ7x1Bc4syeuOJmxmEwI127h5eFIuovyJtNLS6n1HxtY18LlH
KIGplG9xSsWt5nZxXA3y83q/6yz5bHeHP+Kzz9KTIVGg+I0tm9zA7o6G78mbbOJb
9DPsblY8ORybLElyfvAUibAML7OyPcSgjRU05zk2QPJhaFZC/xwUfi8e5ggCFNbO
FDihR5mhAoGBAPM8EPh9/xRudNf9UUUzX2yJxXzy8JfKD6zUFCz2XvjTyyU7CTxn
Uc5ARcUqXNLmbDTSg2O8WHq7EKsgMbyKBO1XK9TXK/BD/0YfcR7tJ/d0sZn22HJJ
EjR4dkLPoXRzlZKjHbMbleo5TJN1VMqNmqGNNIhxEEbMM45jP6976ERjAoGBANS5
e6EydrkfJU8iobH+k9KIo9r8UVL0rd0NFrkMu0m8oLH1HB877iOxUb+ZRO3GR0dr
RiAtxMcOGArb2DVOy82UaHViN5LQ4OY+e8M1EZE2TnCRxLkxj/zPJCd6YHVIn1of
XEm48lRE1exfzgEG3cHFL47EnWBdkp//M9on1rgRAoGBAOJ5Uh/dSQ1gD2Ewl2RE
ghwQZ5aAqW3bkR7N1P9MYn9yzFqdDmt0lCHjjFMZr5YbQDMqs3XA3+1ekhWUA1tW
c2H94Wzq8BllZqGHEw/Fp4nr2JXP1hcLXG0IoKxyoRVJrcH8KOIk1EBjG57NB6cV
lB3J2VkVVR9mcLaqSJj/WPObAn8uiGSC3ocZ97YxmWHFjerIIxu0y3z+qIdf030k
/aP6fUippPSB4Jo3NJKtVtm9KaJt/QlaAKkK4gpgVbb18kaisdQn2VROyWJo+0IX
cYRmP3rpJPnjiPP2WVmPSTXQchJppHKLrelUhbpF+q8Vimr3+CpvEJNcgRuR5EFz
d0OBAoGBANXVpkJTiIOZR1gzrP1OpODc7WVuU7RxcbICz9zdhzZKeBR+KDeqxtmf
9SOIzfro4LeCScuP+i/P0nq0maU70U5moZ2LjUgUXwYkNqxYpNg8k+4FaGGUHIjG
3hp6TI0ntYPrz8tl4n4Hm56RePNN/gOho5JHyjOfcwXoV9DDogFu
-----END RSA PRIVATE KEY-----
"
  vrn[:max_versions] = 2
  vrn[:node_attributes] = "{\"type\":\"folder\"}"
  vrn[:latest] = true
  vrn[:lock_uid] = -1
  vrn[:is_open_flag] = false
  vrn[:spin_url] = ""
  vrn[:is_pending] = false
  vrn[:spin_vfs_id] = spin_root_node_vfs[:spin_vfs_id]
  vrn[:spin_storage_id] = spin_root_node_vstorage[:spin_storage_id]
  vrn[:user_level_x] = -1
  vrn[:user_level_y] = -1
  vrn[:trashed_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
  vrn[:is_void] = false
  vrn[:is_expanded] = false
  vrn[:is_domain_root_node] = true
  vrn[:spin_updated_at] = Time.now
  vrn[:lock_status] = 0
  vrn[:mtime] = Time.now
  vrn[:ctime] = Time.now
  vrn[:lock_mode] = 0
  vrn[:details] = ""
  vrn[:is_sticky] = false
  vrn[:spin_created_at] = Time.now
  vrn[:virtual_path] = spin_root_node_name
  vrn[:orphan] = false
  vrn[:modifier] = -1
  vrn[:creator] = -1
  vrn[:spin_tree_type] = 0
  vrn[:spin_node_tree] = 0
  vrn[:notified_new_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
  vrn[:notified_modification_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
  vrn[:notified_delete_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
  vrn[:memo1] = ""
  vrn[:memo2] = ""
  vrn[:memo3] = ""
  vrn[:memo4] = ""
  vrn[:memo5] = ""
  vrn[:is_synchronized] = false
  vrn[:is_archive] = false
  vrn[:is_paused] = false
  vrn[:lock_version] = 0
}
# if vrnode.present?
#   vrnode[:spin_node_hashkey] = spin_root_node_hash_key
#   vrnode[:node_x_coord] = 0
#   vrnode[:node_y_coord] = 0
#   vrnode[:node_name] = spin_root_node_name
#   vrnode[:node_type] = Vfs::NODE_DIRECTORY
#   vrnode[:node_version] = 0
#   vrnode[:node_x_pr_coord] = 0
#   vrnode[:in_trash_flag] = false
#   vrnode[:is_dirty_flag] = false
#   vrnode[:is_under_maintenance_flag] = false
#   vrnode[:in_use_uid] = -1
#   vrnode[:spin_uid] = 0
#   vrnode[:spin_gid] = 0
#   vrnode[:spin_uid_access_right] = 15
#   vrnode[:spin_gid_access_right] = 7
#   vrnode[:spin_world_access_right] = 0
#   vrnode[:created_by] = -1
#   vrnode[:updated_by] = -1
#   vrnode[:spin_private_key] = "-----BEGIN RSA PRIVATE KEY-----
# MIIEpAIBAAKCAQEAvuhIb4v0iPEjNIuz4up/awweqoLCz1i3l5xJh7YDi/5uwso7
# 4lr+DVefqWAj8gVcf6m7Sk7qMGYEguzbDUXUmaxUpLC/Hb6dBMar7vT/MTRvqDv0
# GDJGrIFwB+PP6gHQh5MeXmt+f8Aaq226gvVCQVf7DJmomFFgm0pVTYd4NQW8Vu8G
# ebKrs31MuPZN+LiJi0/j5pjwwvbNIQ9u0sC9f+CDAett6zYbnVs2P3MtcjhRzhhD
# /3K+nj8YkPFJrPbuKODFb1eMcFy+wet8zXnNoKxf5qhJ4OgV5KK5+DGf5Mi6MLCY
# 8Qv6mV+MwNG99SKE6bjysdVzu/BEUzuRT+saUQIDAQABAoIBAD88GaI5LYqetRaW
# n8MuAX6nyRCZt4WO0WE6t3BobcxVPsLu0d8sXLJ2r8AexElKVVVEF3GJqjDV2fC0
# G+rNkppEZtUWZnenx8LpO9Iu/MiDoeiL01KgdKB3T3CNmTTd3QDLTmfgG0qdizf1
# ZK40JvoV9mY6D4pEikdl29OOZ9bHuCoTt2+kvNDmYVOOjfGU8hoAIVbqmBh2bvgl
# /IHAAg1/SE6gIsQCciH2WYBa2qoNcfN6R/HT55kmrA37aCJxJT/rjOdW8AHv140y
# rUdrIUS6of+mxTysMdhU+9+Hv9zxKm/kYTtbGjTOdQAQB0sh7ebsWoFWfGSTIAUM
# AzJe/7ECgYEA+AlT5+2BZs1RgH01XTVRWFAEBxZe2afNjPOMxmyRoJQRpLeW9WOZ
# 1bHj9KntayF4lEqMDNP9FN3xxJchbksjkr7GcGXB2PSSOSr9+JM+AotwV2eTibko
# bXRrd/deYwK6SF0gkAaQHOMuSQJ/93KgHQQLGojb3E7hKSSaAa1eGpcCgYEAxQll
# tAq0Wnv/Vf+olQ9o2Ng1sx/+qm8Yv1JjI7VtGUVrFEd+lB+VOCQQ5nbDMB6+8DZf
# UKQgUBzff5oPX0CB5Ty24oScK9rkBiq8tkB0lGmsON4TUzIP9h+pIKWZjd5RV1nH
# lvPd9ucB1f4hYpAsuui3+CtqjAWF7J8umePnl1cCgYEAhYb3/aZ1gDNOCf7dyJTY
# etNwp6QaYdAdLyE6CuQNrcWojeUrxmTdPxZqIp+MKZ02PZa4OHuzBhXJfszheW/H
# 8cr0JzQQnExln5MOcFBMFLCeRN+EpKLiKbJ/3HB2BpVEVYqU6hQuZu7CTxmibELw
# AU7Y72r3+W0Zd721juuW+ncCgYEAjdcn+aXDE2gz9WqnpzaCmad7cMlVgMedHw1m
# BOyz7v9ECEM3YdYii1mbOOzBskBP34iksN6VzFYcpjT3X/CGEcnVNdeUvRVEFRRq
# 6SAZTEWODxn++2MMjndYPwI3OiOSlrkwrwA7B2Rgs/XPfq6fJKYm2WYXu1i2ghJN
# b8bajt0CgYB573TzoC3zdK33gYPX8UMrdWk1O5moTmRXoX/nHLUGeJahL/cY5bKv
# B74Sqv8ib52+qTFeLtkw+lyzLYmOGSQ37I0fhhmZ9/nhyejaqmRgZhb7uODYNmog
# Y0xplrEtK77C3ezKX5/2DKshuzNck31xvrW8H28r/m9dVDoJE5imhw==
# -----END RSA PRIVATE KEY-----
# "
#   vrnode[:spin_public_key] = "-----BEGIN PUBLIC KEY-----
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvuhIb4v0iPEjNIuz4up/
# awweqoLCz1i3l5xJh7YDi/5uwso74lr+DVefqWAj8gVcf6m7Sk7qMGYEguzbDUXU
# maxUpLC/Hb6dBMar7vT/MTRvqDv0GDJGrIFwB+PP6gHQh5MeXmt+f8Aaq226gvVC
# QVf7DJmomFFgm0pVTYd4NQW8Vu8GebKrs31MuPZN+LiJi0/j5pjwwvbNIQ9u0sC9
# f+CDAett6zYbnVs2P3MtcjhRzhhD/3K+nj8YkPFJrPbuKODFb1eMcFy+wet8zXnN
# oKxf5qhJ4OgV5KK5+DGf5Mi6MLCY8Qv6mV+MwNG99SKE6bjysdVzu/BEUzuRT+sa
# UQIDAQAB
# -----END PUBLIC KEY-----
# "
#   vrnode[:rsa_key] = "-----BEGIN RSA PRIVATE KEY-----
# MIIEowIBAAKCAQEAyh357RDK4/Zj9J8S+AQW0Xp++sr2FCbnANZ8TIDJfoE7AmRv
# mKG4ZgSj9DF106xop1vmTNgGEg8+7guxxLsf0jPGKJKyGJg6+i065+eWVoS8YY7b
# qihqSUFdUygoAlUWlYjrG1UrCLlzryN5WuK8/aYwGN0tH0A+bI8/vzJPYtPOFVtx
# nktE2KguxTBb7dY2alTJQZh2K+9qgUZyVN88sOpHMnUEoypmut5wR9F1hYPfql2Z
# FwWYEi04v7mTx7Wel7SwfpjHiL2mn7t/XuLn4TL1WDFE7Pl8WMDyQ5DjQO19K0bU
# /eMbC6s8uWrbUGEwAsibHWCnmtkn9keYa1WykwIDAQABAoIBAQCtlXMZG+v0Pp73
# 70qeQPzL6dV2VKtlAUgx2wOjvJPQlvJ0CoghYPr6ew/IYFYedhrnaTDwXDNSfU+B
# p/+Dw2X/5MFSBTL5lnxIcmH921KteZBEhSm5CL7HrWCWU42Q+zzLLm0k609rTcLB
# 7siBuuuvOHRkVkgzZ7x1Bc4syeuOJmxmEwI127h5eFIuovyJtNLS6n1HxtY18LlH
# KIGplG9xSsWt5nZxXA3y83q/6yz5bHeHP+Kzz9KTIVGg+I0tm9zA7o6G78mbbOJb
# 9DPsblY8ORybLElyfvAUibAML7OyPcSgjRU05zk2QPJhaFZC/xwUfi8e5ggCFNbO
# FDihR5mhAoGBAPM8EPh9/xRudNf9UUUzX2yJxXzy8JfKD6zUFCz2XvjTyyU7CTxn
# Uc5ARcUqXNLmbDTSg2O8WHq7EKsgMbyKBO1XK9TXK/BD/0YfcR7tJ/d0sZn22HJJ
# EjR4dkLPoXRzlZKjHbMbleo5TJN1VMqNmqGNNIhxEEbMM45jP6976ERjAoGBANS5
# e6EydrkfJU8iobH+k9KIo9r8UVL0rd0NFrkMu0m8oLH1HB877iOxUb+ZRO3GR0dr
# RiAtxMcOGArb2DVOy82UaHViN5LQ4OY+e8M1EZE2TnCRxLkxj/zPJCd6YHVIn1of
# XEm48lRE1exfzgEG3cHFL47EnWBdkp//M9on1rgRAoGBAOJ5Uh/dSQ1gD2Ewl2RE
# ghwQZ5aAqW3bkR7N1P9MYn9yzFqdDmt0lCHjjFMZr5YbQDMqs3XA3+1ekhWUA1tW
# c2H94Wzq8BllZqGHEw/Fp4nr2JXP1hcLXG0IoKxyoRVJrcH8KOIk1EBjG57NB6cV
# lB3J2VkVVR9mcLaqSJj/WPObAn8uiGSC3ocZ97YxmWHFjerIIxu0y3z+qIdf030k
# /aP6fUippPSB4Jo3NJKtVtm9KaJt/QlaAKkK4gpgVbb18kaisdQn2VROyWJo+0IX
# cYRmP3rpJPnjiPP2WVmPSTXQchJppHKLrelUhbpF+q8Vimr3+CpvEJNcgRuR5EFz
# d0OBAoGBANXVpkJTiIOZR1gzrP1OpODc7WVuU7RxcbICz9zdhzZKeBR+KDeqxtmf
# 9SOIzfro4LeCScuP+i/P0nq0maU70U5moZ2LjUgUXwYkNqxYpNg8k+4FaGGUHIjG
# 3hp6TI0ntYPrz8tl4n4Hm56RePNN/gOho5JHyjOfcwXoV9DDogFu
# -----END RSA PRIVATE KEY-----
# "
#   vrnode[:max_versions] = 2
#   vrnode[:node_attributes] = "{\"type\":\"folder\"}"
#   vrnode[:latest] = true
#   vrnode[:lock_uid] = -1
#   vrnode[:is_open_flag] = false
#   vrnode[:spin_url] = ""
#   vrnode[:is_pending] = false
#   vrnode[:spin_vfs_id] = spin_root_node_vfs[:spin_vfs_id]
#   vrnode[:spin_storage_id] = spin_root_node_vstorage[:spin_storage_id]
#   vrnode[:user_level_x] = -1
#   vrnode[:user_level_y] = -1
#   vrnode[:trashed_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
#   vrnode[:is_void] = false
#   vrnode[:is_expanded] = false
#   vrnode[:is_domain_root_node] = true
#   vrnode[:spin_updated_at] = Time.now
#   vrnode[:lock_status] = 0
#   vrnode[:mtime] = Time.now
#   vrnode[:ctime] = Time.now
#   vrnode[:lock_mode] = 0
#   vrnode[:details] = ""
#   vrnode[:is_sticky] = false
#   vrnode[:spin_created_at] = Time.now
#   vrnode[:virtual_path] = spin_root_node_name
#   vrnode[:orphan] = false
#   vrnode[:modifier] = -1
#   vrnode[:creator] = -1
#   vrnode[:spin_tree_type] = 0
#   vrnode[:spin_node_tree] = 0
#   vrnode[:notified_new_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
#   vrnode[:notified_modification_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
#   vrnode[:notified_delete_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
#   vrnode[:memo1] = ""
#   vrnode[:memo2] = ""
#   vrnode[:memo3] = ""
#   vrnode[:memo4] = ""
#   vrnode[:memo5] = ""
#   vrnode[:is_synchronized] = false
#   vrnode[:is_archive] = false
#   vrnode[:is_paused] = false
#   vrnode[:lock_version] = 0
#   vrnode.save
# end
vrnode2 = SpinNode.find_or_create_by(node_x_coord: 0, node_y_coord: 1) {|vrn|
  vrn[:spin_node_hashkey] = spin_virtual_root_node_hash_key
  vrn[:node_x_coord] = 0
  vrn[:node_y_coord] = 1
  vrn[:node_name] = spin_virtual_root_node_name
  vrn[:node_type] = Vfs::NODE_DIRECTORY
  vrn[:node_version] = 0
  vrn[:node_x_pr_coord] = 0
  vrn[:in_trash_flag] = false
  vrn[:is_dirty_flag] = false
  vrn[:is_under_maintenance_flag] = false
  vrn[:in_use_uid] = -1
  vrn[:spin_uid] = 0
  vrn[:spin_gid] = 0
  vrn[:spin_uid_access_right] = 15
  vrn[:spin_gid_access_right] = 7
  vrn[:spin_world_access_right] = 0
  vrn[:created_by] = -1
  vrn[:updated_by] = -1
  vrn[:spin_private_key] = "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAvuhIb4v0iPEjNIuz4up/awweqoLCz1i3l5xJh7YDi/5uwso7
4lr+DVefqWAj8gVcf6m7Sk7qMGYEguzbDUXUmaxUpLC/Hb6dBMar7vT/MTRvqDv0
GDJGrIFwB+PP6gHQh5MeXmt+f8Aaq226gvVCQVf7DJmomFFgm0pVTYd4NQW8Vu8G
ebKrs31MuPZN+LiJi0/j5pjwwvbNIQ9u0sC9f+CDAett6zYbnVs2P3MtcjhRzhhD
/3K+nj8YkPFJrPbuKODFb1eMcFy+wet8zXnNoKxf5qhJ4OgV5KK5+DGf5Mi6MLCY
8Qv6mV+MwNG99SKE6bjysdVzu/BEUzuRT+saUQIDAQABAoIBAD88GaI5LYqetRaW
n8MuAX6nyRCZt4WO0WE6t3BobcxVPsLu0d8sXLJ2r8AexElKVVVEF3GJqjDV2fC0
G+rNkppEZtUWZnenx8LpO9Iu/MiDoeiL01KgdKB3T3CNmTTd3QDLTmfgG0qdizf1
ZK40JvoV9mY6D4pEikdl29OOZ9bHuCoTt2+kvNDmYVOOjfGU8hoAIVbqmBh2bvgl
/IHAAg1/SE6gIsQCciH2WYBa2qoNcfN6R/HT55kmrA37aCJxJT/rjOdW8AHv140y
rUdrIUS6of+mxTysMdhU+9+Hv9zxKm/kYTtbGjTOdQAQB0sh7ebsWoFWfGSTIAUM
AzJe/7ECgYEA+AlT5+2BZs1RgH01XTVRWFAEBxZe2afNjPOMxmyRoJQRpLeW9WOZ
1bHj9KntayF4lEqMDNP9FN3xxJchbksjkr7GcGXB2PSSOSr9+JM+AotwV2eTibko
bXRrd/deYwK6SF0gkAaQHOMuSQJ/93KgHQQLGojb3E7hKSSaAa1eGpcCgYEAxQll
tAq0Wnv/Vf+olQ9o2Ng1sx/+qm8Yv1JjI7VtGUVrFEd+lB+VOCQQ5nbDMB6+8DZf
UKQgUBzff5oPX0CB5Ty24oScK9rkBiq8tkB0lGmsON4TUzIP9h+pIKWZjd5RV1nH
lvPd9ucB1f4hYpAsuui3+CtqjAWF7J8umePnl1cCgYEAhYb3/aZ1gDNOCf7dyJTY
etNwp6QaYdAdLyE6CuQNrcWojeUrxmTdPxZqIp+MKZ02PZa4OHuzBhXJfszheW/H
8cr0JzQQnExln5MOcFBMFLCeRN+EpKLiKbJ/3HB2BpVEVYqU6hQuZu7CTxmibELw
AU7Y72r3+W0Zd721juuW+ncCgYEAjdcn+aXDE2gz9WqnpzaCmad7cMlVgMedHw1m
BOyz7v9ECEM3YdYii1mbOOzBskBP34iksN6VzFYcpjT3X/CGEcnVNdeUvRVEFRRq
6SAZTEWODxn++2MMjndYPwI3OiOSlrkwrwA7B2Rgs/XPfq6fJKYm2WYXu1i2ghJN
b8bajt0CgYB573TzoC3zdK33gYPX8UMrdWk1O5moTmRXoX/nHLUGeJahL/cY5bKv
B74Sqv8ib52+qTFeLtkw+lyzLYmOGSQ37I0fhhmZ9/nhyejaqmRgZhb7uODYNmog
Y0xplrEtK77C3ezKX5/2DKshuzNck31xvrW8H28r/m9dVDoJE5imhw==

-----END RSA PRIVATE KEY-----
"
  vrn[:spin_public_key] = "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvuhIb4v0iPEjNIuz4up/
awweqoLCz1i3l5xJh7YDi/5uwso74lr+DVefqWAj8gVcf6m7Sk7qMGYEguzbDUXU
maxUpLC/Hb6dBMar7vT/MTRvqDv0GDJGrIFwB+PP6gHQh5MeXmt+f8Aaq226gvVC
QVf7DJmomFFgm0pVTYd4NQW8Vu8GebKrs31MuPZN+LiJi0/j5pjwwvbNIQ9u0sC9
f+CDAett6zYbnVs2P3MtcjhRzhhD/3K+nj8YkPFJrPbuKODFb1eMcFy+wet8zXnN
oKxf5qhJ4OgV5KK5+DGf5Mi6MLCY8Qv6mV+MwNG99SKE6bjysdVzu/BEUzuRT+sa
UQIDAQAB
-----END PUBLIC KEY-----
"
  vrn[:rsa_key] = "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAyh357RDK4/Zj9J8S+AQW0Xp++sr2FCbnANZ8TIDJfoE7AmRv
mKG4ZgSj9DF106xop1vmTNgGEg8+7guxxLsf0jPGKJKyGJg6+i065+eWVoS8YY7b
qihqSUFdUygoAlUWlYjrG1UrCLlzryN5WuK8/aYwGN0tH0A+bI8/vzJPYtPOFVtx
nktE2KguxTBb7dY2alTJQZh2K+9qgUZyVN88sOpHMnUEoypmut5wR9F1hYPfql2Z
FwWYEi04v7mTx7Wel7SwfpjHiL2mn7t/XuLn4TL1WDFE7Pl8WMDyQ5DjQO19K0bU
/eMbC6s8uWrbUGEwAsibHWCnmtkn9keYa1WykwIDAQABAoIBAQCtlXMZG+v0Pp73
70qeQPzL6dV2VKtlAUgx2wOjvJPQlvJ0CoghYPr6ew/IYFYedhrnaTDwXDNSfU+B
p/+Dw2X/5MFSBTL5lnxIcmH921KteZBEhSm5CL7HrWCWU42Q+zzLLm0k609rTcLB
7siBuuuvOHRkVkgzZ7x1Bc4syeuOJmxmEwI127h5eFIuovyJtNLS6n1HxtY18LlH
KIGplG9xSsWt5nZxXA3y83q/6yz5bHeHP+Kzz9KTIVGg+I0tm9zA7o6G78mbbOJb
9DPsblY8ORybLElyfvAUibAML7OyPcSgjRU05zk2QPJhaFZC/xwUfi8e5ggCFNbO
FDihR5mhAoGBAPM8EPh9/xRudNf9UUUzX2yJxXzy8JfKD6zUFCz2XvjTyyU7CTxn
Uc5ARcUqXNLmbDTSg2O8WHq7EKsgMbyKBO1XK9TXK/BD/0YfcR7tJ/d0sZn22HJJ
EjR4dkLPoXRzlZKjHbMbleo5TJN1VMqNmqGNNIhxEEbMM45jP6976ERjAoGBANS5
e6EydrkfJU8iobH+k9KIo9r8UVL0rd0NFrkMu0m8oLH1HB877iOxUb+ZRO3GR0dr
RiAtxMcOGArb2DVOy82UaHViN5LQ4OY+e8M1EZE2TnCRxLkxj/zPJCd6YHVIn1of
XEm48lRE1exfzgEG3cHFL47EnWBdkp//M9on1rgRAoGBAOJ5Uh/dSQ1gD2Ewl2RE
ghwQZ5aAqW3bkR7N1P9MYn9yzFqdDmt0lCHjjFMZr5YbQDMqs3XA3+1ekhWUA1tW
c2H94Wzq8BllZqGHEw/Fp4nr2JXP1hcLXG0IoKxyoRVJrcH8KOIk1EBjG57NB6cV
lB3J2VkVVR9mcLaqSJj/WPObAn8uiGSC3ocZ97YxmWHFjerIIxu0y3z+qIdf030k
/aP6fUippPSB4Jo3NJKtVtm9KaJt/QlaAKkK4gpgVbb18kaisdQn2VROyWJo+0IX
cYRmP3rpJPnjiPP2WVmPSTXQchJppHKLrelUhbpF+q8Vimr3+CpvEJNcgRuR5EFz
d0OBAoGBANXVpkJTiIOZR1gzrP1OpODc7WVuU7RxcbICz9zdhzZKeBR+KDeqxtmf
9SOIzfro4LeCScuP+i/P0nq0maU70U5moZ2LjUgUXwYkNqxYpNg8k+4FaGGUHIjG
3hp6TI0ntYPrz8tl4n4Hm56RePNN/gOho5JHyjOfcwXoV9DDogFu
-----END RSA PRIVATE KEY-----
"
  vrn[:max_versions] = 2
  vrn[:node_attributes] = "{\"type\":\"folder\"}"
  vrn[:latest] = true
  vrn[:lock_uid] = -1
  vrn[:is_open_flag] = false
  vrn[:spin_url] = ""
  vrn[:is_pending] = false
  vrn[:spin_vfs_id] = spin_root_node_vfs[:spin_vfs_id]
  vrn[:spin_storage_id] = spin_root_node_vstorage[:spin_storage_id]
  vrn[:user_level_x] = -1
  vrn[:user_level_y] = -1
  vrn[:trashed_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
  vrn[:is_void] = false
  vrn[:is_expanded] = false
  vrn[:is_domain_root_node] = true
  vrn[:spin_updated_at] = Time.now
  vrn[:lock_status] = 0
  vrn[:mtime] = Time.now
  vrn[:ctime] = Time.now
  vrn[:lock_mode] = 0
  vrn[:details] = ""
  vrn[:is_sticky] = false
  vrn[:spin_created_at] = Time.now
  vrn[:virtual_path] = spin_virtual_root_node_name
  vrn[:orphan] = false
  vrn[:modifier] = -1
  vrn[:creator] = -1
  vrn[:spin_tree_type] = 0
  vrn[:spin_node_tree] = 0
  vrn[:notified_new_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
  vrn[:notified_modification_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
  vrn[:notified_delete_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
  vrn[:memo1] = ""
  vrn[:memo2] = ""
  vrn[:memo3] = ""
  vrn[:memo4] = ""
  vrn[:memo5] = ""
  vrn[:is_synchronized] = false
  vrn[:is_archive] = false
  vrn[:is_paused] = false
  vrn[:lock_version] = 0
}
# if vrnode2.present?
#   vrnode2[:spin_node_hashkey] = spin_virtual_root_node_hash_key
#   vrnode2[:node_x_coord] = 0
#   vrnode2[:node_y_coord] = 1
#   vrnode2[:node_name] = spin_virtual_root_node_name
#   vrnode2[:node_type] = Vfs::NODE_DIRECTORY
#   vrnode2[:node_version] = 0
#   vrnode2[:node_x_pr_coord] = 0
#   vrnode2[:in_trash_flag] = false
#   vrnode2[:is_dirty_flag] = false
#   vrnode2[:is_under_maintenance_flag] = false
#   vrnode2[:in_use_uid] = -1
#   vrnode2[:spin_uid] = 0
#   vrnode2[:spin_gid] = 0
#   vrnode2[:spin_uid_access_right] = 15
#   vrnode2[:spin_gid_access_right] = 7
#   vrnode2[:spin_world_access_right] = 0
#   vrnode2[:created_by] = -1
#   vrnode2[:updated_by] = -1
#   vrnode2[:spin_private_key] = "-----BEGIN RSA PRIVATE KEY-----
# MIIEpAIBAAKCAQEAvuhIb4v0iPEjNIuz4up/awweqoLCz1i3l5xJh7YDi/5uwso7
# 4lr+DVefqWAj8gVcf6m7Sk7qMGYEguzbDUXUmaxUpLC/Hb6dBMar7vT/MTRvqDv0
# GDJGrIFwB+PP6gHQh5MeXmt+f8Aaq226gvVCQVf7DJmomFFgm0pVTYd4NQW8Vu8G
# ebKrs31MuPZN+LiJi0/j5pjwwvbNIQ9u0sC9f+CDAett6zYbnVs2P3MtcjhRzhhD
# /3K+nj8YkPFJrPbuKODFb1eMcFy+wet8zXnNoKxf5qhJ4OgV5KK5+DGf5Mi6MLCY
# 8Qv6mV+MwNG99SKE6bjysdVzu/BEUzuRT+saUQIDAQABAoIBAD88GaI5LYqetRaW
# n8MuAX6nyRCZt4WO0WE6t3BobcxVPsLu0d8sXLJ2r8AexElKVVVEF3GJqjDV2fC0
# G+rNkppEZtUWZnenx8LpO9Iu/MiDoeiL01KgdKB3T3CNmTTd3QDLTmfgG0qdizf1
# ZK40JvoV9mY6D4pEikdl29OOZ9bHuCoTt2+kvNDmYVOOjfGU8hoAIVbqmBh2bvgl
# /IHAAg1/SE6gIsQCciH2WYBa2qoNcfN6R/HT55kmrA37aCJxJT/rjOdW8AHv140y
# rUdrIUS6of+mxTysMdhU+9+Hv9zxKm/kYTtbGjTOdQAQB0sh7ebsWoFWfGSTIAUM
# AzJe/7ECgYEA+AlT5+2BZs1RgH01XTVRWFAEBxZe2afNjPOMxmyRoJQRpLeW9WOZ
# 1bHj9KntayF4lEqMDNP9FN3xxJchbksjkr7GcGXB2PSSOSr9+JM+AotwV2eTibko
# bXRrd/deYwK6SF0gkAaQHOMuSQJ/93KgHQQLGojb3E7hKSSaAa1eGpcCgYEAxQll
# tAq0Wnv/Vf+olQ9o2Ng1sx/+qm8Yv1JjI7VtGUVrFEd+lB+VOCQQ5nbDMB6+8DZf
# UKQgUBzff5oPX0CB5Ty24oScK9rkBiq8tkB0lGmsON4TUzIP9h+pIKWZjd5RV1nH
# lvPd9ucB1f4hYpAsuui3+CtqjAWF7J8umePnl1cCgYEAhYb3/aZ1gDNOCf7dyJTY
# etNwp6QaYdAdLyE6CuQNrcWojeUrxmTdPxZqIp+MKZ02PZa4OHuzBhXJfszheW/H
# 8cr0JzQQnExln5MOcFBMFLCeRN+EpKLiKbJ/3HB2BpVEVYqU6hQuZu7CTxmibELw
# AU7Y72r3+W0Zd721juuW+ncCgYEAjdcn+aXDE2gz9WqnpzaCmad7cMlVgMedHw1m
# BOyz7v9ECEM3YdYii1mbOOzBskBP34iksN6VzFYcpjT3X/CGEcnVNdeUvRVEFRRq
# 6SAZTEWODxn++2MMjndYPwI3OiOSlrkwrwA7B2Rgs/XPfq6fJKYm2WYXu1i2ghJN
# b8bajt0CgYB573TzoC3zdK33gYPX8UMrdWk1O5moTmRXoX/nHLUGeJahL/cY5bKv
# B74Sqv8ib52+qTFeLtkw+lyzLYmOGSQ37I0fhhmZ9/nhyejaqmRgZhb7uODYNmog
# Y0xplrEtK77C3ezKX5/2DKshuzNck31xvrW8H28r/m9dVDoJE5imhw==
# -----END RSA PRIVATE KEY-----
# "
#   vrnode2[:spin_public_key] = "-----BEGIN PUBLIC KEY-----
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvuhIb4v0iPEjNIuz4up/
# awweqoLCz1i3l5xJh7YDi/5uwso74lr+DVefqWAj8gVcf6m7Sk7qMGYEguzbDUXU
# maxUpLC/Hb6dBMar7vT/MTRvqDv0GDJGrIFwB+PP6gHQh5MeXmt+f8Aaq226gvVC
# QVf7DJmomFFgm0pVTYd4NQW8Vu8GebKrs31MuPZN+LiJi0/j5pjwwvbNIQ9u0sC9
# f+CDAett6zYbnVs2P3MtcjhRzhhD/3K+nj8YkPFJrPbuKODFb1eMcFy+wet8zXnN
# oKxf5qhJ4OgV5KK5+DGf5Mi6MLCY8Qv6mV+MwNG99SKE6bjysdVzu/BEUzuRT+sa
# UQIDAQAB
# -----END PUBLIC KEY-----
# "
#   vrnode2[:rsa_key] = "-----BEGIN RSA PRIVATE KEY-----
# MIIEowIBAAKCAQEAyh357RDK4/Zj9J8S+AQW0Xp++sr2FCbnANZ8TIDJfoE7AmRv
# mKG4ZgSj9DF106xop1vmTNgGEg8+7guxxLsf0jPGKJKyGJg6+i065+eWVoS8YY7b
# qihqSUFdUygoAlUWlYjrG1UrCLlzryN5WuK8/aYwGN0tH0A+bI8/vzJPYtPOFVtx
# nktE2KguxTBb7dY2alTJQZh2K+9qgUZyVN88sOpHMnUEoypmut5wR9F1hYPfql2Z
# FwWYEi04v7mTx7Wel7SwfpjHiL2mn7t/XuLn4TL1WDFE7Pl8WMDyQ5DjQO19K0bU
# /eMbC6s8uWrbUGEwAsibHWCnmtkn9keYa1WykwIDAQABAoIBAQCtlXMZG+v0Pp73
# 70qeQPzL6dV2VKtlAUgx2wOjvJPQlvJ0CoghYPr6ew/IYFYedhrnaTDwXDNSfU+B
# p/+Dw2X/5MFSBTL5lnxIcmH921KteZBEhSm5CL7HrWCWU42Q+zzLLm0k609rTcLB
# 7siBuuuvOHRkVkgzZ7x1Bc4syeuOJmxmEwI127h5eFIuovyJtNLS6n1HxtY18LlH
# KIGplG9xSsWt5nZxXA3y83q/6yz5bHeHP+Kzz9KTIVGg+I0tm9zA7o6G78mbbOJb
# 9DPsblY8ORybLElyfvAUibAML7OyPcSgjRU05zk2QPJhaFZC/xwUfi8e5ggCFNbO
# FDihR5mhAoGBAPM8EPh9/xRudNf9UUUzX2yJxXzy8JfKD6zUFCz2XvjTyyU7CTxn
# Uc5ARcUqXNLmbDTSg2O8WHq7EKsgMbyKBO1XK9TXK/BD/0YfcR7tJ/d0sZn22HJJ
# EjR4dkLPoXRzlZKjHbMbleo5TJN1VMqNmqGNNIhxEEbMM45jP6976ERjAoGBANS5
# e6EydrkfJU8iobH+k9KIo9r8UVL0rd0NFrkMu0m8oLH1HB877iOxUb+ZRO3GR0dr
# RiAtxMcOGArb2DVOy82UaHViN5LQ4OY+e8M1EZE2TnCRxLkxj/zPJCd6YHVIn1of
# XEm48lRE1exfzgEG3cHFL47EnWBdkp//M9on1rgRAoGBAOJ5Uh/dSQ1gD2Ewl2RE
# ghwQZ5aAqW3bkR7N1P9MYn9yzFqdDmt0lCHjjFMZr5YbQDMqs3XA3+1ekhWUA1tW
# c2H94Wzq8BllZqGHEw/Fp4nr2JXP1hcLXG0IoKxyoRVJrcH8KOIk1EBjG57NB6cV
# lB3J2VkVVR9mcLaqSJj/WPObAn8uiGSC3ocZ97YxmWHFjerIIxu0y3z+qIdf030k
# /aP6fUippPSB4Jo3NJKtVtm9KaJt/QlaAKkK4gpgVbb18kaisdQn2VROyWJo+0IX
# cYRmP3rpJPnjiPP2WVmPSTXQchJppHKLrelUhbpF+q8Vimr3+CpvEJNcgRuR5EFz
# d0OBAoGBANXVpkJTiIOZR1gzrP1OpODc7WVuU7RxcbICz9zdhzZKeBR+KDeqxtmf
# 9SOIzfro4LeCScuP+i/P0nq0maU70U5moZ2LjUgUXwYkNqxYpNg8k+4FaGGUHIjG
# 3hp6TI0ntYPrz8tl4n4Hm56RePNN/gOho5JHyjOfcwXoV9DDogFu
# -----END RSA PRIVATE KEY-----
# "
#   vrnode2[:max_versions] = 2
#   vrnode2[:node_attributes] = "{\"type\":\"folder\"}"
#   vrnode2[:latest] = true
#   vrnode2[:lock_uid] = -1
#   vrnode2[:is_open_flag] = false
#   vrnode2[:spin_url] = ""
#   vrnode2[:is_pending] = false
#   vrnode2[:spin_vfs_id] = spin_root_node_vfs[:spin_vfs_id]
#   vrnode2[:spin_storage_id] = spin_root_node_vstorage[:spin_storage_id]
#   vrnode2[:user_level_x] = -1
#   vrnode2[:user_level_y] = -1
#   vrnode2[:trashed_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
#   vrnode2[:is_void] = false
#   vrnode2[:is_expanded] = false
#   vrnode2[:is_domain_root_node] = true
#   vrnode2[:spin_updated_at] = Time.now
#   vrnode2[:lock_status] = 0
#   vrnode2[:mtime] = Time.now
#   vrnode2[:ctime] = Time.now
#   vrnode2[:lock_mode] = 0
#   vrnode2[:details] = ""
#   vrnode2[:is_sticky] = false
#   vrnode2[:spin_created_at] = Time.now
#   vrnode2[:virtual_path] = spin_virtual_root_node_name
#   vrnode2[:orphan] = false
#   vrnode2[:modifier] = -1
#   vrnode2[:creator] = -1
#   vrnode2[:spin_tree_type] = 0
#   vrnode2[:spin_node_tree] = 0
#   vrnode2[:notified_new_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
#   vrnode2[:notified_modification_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
#   vrnode2[:notified_delete_at] = Time.mktime(2001, 1, 1, 00, 00, 00)
#   vrnode2[:memo1] = ""
#   vrnode2[:memo2] = ""
#   vrnode2[:memo3] = ""
#   vrnode2[:memo4] = ""
#   vrnode2[:memo5] = ""
#   vrnode2[:is_synchronized] = false
#   vrnode2[:is_archive] = false
#   vrnode2[:is_paused] = false
#   vrnode2[:lock_version] = 0
#   vrnode2.save
# end

# setup virtual domains
#
virtual_domain_config.each {|dom|
  vsd = SpinDomain.find_or_create_by(spin_domain_name: dom['domain_name'], spin_did: dom['domain_id']) {|vdom|
    vdom[:spin_did] = dom['domain_id']
    vdom[:spin_domain_name] = dom['domain_name']
    vdom[:spin_domain_root] = spin_root_node_name
    vdom[:domain_root_node_hashkey] = spin_root_node_hash_key
    vdom[:spin_server] = "127.0.0.1"
    vdom[:hash_key] = dom['domain_hash_key']
    vdom[:spin_domain_disp_name] = dom['domain_disp_name']
    vdom[:domain_descr] = dom['domain_descr']
    vdom[:domain_writable_status] = dom['domain_writable_status']
    vdom[:domain_link] = dom['domain_link']
    vdom[:img] = dom['domain_img']
    vdom[:spin_uid] = dom['domain_uid']
    vdom[:spin_gid] = dom['domain_gid']
    vdom[:spin_uid_access_right] = dom['uid_access_right']
    vdom[:spin_gid_access_right] = dom['gid_access_right']
    vdom[:spin_world_access_right] = dom['world_access_right']
    vdom[:lock_version] = 0
    vdom[:domain_attributes] = "{}"
    vdom[:spin_updated_at] = Time.now
  }
  # if vsd.present?
  #   vsd[:spin_did] = dom['domain_id']
  #   vsd[:spin_domain_name] = dom['domain_name']
  #   vsd[:spin_domain_root] = spin_root_node_name
  #   vsd[:domain_root_node_hashkey] = spin_root_node_hash_key
  #   vsd[:spin_server] = "127.0.0.1"
  #   vsd[:hash_key] = dom['domain_hash_key']
  #   vsd[:spin_domain_disp_name] = dom['domain_disp_name']
  #   vsd[:domain_descr] = dom['domain_descr']
  #   vsd[:domain_writable_status] = dom['domain_writable_status']
  #   vsd[:domain_link] = dom['domain_link']
  #   vsd[:img] = dom['domain_img']
  #   vsd[:spin_uid] = dom['domain_uid']
  #   vsd[:spin_gid] = dom['domain_gid']
  #   vsd[:spin_uid_access_right] = dom['uid_access_right']
  #   vsd[:spin_gid_access_right] = dom['gid_access_right']
  #   vsd[:spin_world_access_right] = dom['world_access_right']
  #   vsd[:lock_version] = 0
  #   vsd[:domain_attributes] = "{}"
  #   vsd[:spin_updated_at] = Time.now
  #   vsd.save
  # end
}

