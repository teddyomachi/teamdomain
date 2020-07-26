/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

Ext.define('TeamDomain.model.MemberTree',
	{
            extend : 'Ext.data.Model',
            fields :
            [
                {
                    type : 'string',
                    name : 'text'
		},
                {
                    type : 'string',
                    name : 'member_name'
		},
		{
                    type : 'string',
                    name : 'group_name'
		},
                {
                    type : 'int',
                    name : 'member_id'
		},
		{
                    type : 'int',
                    name : 'group_id'
		},
                {
                    type:'int',
                    name:'owner_id'
                }
            ]
	});

