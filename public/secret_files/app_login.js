/*
 * File: app.js
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

//@require @packageOverrides
Ext.Loader.setConfig({
	enabled: true,
	paths: {
		'Ext.ux.DataView': '../ext/src/ux/DataView',
		'Ext.TeamDomain': 'js'
	}
});

Ext.application({

	requires: [
		'Teamdomain.view.LoginWin',
		'Teamdomain.view.ActivationWin'
	],
	views: [
		'LoginWin',
		'ActivationWin'
	],
	//autoCreateViewport: true,
	name: 'Teamdomain',

	launch: function() {
		Ext.override(Ext.data.Connection, {
			timeout: 300000
		});
                
                Ext.create('Teamdomain.view.ViewportLogin');
		//Ext.Ajax.timeout = 300000;
	}

});
