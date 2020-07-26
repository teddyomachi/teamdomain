/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */


Ext.define('TeamDomain.view.temppanel', 
{
    extend: 'Ext.tree.Panel',
    alias: 'widget.temppanel',
    id: 'temppanel',
    itemId: 'temppanel',
    autoScroll: true,
    title: 'テスト用パネル',
    rootVisible: false,
    initComponent: function()
    {
        var me = this;
        var formX;
        formX = Ext.apply({session_id: this_session_id}, formX);
        formX = Ext.apply({request_type: 'get_node_list'}, formX);
        formX = Ext.apply({params: ['$HOME', 1, false]}, formX);
        
        Ext.applyIf(me,
        {
           //store: 'FolderDataStoreA'
           //store: Ext.create('TeamDomain.store.FolderDataStoreB', {jsonData: formX})
           store: Ext.create('TeamDomain.store.LocalFolderDataStore', {jsonData: formX})
        });
        me.callParent(arguments);
    }
});