/*
This file is not a part of Ext JS
Authored by (c) 2012 WoodvilleJapan
This should be used to check the codition whenever any contents are selected in TeamDomain.
*/

function doCheckDomain(editChecked) {
	if (editChecked === true) {
		Ext.getCmp('domain_name_1').enable();
		//Ext.getCmp('btn_change_domain_name').enable();
		Ext.getCmp('new_root_folder').enable();
		Ext.getCmp('btn_create_root_folder').enable();
		Ext.getCmp('uploadRootFile').enable();
		Ext.getCmp('btn_upload_root_file').enable();
	} else {
		Ext.getCmp('domain_name_1').disable();
		Ext.getCmp('btn_change_domain_name').disable();
		Ext.getCmp('new_root_folder').disable();
		Ext.getCmp('btn_create_root_folder').disable();
		Ext.getCmp('uploadRootFile').disable();
		Ext.getCmp('btn_upload_root_file').disable();
	}
}
