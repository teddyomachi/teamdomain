/*
 * File: app/store/ActiveOperatorStore.js
 *
 * This file was generated by Sencha Architect version 2.2.2.
 * http://www.sencha.com/products/architect/
 *
 * This file requires use of the Ext JS 4.0.x library, under independent license.
 * License of Sencha Architect does not include license for Ext JS 4.0.x. For more
 * details see http://www.sencha.com/license or contact license@sencha.com.
 *
 * This file will be auto-generated each and everytime you save your project.
 *
 * Do NOT hand edit this file.
 */

Ext.define('TeamDomain.store.ActiveOperatorStore', {
	extend: 'Ext.data.Store',

	requires: [
		'TeamDomain.model.OperatorData'
	],

	constructor: function(cfg) {
		var me = this;
		cfg = cfg || {};
		me.callParent([Ext.apply({
			model: 'TeamDomain.model.OperatorData',
			storeId: 'ActiveOperatorStore',
			proxy: {
				type: 'ajax',
				url: 'spin/active_operator.sfl',
				reader: {
					type: 'json',
					root: 'operator'
				}
			},
			listeners: {
				load: {
					fn: me.onJsonstoreLoad,
					scope: me
				}
			}
		}, cfg)]);
	},

	onJsonstoreLoad: function(store, records, successful, operation, eOpts) {
		var this_records = store.data.items[0].data;

		this_op_name			= this_records.operator_name;
		this_op_id				= this_records.operator_id;
		this_op_description		= this_records.user_description;
		This_op_group_editable	= this_records.operator_group_editable;
		This_op_cntrl_editable	= this_records.operator_control_editable;
		this_op_created_date	= this_records.rule_created_date;
		this_op_disp_ext		= this_records.disp_ext;
		this_op_auto_save		= this_records.auto_save;
		this_op_disp_tree		= this_records.disp_tree;
		this_op_mail			= this_records.user_mail;
		this_op_tel				= this_records.user_tel;
		this_op_major			= this_records.user_major;
		this_op_org				= this_records.user_org;

		Ext.getCmp('activeUser').getForm().setValues({
			active_op_name: this_op_name
		});
/*
		Ext.getCmp('createFile').getForm().setValues({
			session_id: this_session_id
		});
*/
		//console.log(This_op_group_editable);
		if (This_op_group_editable !== true && GroupDspClosed === false) {
			//console.log(Ext.getCmp('groupDsp'));
//			Ext.getCmp('groupDsp').close();
			//Ext.getCmp('groupDsp').disable();
			GroupDspClosed = true;
		}

		//console.log(This_op_cntrl_editable);
		if (This_op_cntrl_editable !== true && UserDspClosed === false) {
//			Ext.getCmp('userDsp').close();
			UserDspClosed = true;
		}

//		Ext.ComponentQuery.query('#westSideB')[0].collapse();
	}

});