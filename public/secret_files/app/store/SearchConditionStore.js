/*
 * File: app/store/SearchConditionStore.js
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

Ext.define('TeamDomain.store.SearchConditionStore', {
	extend: 'Ext.data.Store',

	requires: [
		'TeamDomain.model.SearchConditionData'
	],

	constructor: function(cfg) {
		var me = this;
		cfg = cfg || {};
		me.callParent([Ext.apply({
			model: 'TeamDomain.model.SearchConditionData',
			storeId: 'SearchConditionStore',
			proxy: {
				type: 'ajax',
				url: 'spin/search_conditions.sfl',
				reader: {
					type: 'json',
					root: 'conditions'
				}
			}
		}, cfg)]);
	}
});