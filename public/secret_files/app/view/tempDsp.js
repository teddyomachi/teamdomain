/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
Ext.define('TeamDomain.view.tempDsp', {
    extend: 'Ext.window.Window',
    alias: 'widget.tempDsp',
    height: 500,
    hidden: false,
    id: 'tempDsp',
    itemId: 'tempDsp',
    width: 320,
    layout: {
        type: 'fit'
    },
    title: '同期フォルダ作成',
    //constrain: true,
    initComponent: function () {
        var me = this;
        var formX;
        formX = Ext.apply({session_id: this_session_id}, formX);
        formX = Ext.apply({request_type: 'get_node_list'}, formX);
        formX = Ext.apply({params: ['$HOME', 1, false]}, formX);
        Ext.applyIf(me, {
            items: [
                {
                    xtype: 'panel',
                    //width: 285,
                    layout: {
                        type: 'fit'
                    },
                    items: [
                        {
                            xtype: 'treepanel',
                            flex: 1,
                            id: 'tempTree',
                            autoScroll: true,
                            title: 'フォルダ',
                            sortableColumns: false,
                            store: Ext.create('TeamDomain.store.LocalFolderDataStore', {jsonData: formX}),
                            //store: Ext.create('TeamDomain.store.FolderDataStoreA'),
                            rootVisible: false,
                            selModel: Ext.create('Ext.selection.CheckboxModel', {mode: 'SINGLE', allowDeselect: true}),
                            listeners: {
                                beforeitemexpand: {
                                    fn: me.onTreePanelItemExpand,
                                    scope: me
                                }
                            }
                        }
                    ]
                }
            ]
        });
        me.callParent(arguments);
    },
    onTreePanelItemExpand: function (nodeinterface, eOpts) {
        var formX;
        formX = Ext.apply({session_id: this_session_id}, formX);
        formX = Ext.apply({request_type: 'get_node_list'}, formX);
        formX = Ext.apply({params: [nodeinterface.data.node_path, 1, false]}, formX);
        Ext.getStore('LocalFolderDataStore').jsonData = formX;
    }
});


