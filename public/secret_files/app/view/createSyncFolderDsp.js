/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
Ext.define('TeamDomain.view.createSyncFolderDsp', {
    extend: 'Ext.window.Window',
    alias: 'widget.createSyncFolderDsp',
    height: 500,
    hidden: false,
    id: 'createSyncFolderDsp',
    itemId: 'createSyncFolderDsp',
    width: 320,
    layout: {
        type: 'fit'
    },
    title: '同期フォルダ作成',
    constrain: true,
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
                    layout: {
                        align: 'stretch',
                        //type: 'hbox'
                        type: 'fit'

                    },
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
                                    id: 'syncFolderTree',
                                    autoScroll: true,
                                    title: 'フォルダ',
                                    sortableColumns: false,
                                    store: Ext.create('TeamDomain.store.LocalFolderDataStore', {jsonData: formX
                                    }),
                                    rootVisible: false,
                                    selModel: Ext.create('Ext.selection.CheckboxModel', {mode: 'SINGLE', allowDeselect: true
                                    }),
                                    listeners: {
                                        beforeitemexpand: {
                                            fn: me.onTreePanelItemExpand,
                                            scope: me
                                        }
                                    }
                                },
                                {
                                    xtype: 'hiddenfield',
                                    fieldLabel: 'Label',
                                    name: 'syncFolder_cont_location'
                                },
                                {
                                    xtype: 'hiddenfield',
                                    fieldLabel: 'Label',
                                    name: 'syncFolder_hash_key'
                                },
                                {
                                    xtype: 'hiddenfield',
                                    id: 'syncFolder_writable_status',
                                    fieldLabel: 'Label',
                                    name: 'syncFolder_writable_status'
                                }
                            ]
                        }
                        /*{
                         xtype: 'panel',
                         width: 500,
                         region: 'center',
                         layout: {
                         type: 'fit'
                         },
                         title: 'ファイル',
                         items: [
                         {
                         xtype: 'gridpanel',
                         id: 'syncFolderList',
                         autoScroll: true,
                         store: Ext.create('TeamDomain.store.LocalFileDataStore'),
                         viewConfig: {
                         emptyText: 'データがありません',
                         listeners: {
                         beforedrop: {
                         fn: me.onGriddragdroppluginBeforeDropA,
                         scope: me
                         }
                         }
                         },
                         selModel: Ext.create('Ext.selection.CheckboxModel', {checkOnly: true
                         //                                                                                                                ,listeners: {
                         //                                                                                                                    afterrender: {
                         //                                                                                                                            fn: me.onCheckBoxModelAfterRender,
                         //                                                                                                                            scope: me
                         //                                                                                                                    }
                         //                                                                                                                }
                         }),
                         columns: [
                         {
                         xtype: 'gridcolumn',
                         renderer: function (value, metaData, record, rowIndex, colIndex, store, view) {
                         var thumbnail = '';
                         if ('1' === record.data.node_type) {
                         // フォルダ
                         thumbnail = './file_type_icon/FolderDocument.png';
                         } else if ('2' === record.data.node_type) {
                         // ファイル
                         thumbnail = './file_type_icon/text.png';
                         } else if ('5' === record.data.node_type) {
                         // フォルダのシンボリックリンク
                         thumbnail = './file_type_icon/text.png';
                         } else if ('6' === record.data.node_type) {
                         // ファイルのシンボリックリンク
                         thumbnail = './file_type_icon/text.png';
                         }
                         return '<img src="' + thumbnail + '" style="max-width:25px;max-height: 25px"/>';
                         },
                         padding: 0,
                         width: 35,
                         dataIndex: 'type',
                         text: 'TP'
                         },
                         {
                         xtype: 'gridcolumn',
                         minWidth: 150,
                         width: 150,
                         dataIndex: 'text',
                         text: '名前',
                         flex: 1
                         },
                         {
                         xtype: 'gridcolumn',
                         width: 100,
                         align: 'right',
                         dataIndex: 'size',
                         text: 'サイズ'
                         },
                         {
                         xtype: 'gridcolumn',
                         renderer: function (value, metaData, record, rowIndex, colIndex, store, view) {
                         if (typeof value === "string") {
                         value = parseInt(value);
                         }
                         var dtDate = new Date(value * 1000);
                         return Ext.util.Format.date(dtDate, 'Y-M-d H:i:s');
                         },
                         width: 140,
                         dataIndex: 'created_unix_time',
                         text: '作成日'
                         },
                         {
                         xtype: 'gridcolumn',
                         renderer: function (value, metaData, record, rowIndex, colIndex, store, view) {
                         if (typeof value === "string") {
                         value = parseInt(value);
                         }
                         var dtDate = new Date(value * 1000);
                         return Ext.util.Format.date(dtDate, 'Y-M-d H:i:s');
                         },
                         width: 140,
                         dataIndex: 'modified_unix_time',
                         text: '更新日'
                         }
                         ],
                         dockedItems: [
                         {
                         xtype: 'pagingtoolbar',
                         dock: 'bottom',
                         autoRender: true,
                         id: 'addList_list',
                         displayInfo: true,
                         store: 'LocalFileDataStore'
                         }
                         ]
                         }
                         ]
                         }*/
                    ],
                    dockedItems: [
                        {
                            xtype: 'toolbar',
                            dock: 'bottom',
                            items: [
                                {
                                    xtype: 'fieldcontainer',
                                    items: [
                                        {
                                            xtype: 'button',
                                            id: 'syncFolderCancelBtn',
                                            handler: function (button, event) {
                                                Ext.getCmp('createSyncFolderDsp').close();
                                            },
                                            margin: '2 0 0 5',
                                            width: 100,
                                            text: 'キャンセル',
                                            tooltip: '終了します。',
                                            tooltipType: 'title'
                                        },
                                        {
                                            xtype: 'button',
                                            id: 'createSyncFolderBtn',
                                            disabled: true,
                                            handler: function (button, event) {
                                                var grid = Ext.getCmp(TargetComp);
                                                var model = grid.getSelectionModel();
                                                var record = model.getSelection()[0];

                                                //ローカルフォルダ取得
                                                var lgrid = Ext.getCmp('syncFolderTree');
                                                var lmodel = lgrid.getSelectionModel();
                                                var lrecord = lmodel.getSelection()[0];

                                                this.disable();
                                                Ext.getCmp('syncFolderCancelBtn').disable();
                                                //Ext.getCmp('addAgentProgress').show();

                                                var sendData = Ext.apply({session_id: this_session_id});
                                                sendData = Ext.apply({request_type: 'set_sync_folder'}, sendData);
                                                sendData = Ext.apply({params: [lrecord.data.node_path, record.data.hash_key]}, sendData);

                                                console.log('test1');
                                                
                                                Ext.Ajax.request({
                                                    url: 'http://127.0.0.1:18880/spinagent/spin_api_request',
                                                    method: 'POST',
                                                    jsonData: sendData,
                                                    success: handleSuccess,
                                                    failure: handleFailure
                                                });

                                                console.log('test2');

                                                function handleFailure(response) {
                                                    alert('ERROR');
                                                    Ext.getCmp('syncFolderCancelBtn').enable();
                                                    Busy = false;
                                                    Ext.Msg.show({
                                                        title: '同期失敗',
                                                        msg: 'サーバとの通信に失敗しました',
                                                        buttons: Ext.Msg.OK
                                                    });
                                                    return;
                                                }
                                                function handleSuccess(response) {
                                                    Ext.getCmp('syncFolderCancelBtn').enable();
                                                    obj = Ext.decode(response.responseText);
                                                    var request_success = obj.success;
                                                    if (request_success === false) {
                                                        Busy = false;
                                                        var request_errors = obj.errors;
                                                        Ext.Msg.show({
                                                            title: '同期失敗',
                                                            msg: request_errors,
                                                            buttons: Ext.Msg.OK
                                                        });
                                                        return;
                                                    } else {
                                                        Ext.Msg.show({
                                                            title: '同期完了',
                                                            msg: 'フォルダの同期が完了しました。',
                                                            buttons: Ext.Msg.OK,
                                                            fn: function (btn)
                                                            {
                                                                if (btn == 'ok')
                                                                {
                                                                    Ext.getCmp('createArchiveFolderDsp').close();
                                                                }
                                                            }
                                                        });
                                                    }
                                                }
                                            },
                                            margin: '2 0 0 5',
                                            width: 100,
                                            text: '作成',
                                            tooltip: '同期フォルダを作成します。',
                                            tooltipType: 'title'
                                        }
                                    ]
                                },
                                {
                                    xtype: 'tbfill'
                                },
                                {
                                    xtype: 'progressbar',
                                    margin: '0 5 0 0',
                                    id: 'syncFolderProgress',
                                    width: 450,
                                    hidden: true
                                }
                            ]
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


