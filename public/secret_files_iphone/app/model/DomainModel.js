/*
 * File: app/model/DomainModel.js
 *
 * This file was generated by Sencha Architect version 2.2.2.
 * http://www.sencha.com/products/architect/
 *
 * This file requires use of the Sencha Touch 2.2.x library, under independent license.
 * License of Sencha Architect does not include license for Sencha Touch 2.2.x. For more
 * details see http://www.sencha.com/license or contact license@sencha.com.
 *
 * This file will be auto-generated each and everytime you save your project.
 *
 * Do NOT hand edit this file.
 */

Ext.define('BoomBoxMobile.model.DomainModel', {
	extend: 'Ext.data.Model',

	config: {
		fields: [
			{
				name: 'hash_key',
				type: 'string'
			},
			{
				name: 'cont_location',
				type: 'string'
			},
			{
				name: 'domain_writable_status',
				type: 'boolean'
			},
			{
				name: 'domain_name',
				type: 'string'
			},
			{
				name: 'domain_link',
				type: 'string'
			},
			{
				name: 'img',
				type: 'string'
			},
			{
				name: 'selected',
				type: 'boolean'
			}
		]
	}
});