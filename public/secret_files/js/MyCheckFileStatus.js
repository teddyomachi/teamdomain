/*
This file is not a part of Ext JS
Authored by (c) 2012 WoodvilleJapan
This should be used to check the codition whenever any contents are selected in TeamDomain.
*/

function doTargetFile(originalWriteChecked, targetWriteChecked, fileLockChecked, fileWriteChecked, fileOpenChecked) {

	if (targetWriteChecked == true && (fileLockChecked == 0 || fileLockChecked == 1 || fileLockChecked == 2 || fileLockChecked == 4)) {
		Ext.getCmp('btn_copy_file').enable();
	} else {
		Ext.getCmp('btn_copy_file').disable();
	}

	if (originalWriteChecked == true && targetWriteChecked == true && fileWriteChecked == true && (fileLockChecked == 0 || (fileLockChecked == 1 && fileOpenChecked == false))) {
		Ext.getCmp('btn_move_file').enable();
	} else {
		Ext.getCmp('btn_move_file').disable();
	}

	if (originalWriteChecked == true && fileWriteChecked == true && (fileLockChecked == 0 || (fileLockChecked == 1 && fileOpenChecked == false))) {
		Ext.getCmp('btn_delete_file').enable();
	} else {
		Ext.getCmp('btn_delete_file').disable();
	}
}

function doCheckFile(folderReadChecked, folderWriteChecked, fileReadChecked, fileWriteChecked, fileOwnershipChecked, fileControllerChecked, fileLockChecked, fileOpenChecked, targetStatus, lcUserId, this_op_id) {

	//if (fileOwnershipChecked == 'me' || fileControllerChecked == true) {
	if (fileControllerChecked == true) {
		Ext.getCmp('fileAccess').enable();
	} else {
		Ext.getCmp('fileAccess').disable();
	}

	if (fileWriteChecked == true && (fileLockChecked == 0 || (fileLockChecked == 1 && fileOpenChecked == false))) {
		Ext.getCmp('change_file_name').enable();
		Ext.getCmp('change_file_title').enable();
		Ext.getCmp('change_file_subtitle').enable();
		Ext.getCmp('change_file_keyword').enable();
		Ext.getCmp('change_file_description').enable();
		Ext.getCmp('btn_change_file_property').enable();
		Ext.getCmp('view_file_name').enable();
		Ext.getCmp('view_title').enable();
		Ext.getCmp('view_subtitle').enable();
		Ext.getCmp('view_keyword').enable();
		Ext.getCmp('view_file_description').enable();
		Ext.getCmp('change_duration').enable();
		Ext.getCmp('change_producer').enable();
		Ext.getCmp('change_produced_date').enable();
		Ext.getCmp('change_location').enable();
		Ext.getCmp('change_cast').enable();
		Ext.getCmp('change_client').enable();
		Ext.getCmp('change_copyright').enable();
		Ext.getCmp('change_music').enable();
		Ext.getCmp('btn_change_file_extension').enable();
	} else {
		Ext.getCmp('change_file_name').disable();
		Ext.getCmp('change_file_title').disable();
		Ext.getCmp('change_file_subtitle').disable();
		Ext.getCmp('change_file_keyword').disable();
		Ext.getCmp('change_file_description').disable();
		Ext.getCmp('btn_change_file_property').disable();
		Ext.getCmp('view_file_name').disable();
		Ext.getCmp('view_title').disable();
		Ext.getCmp('view_subtitle').disable();
		Ext.getCmp('view_keyword').disable();
		Ext.getCmp('view_file_description').disable();
		Ext.getCmp('change_duration').disable();
		Ext.getCmp('change_producer').disable();
		Ext.getCmp('change_produced_date').disable();
		Ext.getCmp('change_location').disable();
		Ext.getCmp('change_cast').disable();
		Ext.getCmp('change_client').disable();
		Ext.getCmp('change_copyright').disable();
		Ext.getCmp('change_music').disable();
		Ext.getCmp('btn_change_file_extension').disable();
	}

	if (fileLockChecked == 0 || fileLockChecked == 1 || fileLockChecked == 2 || fileLockChecked == 4) {
		Ext.getCmp('radio_open_writable').disable();
		Ext.getCmp('radio_open_only').enable();
		Ext.getCmp('check_version').enable();
		Ext.getCmp('open_ver_number').enable();
		Ext.getCmp('btn_open_file').enable();

		if (folderWriteChecked == true && fileWriteChecked == true && (fileLockChecked == 0 || (fileLockChecked == 1 && fileOpenChecked == false))) {
			Ext.getCmp('radio_open_writable').enable();
		}
	} else {
		Ext.getCmp('radio_open_writable').disable();
		Ext.getCmp('radio_open_only').disable();
		Ext.getCmp('check_version').disable();
		Ext.getCmp('open_ver_number').disable();
		Ext.getCmp('btn_open_file').disable();
	}

	if (targetStatus == true && (fileLockChecked == 0 || fileLockChecked == 1 || fileLockChecked == 2 || fileLockChecked == 4)) {
	//if (targetStatus === true) {
		Ext.getCmp('btn_copy_file').enable();
	} else {
		//console.log('doCheckFile_copy', targetStatus);
		//console.log('doCheckFile_copy', fileLockChecked);
		Ext.getCmp('btn_copy_file').disable();
	}

	if (folderWriteChecked == true && targetStatus == true && fileWriteChecked == true && (fileLockChecked == 0 || (fileLockChecked == 1 && fileOpenChecked == false))) {
	//if (targetStatus === true) {
		Ext.getCmp('btn_move_file').enable();
	} else {
		//console.log('doCheckFile_move', targetStatus);
		//console.log('doCheckFile_move', fileLockChecked);
		Ext.getCmp('btn_move_file').disable();
	}

	if (folderWriteChecked == true && fileWriteChecked == true && (fileLockChecked == 0 || (fileLockChecked == 1 && fileOpenChecked == false))) {
		Ext.getCmp('btn_delete_file').enable();
	} else {
		Ext.getCmp('btn_delete_file').disable();
	}

	if ((folderWriteChecked == true && fileWriteChecked == true) && (fileLockChecked == 0 || (fileLockChecked == 1 && fileOpenChecked == false))) {
		Ext.getCmp('checkout_version').enable();
		Ext.getCmp('checkout_ver_number').enable();
		Ext.getCmp('checkout_for_others').enable();
		Ext.getCmp('btn_checkout').enable();
		Ext.getCmp('btn_checkin').disable();
		Ext.getCmp('btn_checkout_cancel').disable();
	} else if ((fileLockChecked == 4 || fileLockChecked == 8) && (fileOwnershipChecked == 'me' || fileControllerChecked == true)) {
		//Ext.getCmp('checkOut').enable();
		Ext.getCmp('checkout_version').disable();
		Ext.getCmp('checkout_ver_number').disable();
		Ext.getCmp('checkout_for_others').disable();
		Ext.getCmp('btn_checkout').disable();
		Ext.getCmp('btn_checkin').disable();
		Ext.getCmp('btn_checkout_cancel').enable();
	} else {
		Ext.getCmp('checkout_version').disable();
		Ext.getCmp('checkout_ver_number').disable();
		Ext.getCmp('checkout_for_others').disable();
		Ext.getCmp('btn_checkout').disable();
		Ext.getCmp('btn_checkin').disable();
		Ext.getCmp('btn_checkout_cancel').disable();
	}

	if (folderWriteChecked == true && fileWriteChecked == true && fileLockChecked == 0) {
		Ext.getCmp('btn_lock_file').enable();
		Ext.getCmp('btn_unlock_file').disable();
	} else if (folderWriteChecked == true && fileWriteChecked == true && fileLockChecked == 1) {
		Ext.getCmp('btn_lock_file').disable();
		Ext.getCmp('btn_unlock_file').enable();
	} else if (folderWriteChecked == true && fileWriteChecked == true && fileLockChecked == 2 && (fileOwnershipChecked == 'me' || fileControllerChecked == true)) {
		Ext.getCmp('btn_lock_file').disable();
		Ext.getCmp('btn_unlock_file').enable();
	} else {
		Ext.getCmp('btn_lock_file').disable();
		Ext.getCmp('btn_unlock_file').disable();
	}

	if (fileOwnershipChecked == 'me' && fileLockChecked !== 8) {
		Ext.getCmp('btn_release_ownership_file').enable();
		Ext.getCmp('btn_get_ownership_file').disable();
	} else if (folderWriteChecked == true && fileWriteChecked == true && fileOwnershipChecked == 'nobody') {
		Ext.getCmp('btn_release_ownership_file').disable();
		Ext.getCmp('btn_get_ownership_file').enable();
	} else {
		Ext.getCmp('btn_release_ownership_file').disable();
		Ext.getCmp('btn_get_ownership_file').disable();
	}
}
