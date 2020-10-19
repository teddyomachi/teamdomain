/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */


Ext.define('TeamDomain.model.ArchivedData', {
	extend: 'Ext.data.Model',

	fields: [
		{
			name: 'spin_node_hashkey',
			type: 'string'
		},
		{
			name: 'cont_location',
			type: 'string'
		},
		{
			name: 'node_name',
			type: 'string'
		},
		{
			name: 'created_date',
			type: 'date'
		},
		{
			name: 'created_at',
			type: 'date'
		},
		{
			name: 'creator',
			type: 'string'
		},
		{
			name: 'modified_date',
			type: 'date'
		},
		{
			name: 'updated_at',
			type: 'date'
		},
		{
			name: 'modifier',
			type: 'string'
		},
		{
			name: 'owner',
			type: 'string'
		},
		{
			name: 'ownership',
			type: 'string'
		},
		{
			name: 'control_right',
			type: 'boolean'
		},
		{
			name: 'dirty',
			type: 'boolean'
		},
		{
			name: 'keyword',
			type: 'string'
		},
		{
			name: 'description',
			type: 'string'
		},
		{
			name: 'icon_image',
			type: 'string'
		},
		{
			name: 'title',
			type: 'string'
		},
		{
			name: 'subtitle',
			type: 'string'
		},
		{
			name: 'frame_size',
			type: 'string'
		},
		{
			name: 'duration',
			type: 'string'
		},
		{
			name: 'producer',
			type: 'string'
		},
		{
			name: 'produced_date',
			type: 'string'
		},
		{
			name: 'location',
			type: 'string'
		},
		{
			name: 'client',
			type: 'string'
		},
		{
			name: 'cast',
			type: 'string'
		},
		{
			name: 'music',
			type: 'string'
		},
		{
			name: 'details',
			type: 'string'
		},
		{
			name: 'copyright',
			type: 'string'
		},
		{
			name: 'portrait_right',
			type: 'string'
		},
		{
			name: 'access_group',
			type: 'string'
		},
		{
			name: 'file_readable_status',
			type: 'boolean'
		},
		{
			name: 'file_writable_status',
			type: 'boolean'
		},
		{
			name: 'open_status',
			type: 'boolean'
		},
		{
			name: 'folder_hash_key',
			type: 'string'
		},
		{
			name: 'folder_readable_status',
			type: 'boolean'
		},
		{
			name: 'folder_writable_status',
			type: 'boolean'
		},
		{
			name: 'selected_file',
			type: 'boolean'
		},
		{
			name: 'other_readable',
			type: 'boolean'
		},
		{
			name: 'other_writable',
			type: 'boolean'
		},
		{
			name: 'virtual_path',
			type: 'string'
		}                
	]
});