/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

Ext.define('TeamDomain.store.MemberTreeStore',
{
    extend:'Ext.data.TreeStore',
    constructor:function(cfg)
    {
        var me = this;
	cfg = cfg || {};
	me.callParent([Ext.apply(
        {
            model:'TeamDomain.model.MemberTree',
            storeId: 'MemberTreeStore',
            proxy:
            {
		type: 'ajax',
		url: 'spin/group_list_tree.sfl',
		reader:
                {
                    type: 'json'
		}
            },
            root:
            {
                text:'members',
                expanded:true
            },
            listeners:
            {
                load:function(me,records)
                {
                    Ext.Msg.hide();
                }
            }
        }, cfg)]);
    }
});

