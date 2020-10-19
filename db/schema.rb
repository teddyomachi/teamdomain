# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_12_21_103045) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clip_boards", id: :serial, force: :cascade do |t|
    t.integer "nodex"
    t.integer "nodey"
    t.integer "nodev"
    t.integer "nodeprx"
    t.integer "nodet"
    t.string "node_hash_key", limit: 255
    t.integer "opr"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "session_id", limit: 255
    t.boolean "opr_complete", default: false
    t.string "opr_id", limit: 255
    t.integer "get_marker", default: 0
    t.boolean "parent_flg", default: false
    t.integer "lock_version", default: 0
    t.index ["get_marker"], name: "index_clip_boards_on_get_marker"
    t.index ["node_hash_key"], name: "index_clip_boards_on_node_hash_key"
    t.index ["nodeprx"], name: "index_clip_boards_on_nodeprx"
    t.index ["nodet"], name: "index_clip_boards_on_nodet"
    t.index ["nodev"], name: "index_clip_boards_on_nodev"
    t.index ["nodex"], name: "index_clip_boards_on_nodex"
    t.index ["nodey"], name: "index_clip_boards_on_nodey"
    t.index ["opr"], name: "index_clip_boards_on_opr"
    t.index ["opr_complete"], name: "index_clip_boards_on_opr_complete"
    t.index ["opr_id"], name: "index_clip_boards_on_opr_id"
    t.index ["session_id"], name: "index_clip_boards_on_session_id"
  end

  create_table "coord_mappings", id: :serial, force: :cascade do |t|
    t.string "key", limit: 255
    t.integer "x"
    t.integer "y"
    t.integer "prx"
    t.integer "nx"
    t.integer "ny"
    t.integer "nprx"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
    t.index ["key"], name: "index_coord_mappings_on_key", unique: true
    t.index ["nprx"], name: "index_coord_mappings_on_nprx"
    t.index ["nx"], name: "index_coord_mappings_on_nx"
    t.index ["ny"], name: "index_coord_mappings_on_ny"
    t.index ["parent_id"], name: "index_coord_mappings_on_parent_id"
    t.index ["prx"], name: "index_coord_mappings_on_prx"
    t.index ["x"], name: "index_coord_mappings_on_x"
    t.index ["y"], name: "index_coord_mappings_on_y"
  end

  create_table "domain_data", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255
    t.string "hash_key", limit: 255
    t.string "cont_location", limit: 255
    t.string "domain_name", limit: 4096
    t.string "domain_link", limit: 255
    t.string "img", limit: 4096
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "folder_hash_key", limit: 255
    t.integer "spin_did", default: -1, null: false
    t.string "current_folder", limit: 255
    t.boolean "selected", default: false
    t.string "selected_folder", limit: 255
    t.boolean "is_dirty", default: false
    t.boolean "is_new", default: true
    t.boolean "target_is_new", default: true
    t.boolean "target_is_dirty", default: false
    t.datetime "spin_updated_at", default: "2000-12-31 15:00:00"
    t.boolean "domain_writable_status", default: true
    t.string "spin_domain_hash_key", limit: 255
    t.string "selected_folder_a", limit: 255, default: ""
    t.string "selected_folder_b", limit: 255, default: ""
    t.string "selected_folder_at", limit: 255, default: ""
    t.string "selected_folder_bt", limit: 255, default: ""
    t.string "selected_folder_atfi", limit: 255, default: ""
    t.string "selected_folder_btfi", limit: 255, default: ""
    t.string "vpath", limit: 255
    t.integer "lock_version", default: 0
    t.index ["cont_location"], name: "index_domain_data_on_cont_location"
    t.index ["domain_name"], name: "index_domain_data_on_domain_name"
    t.index ["domain_writable_status"], name: "index_domain_data_on_domain_writable_status"
    t.index ["folder_hash_key"], name: "index_domain_data_on_folder_hash_key"
    t.index ["hash_key"], name: "index_domain_data_on_hash_key"
    t.index ["is_dirty"], name: "index_domain_data_on_is_dirty"
    t.index ["is_new"], name: "index_domain_data_on_is_new"
    t.index ["selected"], name: "index_domain_data_on_selected"
    t.index ["selected_folder_a"], name: "index_domain_data_on_selected_folder_a"
    t.index ["selected_folder_at"], name: "index_domain_data_on_selected_folder_at"
    t.index ["selected_folder_atfi"], name: "index_domain_data_on_selected_folder_atfi"
    t.index ["selected_folder_b"], name: "index_domain_data_on_selected_folder_b"
    t.index ["selected_folder_bt"], name: "index_domain_data_on_selected_folder_bt"
    t.index ["selected_folder_btfi"], name: "index_domain_data_on_selected_folder_btfi"
    t.index ["session_id"], name: "index_domain_data_on_session_id"
    t.index ["spin_did"], name: "index_domain_data_on_spin_did"
    t.index ["spin_domain_hash_key"], name: "index_domain_data_on_spin_domain_hash_key"
    t.index ["target_is_dirty"], name: "index_domain_data_on_target_is_dirty"
    t.index ["target_is_new"], name: "index_domain_data_on_target_is_new"
    t.index ["vpath"], name: "index_domain_data_on_vpath"
  end

  create_table "file_data", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255
    t.string "hash_key", limit: 255
    t.string "cont_location", limit: 255
    t.string "file_name", limit: 4096
    t.string "file_type", limit: 255
    t.integer "file_size"
    t.integer "file_version"
    t.string "thumbnail_image", limit: 4096
    t.datetime "created_date", null: false
    t.string "creator", limit: 4096
    t.datetime "modified_date", null: false
    t.string "modifier", limit: 4096
    t.string "owner", limit: 4096
    t.string "ownership", limit: 4096
    t.string "id_lc_by", limit: 255
    t.string "keyword", limit: 4096
    t.integer "file_exact_size"
    t.string "icon_image", limit: 4096
    t.string "title", limit: 4096
    t.string "frame_size", limit: 255
    t.string "duration", limit: 255
    t.string "producer", limit: 255
    t.string "produced_date", limit: 255, default: ""
    t.string "location", limit: 4096
    t.string "client", limit: 4096
    t.string "copyright", limit: 4096
    t.string "portrait_right", limit: 4096
    t.string "access_group", limit: 255
    t.string "folder_hash_key", limit: 255
    t.text "details", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "id_lc_name", limit: 255
    t.string "cast", limit: 4096
    t.string "music", limit: 4096
    t.integer "file_size_upper", default: 0
    t.boolean "control_right"
    t.boolean "file_readable_status"
    t.boolean "file_writable_status"
    t.boolean "folder_readable_status"
    t.boolean "folder_writable_status"
    t.integer "lock", default: 0
    t.datetime "spin_updated_at", default: "2000-12-31 15:00:00"
    t.boolean "open_status", default: false
    t.boolean "dirty", default: false
    t.string "spin_node_hashkey", limit: 255
    t.string "subtitle", limit: 4096
    t.string "url", limit: 4096
    t.boolean "latest", default: true
    t.string "target_hash", limit: 255
    t.boolean "moved", default: false
    t.text "description"
    t.datetime "spin_created_at"
    t.boolean "other_readable", default: false
    t.boolean "selected", default: false
    t.boolean "other_writable", default: false
    t.string "target_hash_key", limit: 255
    t.string "t_file_type", limit: 255, default: "mp4"
    t.string "domain_hash_key", limit: 255
    t.string "virtual_path", limit: 4096
    t.string "preview_image", limit: 4096
    t.integer "lock_version", default: 0, null: false
    t.index ["cont_location"], name: "index_file_data_on_cont_location"
    t.index ["control_right"], name: "index_file_data_on_control_right"
    t.index ["description"], name: "index_file_data_on_description"
    t.index ["file_name"], name: "index_file_data_on_file_name"
    t.index ["file_readable_status"], name: "index_file_data_on_file_readable_status"
    t.index ["file_type"], name: "index_file_data_on_file_type"
    t.index ["file_version"], name: "index_file_data_on_file_version"
    t.index ["file_writable_status"], name: "index_file_data_on_file_writable_status"
    t.index ["folder_hash_key"], name: "index_file_data_on_folder_hash_key"
    t.index ["folder_readable_status"], name: "index_file_data_on_folder_readable_status"
    t.index ["folder_writable_status"], name: "index_file_data_on_folder_writable_status"
    t.index ["hash_key"], name: "index_file_data_on_hash_key"
    t.index ["id_lc_by"], name: "index_file_data_on_id_lc_by"
    t.index ["keyword"], name: "index_file_data_on_keyword"
    t.index ["latest"], name: "index_file_data_on_latest"
    t.index ["lock"], name: "index_file_data_on_lock"
    t.index ["moved"], name: "index_file_data_on_moved"
    t.index ["open_status"], name: "index_file_data_on_open_status"
    t.index ["other_readable"], name: "index_file_data_on_other_readable"
    t.index ["other_writable"], name: "index_file_data_on_other_writable"
    t.index ["preview_image"], name: "index_file_data_on_preview_image"
    t.index ["selected"], name: "index_file_data_on_selected"
    t.index ["session_id", "hash_key", "cont_location", "folder_hash_key"], name: "index_sid_hk_loc_fhk", unique: true
    t.index ["session_id"], name: "index_file_data_on_session_id"
    t.index ["spin_created_at"], name: "index_file_data_on_spin_created_at"
    t.index ["spin_node_hashkey"], name: "index_file_data_on_spin_node_hashkey"
    t.index ["spin_updated_at"], name: "index_file_data_on_spin_updated_at"
    t.index ["target_hash"], name: "index_file_data_on_target_hash"
    t.index ["thumbnail_image"], name: "index_file_data_on_thumbnail_image"
    t.index ["virtual_path"], name: "index_file_data_on_virtual_path"
  end

  create_table "folder_data", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255
    t.string "hash_key", limit: 255
    t.string "cont_location", limit: 255
    t.string "img", limit: 255
    t.string "text", limit: 4096
    t.string "folder_name", limit: 4096
    t.string "owner", limit: 255
    t.string "ownership", limit: 255
    t.string "workingFolder", limit: 255
    t.integer "subFolders"
    t.integer "fileNumber"
    t.string "creator", limit: 4096
    t.date "created_date"
    t.string "updater", limit: 4096
    t.date "updated_date"
    t.integer "usedSpace"
    t.integer "restSpace"
    t.integer "capacity"
    t.integer "usedRate"
    t.string "cls", limit: 255
    t.boolean "expanded"
    t.boolean "leaf"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "folder_readable_status", default: false
    t.boolean "folder_writable_status", default: false
    t.boolean "parent_readable_status", default: false
    t.boolean "parent_writable_status", default: false
    t.boolean "control_right", default: false
    t.string "parent_hash_key", limit: 255
    t.string "spin_node_hashkey", limit: 255
    t.boolean "selected", default: false
    t.string "domain_hash_key", limit: 255
    t.boolean "is_dirty", default: false
    t.boolean "is_new", default: true
    t.datetime "spin_updated_at", default: "2000-12-31 15:00:00"
    t.boolean "other_readable"
    t.boolean "other_writable"
    t.integer "expand_counter", default: 0
    t.boolean "is_dirty_list", default: false
    t.boolean "is_new_list", default: true
    t.boolean "is_partial_view", default: false
    t.text "children", default: ""
    t.boolean "is_partial_root", default: false
    t.string "target_cont_location", limit: 255
    t.boolean "target_folder_readable_status"
    t.boolean "target_folder_writable_status"
    t.string "target_ownership", limit: 255
    t.boolean "target_parent_readable_status"
    t.boolean "target_parent_writable_status"
    t.string "target_folder", limit: 4096
    t.string "target_hash_key", limit: 255, default: ""
    t.integer "px", default: -1
    t.integer "py", default: -1
    t.integer "ppx", default: -1
    t.boolean "moved", default: false
    t.integer "new_children", default: 0
    t.integer "notify_new_child", default: 0
    t.datetime "spin_created_at"
    t.string "vpath", limit: 4096
    t.string "virtual_path", limit: 4096
    t.integer "lock_version", default: 0, null: false
    t.boolean "is_domain_root", default: false
    t.index ["cont_location"], name: "index_folder_data_on_cont_location"
    t.index ["control_right"], name: "index_folder_data_on_control_right"
    t.index ["domain_hash_key"], name: "index_folder_data_on_domain_hash_key"
    t.index ["expand_counter"], name: "index_folder_data_on_expand_counter"
    t.index ["expanded"], name: "index_folder_data_on_expanded"
    t.index ["folder_name"], name: "index_folder_data_on_folder_name"
    t.index ["folder_readable_status"], name: "index_folder_data_on_folder_readable_status"
    t.index ["folder_writable_status"], name: "index_folder_data_on_folder_writable_status"
    t.index ["hash_key"], name: "index_folder_data_on_hash_key"
    t.index ["is_dirty"], name: "index_folder_data_on_is_dirty"
    t.index ["is_dirty_list"], name: "index_folder_data_on_is_dirty_list"
    t.index ["is_new"], name: "index_folder_data_on_is_new"
    t.index ["is_new_list"], name: "index_folder_data_on_is_new_list"
    t.index ["is_partial_root"], name: "index_folder_data_on_is_partial_root"
    t.index ["is_partial_view"], name: "index_folder_data_on_is_partial_view"
    t.index ["moved"], name: "index_folder_data_on_moved"
    t.index ["new_children"], name: "index_folder_data_on_new_children"
    t.index ["notify_new_child"], name: "index_folder_data_on_notify_new_child"
    t.index ["owner"], name: "index_folder_data_on_owner"
    t.index ["ownership"], name: "index_folder_data_on_ownership"
    t.index ["parent_hash_key"], name: "index_folder_data_on_parent_hash_key"
    t.index ["parent_readable_status"], name: "index_folder_data_on_parent_readable_status"
    t.index ["parent_writable_status"], name: "index_folder_data_on_parent_writable_status"
    t.index ["ppx"], name: "index_folder_data_on_ppx"
    t.index ["px"], name: "index_folder_data_on_px"
    t.index ["py"], name: "index_folder_data_on_py"
    t.index ["selected"], name: "index_folder_data_on_selected"
    t.index ["session_id"], name: "index_folder_data_on_session_id"
    t.index ["spin_created_at"], name: "index_folder_data_on_spin_created_at"
    t.index ["spin_node_hashkey"], name: "index_folder_data_on_spin_node_hashkey"
    t.index ["spin_updated_at"], name: "index_folder_data_on_spin_updated_at"
    t.index ["target_cont_location"], name: "index_folder_data_on_target_cont_location"
    t.index ["target_folder"], name: "index_folder_data_on_target_folder"
    t.index ["target_folder_readable_status"], name: "index_folder_data_on_target_folder_readable_status"
    t.index ["target_folder_writable_status"], name: "index_folder_data_on_target_folder_writable_status"
    t.index ["target_hash_key"], name: "index_folder_data_on_target_hash_key"
    t.index ["target_parent_readable_status"], name: "index_folder_data_on_target_parent_readable_status"
    t.index ["target_parent_writable_status"], name: "index_folder_data_on_target_parent_writable_status"
    t.index ["text"], name: "index_folder_data_on_text"
    t.index ["virtual_path"], name: "index_folder_data_on_virtual_path"
    t.index ["vpath"], name: "index_folder_data_on_vpath"
  end

  create_table "group_data", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255
    t.string "hash_key", limit: 255
    t.string "target_hash_key", limit: 255
    t.string "editable_status", limit: 255
    t.string "group_name", limit: 4096
    t.string "group_description", limit: 255
    t.string "group_privilege", default: ""
    t.string "member_name", limit: 255
    t.string "member_description", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "list_type", default: 0
    t.integer "data_class", default: -1
    t.string "group_notification", default: ""
    t.integer "lock_version", default: 0
    t.integer "member_id", default: -1
    t.boolean "is_void", default: false
    t.index ["data_class"], name: "index_group_data_on_data_class"
    t.index ["group_name"], name: "index_group_data_on_group_name"
    t.index ["hash_key"], name: "index_group_data_on_hash_key", unique: true
    t.index ["list_type"], name: "index_group_data_on_list_type"
    t.index ["member_name"], name: "index_group_data_on_member_name"
    t.index ["session_id"], name: "index_group_data_on_session_id"
    t.index ["target_hash_key"], name: "index_group_data_on_target_hash_key"
  end

  create_table "member_data", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255
    t.string "hash_key", limit: 255
    t.string "member_id", limit: 255
    t.string "member_name", limit: 4096
    t.string "member_description", limit: 255
    t.string "member_remark", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lock_version", default: 0
  end

  create_table "operator_data", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255
    t.string "active_operator_name", limit: 4096
    t.string "operator_group_editable", limit: 255
    t.string "last_session_id", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "active_operator_id", default: -1
    t.string "active_operator_spin_uname"
    t.boolean "operator_control_editable", default: false
    t.index ["active_operator_name"], name: "index_operator_data_on_active_operator_name"
    t.index ["operator_group_editable"], name: "index_operator_data_on_operator_group_editable"
    t.index ["session_id"], name: "index_operator_data_on_session_id"
  end

  create_table "recycler_data", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255
    t.string "hash_key", limit: 255
    t.string "cont_location", limit: 255
    t.string "file_name", limit: 255
    t.string "file_type", limit: 255
    t.string "url", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "spin_uid"
    t.integer "file_size", default: 0
    t.integer "file_size_upper", default: 0
    t.string "file_exact_size", limit: 255
    t.string "spin_node_hashkey", limit: 255
    t.boolean "latest"
    t.integer "node_x_coord", default: -1
    t.integer "node_y_coord", default: -1
    t.integer "node_version", default: -1
    t.integer "node_x_pr_coord", default: -1
    t.boolean "is_thrown", default: false
    t.integer "node_type", default: -1
    t.string "virtual_path", limit: 4096
    t.boolean "is_busy", default: false
    t.integer "lock_version", default: 0, null: false
    t.index ["hash_key"], name: "index_recycler_data_on_hash_key"
    t.index ["is_busy"], name: "index_recycler_data_on_is_busy"
    t.index ["is_thrown"], name: "index_recycler_data_on_is_thrown"
    t.index ["latest"], name: "index_recycler_data_on_latest"
    t.index ["node_type"], name: "index_recycler_data_on_node_type"
    t.index ["node_version"], name: "index_recycler_data_on_node_version"
    t.index ["node_x_coord"], name: "index_recycler_data_on_node_x_coord"
    t.index ["node_y_coord"], name: "index_recycler_data_on_node_y_coord"
    t.index ["spin_node_hashkey"], name: "index_recycler_data_on_spin_node_hashkey"
    t.index ["spin_uid", "hash_key"], name: "index_recycler_data_on_spin_uid_and_hash_key", unique: true
    t.index ["spin_uid"], name: "index_recycler_data_on_spin_uid"
    t.index ["virtual_path"], name: "index_recycler_data_on_virtual_path"
  end

  create_table "search_condition_data", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255
    t.string "target_folder", limit: 255
    t.string "target_file_name", limit: 4096
    t.integer "target_file_size_min"
    t.integer "target_file_size_max"
    t.string "target_creator", limit: 255
    t.boolean "target_created_by_me"
    t.date "target_created_date_begin"
    t.date "target_created_date_end"
    t.string "target_modifier", limit: 255
    t.boolean "target_modified_by_me"
    t.date "target_modified_date_begin"
    t.date "target_modified_date_end"
    t.boolean "target_subfolder"
    t.boolean "target_locked_by_me"
    t.boolean "target_checked_out_by_me"
    t.integer "target_max_display_files"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "property"
  end

  create_table "search_option_data", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255
    t.string "option_name", limit: 255
    t.string "field_name", limit: 255
    t.string "value", limit: 4096
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sender_data", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255
    t.string "memeber_id", limit: 255
    t.string "sender_id", limit: 255
    t.string "sender_name", limit: 4096
    t.string "sender_email", limit: 4096
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255, null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "spin_access_controls", id: :serial, force: :cascade do |t|
    t.string "spin_node_hashkey", limit: 255
    t.integer "spin_uid_access_right", default: -1
    t.integer "spin_gid_access_right", default: -1
    t.integer "spin_world_access_right", default: -1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "managed_node_hashkey", limit: 255
    t.integer "spin_node_type", default: 1, null: false
    t.integer "spin_uid", default: -1
    t.integer "spin_gid", default: -1
    t.integer "spin_domain_flag", default: 0
    t.integer "user_level_x", default: -1
    t.integer "user_level_y", default: -1
    t.boolean "is_void", default: false
    t.integer "px", default: -1
    t.integer "py", default: -1
    t.integer "ppx", default: -1
    t.integer "notify_upload", default: 0
    t.integer "notify_modify", default: 0
    t.integer "notify_delete", default: 0
    t.string "root_node_hashkey", limit: 255
    t.integer "lock_version", default: 0, null: false
    t.index ["is_void"], name: "index_spin_access_controls_on_is_void"
    t.index ["managed_node_hashkey"], name: "index_spin_access_controls_on_managed_node_hashkey"
    t.index ["notify_delete"], name: "index_spin_access_controls_on_notify_delete"
    t.index ["notify_modify"], name: "index_spin_access_controls_on_notify_modify"
    t.index ["notify_upload"], name: "index_spin_access_controls_on_notify_upload"
    t.index ["ppx"], name: "index_spin_access_controls_on_ppx"
    t.index ["px"], name: "index_spin_access_controls_on_px"
    t.index ["py"], name: "index_spin_access_controls_on_py"
    t.index ["spin_domain_flag"], name: "index_spin_access_controls_on_spin_domain_flag"
    t.index ["spin_gid"], name: "index_spin_access_controls_on_spin_gid"
    t.index ["spin_gid_access_right"], name: "index_spin_access_controls_on_spin_gid_access_right"
    t.index ["spin_node_hashkey"], name: "index_spin_access_controls_on_spin_node_hashkey"
    t.index ["spin_node_type"], name: "index_spin_access_controls_on_spin_node_type"
    t.index ["spin_uid"], name: "index_spin_access_controls_on_spin_uid"
    t.index ["spin_uid_access_right"], name: "index_spin_access_controls_on_spin_uid_access_right"
    t.index ["spin_world_access_right"], name: "index_spin_access_controls_on_spin_world_access_right"
    t.index ["user_level_x"], name: "index_spin_access_controls_on_user_level_x"
    t.index ["user_level_y"], name: "index_spin_access_controls_on_user_level_y"
  end

  create_table "spin_attributes_master", id: false, force: :cascade do |t|
    t.string "client_id", limit: 255, null: false
    t.string "attr_key", limit: 255, null: false
    t.string "attr_name", limit: 255, null: false
    t.string "attr_value", limit: 255
    t.string "spin_node_hashkey", limit: 255, null: false
  end

  create_table "spin_domains", id: :serial, force: :cascade do |t|
    t.integer "spin_did"
    t.string "spin_domain_name", limit: 4096
    t.string "spin_domain_root", limit: 4096
    t.text "domain_descr"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spin_domain_disp_name", limit: 255
    t.string "spin_server", limit: 4096
    t.string "domain_root_node_hashkey", limit: 255
    t.string "hash_key", limit: 255
    t.string "cont_location", limit: 255
    t.string "domain_writable_status", limit: 255
    t.string "domain_link", limit: 255
    t.string "img", limit: 4096
    t.integer "spin_uid"
    t.integer "spin_gid"
    t.integer "spin_uid_access_right"
    t.integer "spin_gid_access_right"
    t.integer "spin_world_access_right"
    t.datetime "spin_updated_at"
    t.integer "lock_version", default: 0
    t.text "domain_attributes"
    t.index ["cont_location"], name: "index_spin_domains_on_cont_location"
    t.index ["domain_root_node_hashkey"], name: "index_spin_domains_on_domain_root_node_hashkey"
    t.index ["hash_key"], name: "index_spin_domains_on_hash_key"
    t.index ["spin_domain_disp_name"], name: "index_spin_domains_on_spin_domain_disp_name"
    t.index ["spin_domain_name"], name: "index_spin_domains_on_spin_domain_name"
    t.index ["spin_domain_root"], name: "index_spin_domains_on_spin_domain_root"
    t.index ["spin_gid"], name: "index_spin_domains_on_spin_gid"
    t.index ["spin_gid_access_right"], name: "index_spin_domains_on_spin_gid_access_right"
    t.index ["spin_uid"], name: "index_spin_domains_on_spin_uid"
    t.index ["spin_uid_access_right"], name: "index_spin_domains_on_spin_uid_access_right"
    t.index ["spin_world_access_right"], name: "index_spin_domains_on_spin_world_access_right"
  end

  create_table "spin_file_servers", id: :serial, force: :cascade do |t|
    t.string "server_name", limit: 255, null: false
    t.string "server_host_name", limit: 255, default: "localhost"
    t.string "server_protocol", limit: 255, default: "http"
    t.string "server_alt_protocols", limit: 255, default: ""
    t.integer "server_port", default: 20000
    t.string "root_user", limit: 255, default: "root"
    t.string "root_password", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_path", limit: 4096, default: "spin_api_request"
    t.integer "max_connections", default: -1
    t.integer "max_pg_connections", default: -1
    t.integer "receive_timeout", default: -1
    t.integer "send_timeout", default: -1
    t.integer "session_timeout", default: -1
    t.string "spin_url_server_name", limit: 255
    t.index ["server_name"], name: "index_spin_file_servers_on_server_name", unique: true
  end

  create_table "spin_group_access_controls", id: :serial, force: :cascade do |t|
    t.integer "spin_gid"
    t.integer "spin_gid_access_right"
    t.integer "spin_uid_access_right"
    t.integer "spin_world_access_right"
    t.integer "spin_uid"
    t.integer "user_level_x"
    t.integer "user_level_y"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lock_version", default: 0
  end

  create_table "spin_group_members", id: :serial, force: :cascade do |t|
    t.integer "spin_uid"
    t.integer "spin_gid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "id_type", default: 0
    t.integer "lock_version", default: 0
    t.index ["id_type"], name: "index_spin_group_members_on_id_type"
    t.index ["spin_gid"], name: "index_spin_group_members_on_spin_gid"
    t.index ["spin_uid", "spin_gid"], name: "index_spin_group_members_on_spin_uid_and_spin_gid", unique: true
    t.index ["spin_uid"], name: "index_spin_group_members_on_spin_uid"
  end

  create_table "spin_groups", id: :serial, force: :cascade do |t|
    t.integer "spin_gid"
    t.string "spin_group_name", limit: 255
    t.text "group_descr"
    t.text "group_atrtributes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "owner_id", default: 0
    t.integer "id_type"
    t.integer "lock_version", default: 0
    t.index ["id_type"], name: "index_spin_groups_on_id_type"
    t.index ["spin_gid"], name: "index_spin_groups_on_spin_gid", unique: true
    t.index ["spin_group_name"], name: "index_spin_groups_on_spin_group_name"
  end

  create_table "spin_location_mappings", id: :serial, force: :cascade do |t|
    t.string "slm_hash_key", limit: 255
    t.integer "node_x_coord"
    t.integer "node_y_coord"
    t.integer "node_x_pr_coord"
    t.integer "node_type"
    t.integer "node_version"
    t.integer "vfs_type"
    t.string "node_hash_key", limit: 255
    t.string "location_path", limit: 4096
    t.integer "media_type"
    t.boolean "offline"
    t.boolean "local"
    t.integer "size_of_data"
    t.string "spin_storage_id", limit: 255
    t.string "spin_vfs_id", limit: 255
    t.text "slm_attributes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spin_server", limit: 255
    t.boolean "is_void", default: false
    t.integer "size_of_data_upper", default: 0
    t.integer "open_count", default: 0
    t.string "thumbnail_location_path", limit: 4096, default: ""
    t.string "proxy_location_path", limit: 4096, default: ""
    t.integer "spin_node_tree", default: 0
    t.string "preview_location_path", limit: 4096, default: ""
    t.string "file_content_type", limit: 255, default: ""
    t.integer "lock_version", default: 0, null: false
    t.index ["file_content_type"], name: "index_spin_location_mappings_on_file_content_type"
    t.index ["is_void"], name: "index_spin_location_mappings_on_is_void"
    t.index ["location_path"], name: "index_spin_location_mappings_on_location_path"
    t.index ["node_hash_key"], name: "index_spin_location_mappings_on_node_hash_key", unique: true
    t.index ["node_type"], name: "index_spin_location_mappings_on_node_type"
    t.index ["node_version"], name: "index_spin_location_mappings_on_node_version"
    t.index ["node_x_coord"], name: "index_spin_location_mappings_on_node_x_coord"
    t.index ["node_x_pr_coord"], name: "index_spin_location_mappings_on_node_x_pr_coord"
    t.index ["node_y_coord"], name: "index_spin_location_mappings_on_node_y_coord"
    t.index ["preview_location_path"], name: "index_spin_location_mappings_on_preview_location_path"
    t.index ["proxy_location_path"], name: "index_spin_location_mappings_on_proxy_location_path"
    t.index ["slm_hash_key"], name: "index_spin_location_mappings_on_slm_hash_key", unique: true
    t.index ["spin_node_tree"], name: "index_spin_location_mappings_on_spin_node_tree"
    t.index ["spin_server"], name: "index_spin_location_mappings_on_spin_server"
    t.index ["spin_storage_id"], name: "index_spin_location_mappings_on_spin_storage_id"
    t.index ["spin_vfs_id"], name: "index_spin_location_mappings_on_spin_vfs_id"
    t.index ["thumbnail_location_path"], name: "index_spin_location_mappings_on_thumbnail_location_path"
  end

  create_table "spin_lock_acls", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spin_lock_spin_nodes", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spin_lock_spin_processes", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_proc_id"
    t.index ["last_proc_id"], name: "index_spin_lock_spin_processes_on_last_proc_id", unique: true
  end

  create_table "spin_node_keeper_locas", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "my_number"
  end

  create_table "spin_node_keeper_locks", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "lock_session", limit: 255
    t.index ["lock_session"], name: "index_spin_node_keeper_locks_on_lock_session", unique: true
  end

  create_table "spin_node_keepers", id: :serial, force: :cascade do |t|
    t.integer "layer", default: 0, null: false
    t.integer "last_x", default: 0, null: false
    t.integer "first_free_x", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spin_tree_hashkey", limit: 255
    t.integer "nx"
    t.integer "ny"
    t.integer "current_version"
    t.integer "nx_pr"
    t.string "node_name", limit: 4096
    t.integer "node_type"
    t.integer "max_versions", default: -1, null: false
    t.integer "spin_node_tree", default: 0
    t.integer "lock_version", default: 0, null: false
    t.index ["first_free_x"], name: "index_spin_node_keepers_on_first_free_x"
    t.index ["last_x"], name: "index_spin_node_keepers_on_last_x"
    t.index ["layer", "spin_tree_hashkey"], name: "index_spin_node_keepers_on_layer_and_spin_tree_hashkey", unique: true
    t.index ["layer"], name: "index_spin_node_keepers_on_layer"
    t.index ["max_versions"], name: "index_spin_node_keepers_on_max_versions"
    t.index ["node_name"], name: "index_spin_node_keepers_on_node_name"
    t.index ["node_type"], name: "index_spin_node_keepers_on_node_type"
    t.index ["nx", "ny"], name: "index_spin_node_keepers_on_nx_and_ny", unique: true
    t.index ["nx"], name: "index_spin_node_keepers_on_nx"
    t.index ["nx_pr"], name: "index_spin_node_keepers_on_nx_pr"
    t.index ["ny"], name: "index_spin_node_keepers_on_ny"
    t.index ["spin_node_tree"], name: "index_spin_node_keepers_on_spin_node_tree"
    t.index ["spin_tree_hashkey"], name: "index_spin_node_keepers_on_spin_tree_hashkey"
  end

  create_table "spin_nodes", id: :serial, force: :cascade do |t|
    t.string "spin_node_hashkey", limit: 255
    t.integer "node_x_coord", default: -1, null: false
    t.integer "node_y_coord", default: -1, null: false
    t.integer "node_x_pr_coord", default: -1, null: false
    t.integer "node_type", default: -1, null: false
    t.integer "node_version", default: -1, null: false
    t.string "node_name", limit: 4096
    t.boolean "in_trash_flag", default: false, null: false
    t.boolean "is_dirty_flag", default: false, null: false
    t.boolean "is_under_maintenance_flag", default: false, null: false
    t.integer "in_use_uid", default: -1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "spin_uid", default: 0, null: false
    t.integer "spin_gid", default: 0, null: false
    t.integer "spin_uid_access_right", default: 15, null: false
    t.integer "spin_gid_access_right", default: 3, null: false
    t.integer "spin_world_access_right", default: 0, null: false
    t.integer "created_by", default: -1
    t.integer "updated_by", default: -1
    t.string "spin_private_key", limit: 4096
    t.string "spin_public_key", limit: 4096
    t.string "rsa_key", limit: 4096
    t.integer "max_versions"
    t.text "node_attributes"
    t.boolean "latest", default: true
    t.integer "lock_uid", default: -1
    t.boolean "is_open_flag", default: false
    t.string "spin_url", limit: 4096
    t.boolean "is_pending", default: false
    t.string "spin_vfs_id", limit: 255
    t.string "spin_storage_id", limit: 255
    t.integer "node_size"
    t.integer "node_size_upper", default: 0
    t.string "node_content_type", limit: 255
    t.integer "user_level_x", default: -1
    t.integer "user_level_y", default: -1
    t.datetime "trashed_at", default: "2001-01-01 00:00:00"
    t.boolean "is_void", default: false
    t.boolean "is_expanded", default: false
    t.boolean "is_domain_root_node", default: false
    t.datetime "spin_updated_at", default: "2000-12-31 15:00:00"
    t.integer "lock_status", default: 0
    t.datetime "mtime"
    t.datetime "ctime"
    t.integer "lock_mode", default: 0
    t.text "details"
    t.boolean "is_sticky", default: false
    t.integer "changed_by", default: -1
    t.text "node_description"
    t.datetime "spin_created_at"
    t.string "virtual_path", limit: 4096, default: ""
    t.boolean "orphan", default: false
    t.integer "modifier", default: -1
    t.integer "creator", default: -1
    t.integer "spin_tree_type", default: 0
    t.integer "spin_node_tree", default: 0
    t.datetime "notified_at", default: "2000-12-31 15:00:00"
    t.integer "notify_type", default: -1
    t.datetime "notified_new_at", default: "2000-12-31 15:00:00"
    t.datetime "notified_modification_at", default: "2000-12-31 15:00:00"
    t.datetime "notified_delete_at", default: "2000-12-31 15:00:00"
    t.string "memo1", limit: 255, default: ""
    t.string "memo2", limit: 255, default: ""
    t.string "memo3", limit: 255, default: ""
    t.string "memo4", limit: 255, default: ""
    t.string "memo5", limit: 255, default: ""
    t.boolean "is_synchronized", default: false
    t.boolean "is_archive", default: false
    t.string "key_virtual_path", limit: 4096
    t.boolean "is_paused", default: false
    t.integer "lock_version", default: 0, null: false
    t.integer "local_node_size", default: -1
    t.integer "local_node_size_upper", default: -1
    t.index ["changed_by"], name: "index_spin_nodes_on_changed_by"
    t.index ["creator"], name: "index_spin_nodes_on_creator"
    t.index ["ctime"], name: "index_spin_nodes_on_ctime"
    t.index ["in_trash_flag"], name: "index_spin_nodes_on_in_trash_flag"
    t.index ["in_use_uid"], name: "index_spin_nodes_on_in_use_uid"
    t.index ["is_archive"], name: "index_spin_nodes_on_is_archive"
    t.index ["is_dirty_flag"], name: "index_spin_nodes_on_is_dirty_flag"
    t.index ["is_expanded"], name: "index_spin_nodes_on_is_expanded"
    t.index ["is_open_flag"], name: "index_spin_nodes_on_is_open_flag"
    t.index ["is_paused"], name: "index_spin_nodes_on_is_paused"
    t.index ["is_pending"], name: "index_spin_nodes_on_is_pending"
    t.index ["is_sticky"], name: "index_spin_nodes_on_is_sticky"
    t.index ["is_synchronized"], name: "index_spin_nodes_on_is_synchronized"
    t.index ["is_under_maintenance_flag"], name: "index_spin_nodes_on_is_under_maintenance_flag"
    t.index ["is_void"], name: "index_spin_nodes_on_is_void"
    t.index ["key_virtual_path"], name: "index_spin_nodes_on_key_virtual_path"
    t.index ["latest"], name: "index_spin_nodes_on_latest"
    t.index ["lock_mode"], name: "index_spin_nodes_on_lock_mode"
    t.index ["lock_uid"], name: "index_spin_nodes_on_lock_uid"
    t.index ["modifier"], name: "index_spin_nodes_on_modifier"
    t.index ["mtime"], name: "index_spin_nodes_on_mtime"
    t.index ["node_content_type"], name: "index_spin_nodes_on_node_content_type"
    t.index ["node_description"], name: "index_spin_nodes_on_node_description"
    t.index ["node_name"], name: "index_spin_nodes_on_node_name"
    t.index ["node_type"], name: "index_spin_nodes_on_node_type"
    t.index ["node_version"], name: "index_spin_nodes_on_node_version"
    t.index ["node_x_coord"], name: "index_spin_nodes_on_node_x_coord"
    t.index ["node_x_pr_coord"], name: "index_spin_nodes_on_node_x_pr_coord"
    t.index ["node_y_coord"], name: "index_spin_nodes_on_node_y_coord"
    t.index ["notified_at"], name: "index_spin_nodes_on_notified_at"
    t.index ["notified_delete_at"], name: "index_spin_nodes_on_notified_delete_at"
    t.index ["notified_modification_at"], name: "index_spin_nodes_on_notified_modification_at"
    t.index ["notified_new_at"], name: "index_spin_nodes_on_notified_new_at"
    t.index ["notify_type"], name: "index_spin_nodes_on_notify_type"
    t.index ["orphan"], name: "index_spin_nodes_on_orphan"
    t.index ["spin_created_at"], name: "index_spin_nodes_on_spin_created_at"
    t.index ["spin_gid"], name: "index_spin_nodes_on_spin_gid"
    t.index ["spin_gid_access_right"], name: "index_spin_nodes_on_spin_gid_access_right"
    t.index ["spin_node_hashkey"], name: "index_spin_nodes_on_spin_node_hashkey", unique: true
    t.index ["spin_node_tree", "node_x_coord", "node_y_coord", "node_x_pr_coord", "node_version"], name: "node_location_index", unique: true
    t.index ["spin_node_tree"], name: "index_spin_nodes_on_spin_node_tree"
    t.index ["spin_tree_type"], name: "index_spin_nodes_on_spin_tree_type"
    t.index ["spin_uid"], name: "index_spin_nodes_on_spin_uid"
    t.index ["spin_uid_access_right"], name: "index_spin_nodes_on_spin_uid_access_right"
    t.index ["spin_updated_at"], name: "index_spin_nodes_on_spin_updated_at"
    t.index ["spin_url"], name: "index_spin_nodes_on_spin_url"
    t.index ["spin_world_access_right"], name: "index_spin_nodes_on_spin_world_access_right"
    t.index ["user_level_x"], name: "index_spin_nodes_on_user_level_x"
    t.index ["user_level_y"], name: "index_spin_nodes_on_user_level_y"
    t.index ["virtual_path"], name: "index_spin_nodes_on_virtual_path"
  end

  create_table "spin_objects", id: :serial, force: :cascade do |t|
    t.integer "node_x_coord"
    t.integer "node_y_coord"
    t.integer "node_x_pr_coord"
    t.integer "node_type"
    t.integer "node_version"
    t.string "object_name", limit: 255
    t.text "object_attributes"
    t.string "src_platform", limit: 255
    t.text "src_attributes"
    t.date "date_created"
    t.date "date_modified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "node_hashkey", limit: 255
    t.integer "object_size"
    t.datetime "ctime", default: "2000-12-31 15:00:00"
    t.datetime "mtime", default: "2000-12-31 15:00:00"
    t.index ["node_hashkey"], name: "index_spin_objects_on_node_hashkey"
  end

  create_table "spin_processes", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255
    t.integer "proc_action"
    t.integer "proc_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "spin_uid", default: -1
    t.integer "spin_storage_type", default: -1
    t.string "proc_message", limit: 255
    t.string "spin_node_hashkey", limit: 255
    t.integer "spin_job_id", default: -1
    t.integer "lock_version", default: 0, null: false
    t.index ["session_id", "spin_job_id"], name: "index_spin_processes_on_session_id_and_spin_job_id", unique: true
    t.index ["session_id"], name: "index_spin_processes_on_session_id"
    t.index ["spin_node_hashkey"], name: "index_spin_processes_on_spin_node_hashkey"
    t.index ["spin_storage_type"], name: "index_spin_processes_on_spin_storage_type"
    t.index ["spin_uid"], name: "index_spin_processes_on_spin_uid"
  end

  create_table "spin_sessions", id: :serial, force: :cascade do |t|
    t.string "spin_session_id", limit: 255
    t.integer "session_status"
    t.integer "spin_uid"
    t.string "spin_uname", limit: 255
    t.text "spin_session_data"
    t.string "spin_search_condition_id", limit: 255
    t.string "spin_search_option_id", limit: 255
    t.string "spin_domaindata_A_id", limit: 255
    t.string "spin_domaindata_B_id", limit: 255
    t.string "spin_filedata_id", limit: 255
    t.string "spin_folderdata_A_id", limit: 255
    t.string "spin_groupdata_id", limit: 255
    t.string "spin_memberdata_id", limit: 255
    t.string "spin_operatordata_id", limit: 255
    t.string "spin_recycledata_id", limit: 255
    t.string "spin_senderdata_id", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "server_session_id", limit: 4096
    t.text "spin_session_params"
    t.string "initial_uri", limit: 255
    t.text "spin_session_conf"
    t.string "spin_folderdata_B_id", limit: 255
    t.string "spin_current_directory", limit: 255, default: "/", null: false
    t.string "spin_last_session", limit: 255
    t.string "cont_location_domain", limit: 255
    t.string "cont_location_folder", limit: 255
    t.string "cont_location_file_list", limit: 255
    t.string "spin_current_domain", limit: 255
    t.datetime "last_access"
    t.datetime "session_expire"
    t.datetime "spin_login_time"
    t.datetime "spin_last_login"
    t.datetime "spin_last_logout"
    t.string "spin_filedata_A_id", limit: 255
    t.string "spin_filedata_B_id", limit: 255
    t.string "selected_domain_a", limit: 255
    t.string "selected_domain_b", limit: 255
    t.string "selected_folder_a", limit: 255
    t.string "selected_folder_b", limit: 255
    t.string "spin_application", limit: 255, default: "spin"
    t.string "selected_folder_at", limit: 255
    t.string "selected_folder_bt", limit: 255
    t.string "selected_folder_atfi", limit: 255
    t.string "selected_folder_btfi", limit: 255
    t.boolean "domain_a_is_dirty", default: false
    t.boolean "domain_b_is_dirty", default: false
    t.boolean "folder_a_is_dirty", default: false
    t.boolean "folder_b_is_dirty", default: false
    t.boolean "folder_at_is_dirty", default: false
    t.boolean "folder_bt_is_dirty", default: false
    t.boolean "folder_atfi_is_dirty", default: false
    t.boolean "folder_btfi_is_dirty", default: false
    t.boolean "file_list_a_is_dirty", default: false
    t.boolean "file_list_b_is_dirty", default: false
    t.integer "spin_agent_type"
    t.string "spin_agent_name", limit: 255
    t.string "current_selected_group_name", limit: 255
    t.string "spin_current_location", limit: 255, default: "folder_a"
    t.integer "lock_version", default: 0, null: false
    t.index ["domain_a_is_dirty"], name: "index_spin_sessions_on_domain_a_is_dirty"
    t.index ["domain_b_is_dirty"], name: "index_spin_sessions_on_domain_b_is_dirty"
    t.index ["file_list_a_is_dirty"], name: "index_spin_sessions_on_file_list_a_is_dirty"
    t.index ["file_list_b_is_dirty"], name: "index_spin_sessions_on_file_list_b_is_dirty"
    t.index ["folder_a_is_dirty"], name: "index_spin_sessions_on_folder_a_is_dirty"
    t.index ["folder_at_is_dirty"], name: "index_spin_sessions_on_folder_at_is_dirty"
    t.index ["folder_atfi_is_dirty"], name: "index_spin_sessions_on_folder_atfi_is_dirty"
    t.index ["folder_b_is_dirty"], name: "index_spin_sessions_on_folder_b_is_dirty"
    t.index ["folder_bt_is_dirty"], name: "index_spin_sessions_on_folder_bt_is_dirty"
    t.index ["folder_btfi_is_dirty"], name: "index_spin_sessions_on_folder_btfi_is_dirty"
    t.index ["selected_domain_a"], name: "index_spin_sessions_on_selected_domain_a"
    t.index ["selected_domain_b"], name: "index_spin_sessions_on_selected_domain_b"
    t.index ["selected_folder_a"], name: "index_spin_sessions_on_selected_folder_a"
    t.index ["selected_folder_at"], name: "index_spin_sessions_on_selected_folder_at"
    t.index ["selected_folder_atfi"], name: "index_spin_sessions_on_selected_folder_atfi"
    t.index ["selected_folder_b"], name: "index_spin_sessions_on_selected_folder_b"
    t.index ["selected_folder_bt"], name: "index_spin_sessions_on_selected_folder_bt"
    t.index ["selected_folder_btfi"], name: "index_spin_sessions_on_selected_folder_btfi"
    t.index ["server_session_id"], name: "index_spin_sessions_on_server_session_id"
    t.index ["spin_application"], name: "index_spin_sessions_on_spin_application"
    t.index ["spin_current_directory"], name: "index_spin_sessions_on_spin_current_directory"
    t.index ["spin_current_domain"], name: "index_spin_sessions_on_spin_current_domain"
    t.index ["spin_current_location"], name: "index_spin_sessions_on_spin_current_location"
    t.index ["spin_session_id"], name: "index_spin_sessions_on_spin_session_id", unique: true
    t.index ["spin_uid"], name: "index_spin_sessions_on_spin_uid"
  end

  create_table "spin_storages", id: :serial, force: :cascade do |t|
    t.string "storage_server", limit: 255, default: "127.0.0.1:18880", null: false
    t.string "storage_root", limit: 4096, default: ""
    t.string "mapping_logic", limit: 255, default: "LEAST_FILES", null: false
    t.integer "storage_max_size", default: -1
    t.text "storage_attributes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "size_gb", default: 0, null: false
    t.integer "size_sub_gb", default: 0, null: false
    t.integer "entries_b", default: 0, null: false
    t.integer "entries_sub_b", default: 0, null: false
    t.integer "storage_type", default: -1
    t.integer "max_directories", default: 0, null: false
    t.integer "max_entries_per_directory", default: 0, null: false
    t.string "storage_name", limit: 255, default: "", null: false
    t.string "load_balance_metric", limit: 255, default: "", null: false
    t.string "master_spin_storage_id", limit: 255, default: ""
    t.integer "priority_in_spin_storage_group", default: 1, null: false
    t.string "spin_storage_id", limit: 255, default: "", null: false
    t.string "spin_vfs_id", limit: 255, default: "", null: false
    t.integer "storage_max_entries", default: -1
    t.string "storage_current_directory", limit: 4096, default: "", null: false
    t.integer "storage_usage_gb", default: 0
    t.integer "storage_usage_sub_b", default: 0
    t.integer "storage_free_space_gb", default: 0
    t.integer "storage_free_space_sub_b", default: 0
    t.integer "storage_free_entries", default: 0
    t.boolean "is_default", default: false, null: false
    t.integer "spin_vfs_type", default: -1
    t.integer "spin_vfs_access_type", default: 3, null: false
    t.integer "spin_vfs_storage_logic", default: 0, null: false
    t.integer "storage_group_max_size", default: 0, null: false
    t.integer "storage_group_max_size_sub", default: 0, null: false
    t.integer "storage_group_max_entries", default: 0, null: false
    t.integer "storage_group_max_entries_sub", default: 0, null: false
    t.integer "storage_group_free_size", default: 0, null: false
    t.integer "storage_group_free_size_sub", default: 0, null: false
    t.integer "storage_group_free_entries", default: 0, null: false
    t.integer "storage_group_free_entries_sub", default: 0, null: false
    t.integer "storage_group_max_directories", default: 0, null: false
    t.integer "storage_group_max_directories_sub", default: 0, null: false
    t.integer "storage_group_max_entries_per_directory", default: 0, null: false
    t.integer "storage_group_max_entries_per_directory_sub", default: 0, null: false
    t.boolean "is_master", default: false, null: false
    t.string "thumbnail_root", limit: 4096, default: ""
    t.string "storage_tmp", limit: 4096, default: "", null: false
    t.integer "storage_max_entries_upper", default: -1
    t.integer "storage_max_size_upper", default: -1
    t.integer "storage_max_directories", default: -1
    t.integer "storage_max_directories_upper", default: -1
    t.integer "storage_max_entries_per_directory", default: -1
    t.integer "storage_max_entries_per_directory_upper", default: -1
    t.integer "storage_priority", default: -1
    t.integer "storage_current_directory_entries", default: 0
    t.integer "storage_group_current_size", default: 0, null: false
    t.integer "storage_group_current_size_upper", default: 0, null: false
    t.integer "storage_group_current_entries", default: 0, null: false
    t.integer "storage_group_current_entries_upper", default: 0, null: false
    t.integer "storage_group_current_directories", default: 0, null: false
    t.integer "storage_group_current_directories_upper", default: 0, null: false
    t.integer "storage_current_size", default: 0, null: false
    t.integer "storage_current_size_upper", default: 0, null: false
    t.integer "storage_current_entries", default: 0, null: false
    t.integer "storage_current_entries_upper", default: 0, null: false
    t.integer "storage_current_directories", default: 0, null: false
    t.integer "storage_current_directories_upper", default: 0, null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["master_spin_storage_id"], name: "index_spin_storages_on_master_spin_storage_id"
    t.index ["spin_storage_id"], name: "index_spin_storages_on_spin_storage_id", unique: true
    t.index ["spin_vfs_access_type"], name: "index_spin_storages_on_spin_vfs_access_type"
    t.index ["spin_vfs_id"], name: "index_spin_storages_on_spin_vfs_id"
    t.index ["spin_vfs_storage_logic"], name: "index_spin_storages_on_spin_vfs_storage_logic"
    t.index ["spin_vfs_type"], name: "index_spin_storages_on_spin_vfs_type"
  end

  create_table "spin_symlinks", id: false, force: :cascade do |t|
    t.integer "linked_node_x_coord"
    t.integer "linked_node_y_coord"
    t.integer "linked_node_x_pr_coord"
    t.integer "src_node_x_coord"
    t.integer "src_node_y_coord"
    t.integer "src_node_x_pr_coord"
  end

  create_table "spin_trees", id: :serial, force: :cascade do |t|
    t.string "spin_tree_hashkey", limit: 255
    t.string "spin_tree_name", limit: 255
    t.string "spin_tree_type", limit: 255
    t.text "spin_tree_attributes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_default"
    t.integer "node_x_coord"
    t.integer "node_y_coord"
    t.integer "node_x_pr_coord"
    t.integer "node_type"
    t.integer "node_version"
    t.integer "quota_gb", default: -1
    t.integer "quota_gb_upper", default: -1
    t.integer "usage_b", default: -1
    t.integer "usage_b_upper", default: -1
    t.index ["node_x_coord"], name: "index_spin_trees_on_node_x_coord"
    t.index ["node_x_pr_coord"], name: "index_spin_trees_on_node_x_pr_coord"
    t.index ["node_y_coord"], name: "index_spin_trees_on_node_y_coord"
  end

  create_table "spin_urls", id: :serial, force: :cascade do |t|
    t.string "spin_node_hashkey", limit: 255
    t.datetime "url_expires_at", default: "2000-12-31 15:00:00"
    t.string "url_server", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hash_key", limit: 255
    t.string "spin_url", limit: 4096
    t.integer "nx", default: -1
    t.integer "ny", default: -1
    t.integer "nprx", default: -1
    t.integer "nv", default: -1
    t.integer "nt", default: -1
    t.string "spin_node_name", limit: 4096
    t.datetime "url_valid_from", default: "2000-12-31 15:00:00"
    t.string "url_pass_phrase", limit: 255, default: ""
    t.string "generator_session", limit: 255
    t.integer "lock_version", default: 0
    t.index ["generator_session"], name: "index_spin_urls_on_generator_session"
    t.index ["hash_key"], name: "index_spin_urls_on_hash_key"
    t.index ["nprx"], name: "index_spin_urls_on_nprx"
    t.index ["nt"], name: "index_spin_urls_on_nt"
    t.index ["nv"], name: "index_spin_urls_on_nv"
    t.index ["nx", "ny"], name: "index_spin_urls_on_nx_and_ny"
    t.index ["nx"], name: "index_spin_urls_on_nx"
    t.index ["ny"], name: "index_spin_urls_on_ny"
    t.index ["spin_node_hashkey"], name: "index_spin_urls_on_spin_node_hashkey"
    t.index ["spin_node_name"], name: "index_spin_urls_on_spin_node_name"
    t.index ["spin_url"], name: "index_spin_urls_on_spin_url"
  end

  create_table "spin_user_attributes", id: :serial, force: :cascade do |t|
    t.integer "spin_uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spin_uname", limit: 4096, default: ""
    t.string "real_uname1", limit: 4096, default: ""
    t.string "real_uname2", limit: 4096, default: ""
    t.string "real_unameM", limit: 4096, default: ""
    t.string "mail_addr", limit: 4096, default: ""
    t.string "mail_addr2", limit: 4096, default: ""
    t.string "organization1", limit: 4096, default: ""
    t.string "organization2", limit: 4096, default: ""
    t.string "organization3", limit: 4096, default: ""
    t.string "organization4", limit: 4096, default: ""
    t.string "organization5", limit: 4096, default: ""
    t.string "organization6", limit: 4096, default: ""
    t.string "organization7", limit: 4096, default: ""
    t.string "organization8", limit: 4096, default: ""
    t.string "tel_country_code_1", limit: 255, default: ""
    t.string "tel_area_code_1", limit: 255, default: ""
    t.string "tel_pid_code_1", limit: 255, default: ""
    t.string "tel_number_1", limit: 255, default: ""
    t.string "tel_ext_1", limit: 255, default: ""
    t.text "user_attributes", default: ""
    t.index ["spin_uid"], name: "index_spin_user_attributes_on_spin_uid", unique: true
  end

  create_table "spin_users", id: :serial, force: :cascade do |t|
    t.integer "spin_uid"
    t.string "spin_uname", limit: 4096
    t.integer "user_level_x", default: 0
    t.integer "user_level_y", default: 0
    t.integer "spin_gid"
    t.integer "spin_projid"
    t.string "spin_passwd", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spin_login_directory", limit: 255
    t.string "spin_default_server", limit: 255
    t.string "spin_default_domain", limit: 255
    t.date "spin_passwd_expiration"
    t.boolean "is_group_editor", default: false
    t.integer "quota_gb", default: -1
    t.integer "quota_upper_gb", default: -1
    t.boolean "activated", default: false
    t.index ["activated"], name: "index_spin_users_on_activated"
    t.index ["is_group_editor"], name: "index_spin_users_on_is_group_editor"
    t.index ["spin_gid"], name: "index_spin_users_on_spin_gid"
    t.index ["spin_projid"], name: "index_spin_users_on_spin_projid"
    t.index ["spin_uid"], name: "index_spin_users_on_spin_uid", unique: true
    t.index ["spin_uname"], name: "index_spin_users_on_spin_uname"
    t.index ["user_level_x"], name: "index_spin_users_on_user_level_x"
    t.index ["user_level_y"], name: "index_spin_users_on_user_level_y"
  end

  create_table "spin_vfs_storage_mappings", id: :serial, force: :cascade do |t|
    t.string "spin_vfs", limit: 255
    t.string "spin_storage", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spin_storage"], name: "index_spin_vfs_storage_mappings_on_spin_storage"
    t.index ["spin_vfs"], name: "index_spin_vfs_storage_mappings_on_spin_vfs"
  end

  create_table "spin_vfs_tree_mappings", id: :serial, force: :cascade do |t|
    t.string "spin_vfs", limit: 255
    t.string "spin_node_tree", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spin_node_tree"], name: "index_spin_vfs_tree_mappings_on_spin_node_tree"
    t.index ["spin_vfs"], name: "index_spin_vfs_tree_mappings_on_spin_vfs"
  end

  create_table "spin_virtual_file_systems", id: :serial, force: :cascade do |t|
    t.string "spin_vfs_type", limit: 255
    t.string "spin_vfs_access_mode", limit: 255
    t.string "spin_vfs_name", limit: 4096
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spin_vfs_id", limit: 255
    t.integer "spin_vfs_size"
    t.integer "spin_vfs_max_entries"
    t.string "spin_vfs_storage_logic", limit: 255
    t.boolean "is_default"
    t.text "spin_vfs_attributes"
    t.index ["spin_vfs_id"], name: "index_spin_virtual_file_systems_on_spin_vfs_id", unique: true
  end

  create_table "target_folder_data", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255
    t.string "target_hash_key", limit: 255
    t.string "target_cont_location", limit: 255
    t.string "text", limit: 255
    t.string "target_folder", limit: 255
    t.string "target_ownership", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "domain_hash_key", limit: 255
    t.string "parent_hash_key", limit: 255
    t.string "spin_node_hashkey", limit: 255
    t.boolean "leaf", default: false
    t.boolean "expanded", default: false
    t.string "children", limit: 255
    t.boolean "target_folder_readable_status"
    t.boolean "target_folder_writable_status"
    t.boolean "target_parent_readable_status"
    t.boolean "target_parent_writable_status"
    t.datetime "spin_updated_at", default: "2000-12-31 15:00:00"
    t.index ["domain_hash_key"], name: "index_target_folder_data_on_domain_hash_key"
    t.index ["parent_hash_key"], name: "index_target_folder_data_on_parent_hash_key"
    t.index ["session_id"], name: "index_target_folder_data_on_session_id"
    t.index ["spin_node_hashkey"], name: "index_target_folder_data_on_spin_node_hashkey"
    t.index ["target_cont_location"], name: "index_target_folder_data_on_target_cont_location"
    t.index ["target_hash_key"], name: "index_target_folder_data_on_target_hash_key"
  end

  create_table "user_interface_managers", id: :serial, force: :cascade do |t|
    t.string "pane_domains_a", limit: 255
    t.string "pane_domains_b", limit: 255
    t.string "pane_folders_a", limit: 255
    t.string "pane_folders_b", limit: 255
    t.string "pane_file_list_a", limit: 255
    t.string "pane_file_list_b", limit: 255
    t.string "pane_file_list_s", limit: 255
    t.string "pane_folders_at", limit: 255
    t.string "pane_folders_bt", limit: 255
    t.string "pane_groupo_list_all", limit: 255
    t.string "pane_group_list_created", limit: 255
    t.string "pane_group_list_file", limit: 255
    t.string "pane_group_list_folder", limit: 255
    t.string "pane_mail_senders", limit: 255
    t.string "pane_member_list_mygroup", limit: 255
    t.string "pane_recycler", limit: 255
    t.string "pane_search_conditions", limit: 255
    t.string "pane_search_option", limit: 255
    t.string "pane_working_files", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
