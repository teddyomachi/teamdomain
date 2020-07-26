/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
Ext.define('TeamDomain.view.resetArchiveFolderDsp', {
    extend: 'Ext.window.Window',
    alias: 'widget.resetArchiveFolderDsp',
    height: 500,
    hidden: false,
    id: 'resetArchiveFolderDsp',
    itemId: 'resetArchiveFolderDsp',
    width: 500,
    layout: {
        type: 'fit'
    },
    title: 'アーカイブフォルダ解除',
    constrain: true,
    initComponent: function () {
        var me = this;
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
                            width: 800,
                            //region: 'center',
                            layout: {
                                type: 'fit'
                            },
                            title: 'フォルダー',
                            items: [
                                {
                                    xtype: 'gridpanel',
                                    id: 'rearchiveFolderList',
                                    autoScroll: true,
                                    store: 'ArchivedFolderDataStore',
                                    viewConfig: {
                                        emptyText: 'データがありません',
                                        listeners: {
                                            beforedrop: {
                                                fn: me.onGriddragdroppluginBeforeDropA,
                                                scope: me
                                            }
                                        }
                                    },
                                    listeners:
                                            {
                                                beforerender: function ()
                                                {
                                                    Ext.getStore('ArchivedFolderDataStore').load();
                                                }
                                            },
                                    selModel: Ext.create('Ext.selection.CheckboxModel', {checkOnly: false,
                                        mode: 'SINGLE',
                                        allowDeselect: true

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
                                            renderer:function (value, metaData, record, rowIndex, colIndex, store, view) {
                                                /*var thumbnail = '';
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
                                                return '<img src="' + thumbnail + '" style="max-width:25px;max-height: 25px"/>';*/
                                                return '<img src="file_type_icon/FolderDocument.png" style="max-width:25px;max-height: 25px"/>';
                                            },
                                            padding: 0,
                                            width: 35,
                                            //dataIndex: 'type',
                                            text: 'TP'
                                        },
                                        {
                                            xtype: 'gridcolumn',
                                            minWidth: 150,
                                            width: 150,
                                            dataIndex: 'node_name',
                                            text: '名前',
                                            flex: 1
                                        },
                                        {
                                            xtype: 'datecolumn',
                                            /*renderer: function (value, metaData, record, rowIndex, colIndex, store, view) {
                                                if (typeof value === "string") {
                                                    value = parseInt(value);
                                                }
                                                var dtDate = new Date(value * 1000);
                                                return Ext.util.Format.date(dtDate, 'Y-M-d H:i:s');
                                            },*/
                                            width: 140,
                                            dataIndex: 'created_at',
                                            format: 'Y-m-d H:i:s',
                                            text: '作成日'
                                        },
                                        {
                                            xtype: 'datecolumn',
                                            /*renderer: function (value, metaData, record, rowIndex, colIndex, store, view) {
                                                if (typeof value === "string") {
                                                    value = parseInt(value);
                                                }
                                                var dtDate = new Date(value * 1000);
                                                return Ext.util.Format.date(dtDate, 'Y-M-d H:i:s');
                                            },*/
                                            width: 140,
                                            dataIndex: 'updated_at',
                                            format: 'Y-m-d H:i:s',
                                            text: '更新日'
                                        }
                                    ],
                                    dockedItems: [
                                        {
                                            xtype: 'pagingtoolbar',
                                            dock: 'bottom',
                                            autoRender: true,
                                            id: 'archivedFolder_list',
                                            displayInfo: true,
                                            store: 'ArchivedFolderDataStore'
                                        }
                                    ]
                                }
                            ]
                        }
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
                                            id: 'rearchiveFolderCancelBtn',
                                            handler: function (button, event) {
                                                Ext.getCmp('resetArchiveFolderDsp').close();
                                            },
                                            margin: '2 0 0 5',
                                            width: 100,
                                            text: 'キャンセル',
                                            tooltip: '終了します。',
                                            tooltipType: 'title'
                                        },
                                        {
                                            xtype: 'button',
                                            id: 'resetArchiveFolderBtn',
                                            disabled: true,
                                            handler: function (button, event) {
                                                var grid = Ext.getCmp('rearchiveFolderList');
                                                var model = grid.getSelectionModel();
                                                var record = model.getSelection()[0];
                                                                                                
                                                this.disable();
                                                Ext.getCmp('rearchiveFolderCancelBtn').disable();

                                                var sendData = Ext.apply({session_id: this_session_id});
                                                sendData = Ext.apply({request_type: 'reset_archive_folder'}, sendData);
                                                sendData = Ext.apply({params: [ record.data.spin_node_hashkey]}, sendData);

                                                Ext.Ajax.request({
                                                    url: 'http://127.0.0.1:18880/spinagent/spin_api_request',
                                                    method: 'POST',
                                                    jsonData: sendData,
                                                    success: handleSuccess,
                                                    failure: handleFailure
                                                });

                                                function handleFailure(response) {
                                                    alert('ERROR');
                                                    Ext.getCmp('rearchiveFolderCancelBtn').enable();
                                                    Busy = false;
                                                    Ext.Msg.show({
                                                        title: 'アーカイブ解除失敗',
                                                        msg: 'サーバとの通信に失敗しました',
                                                        buttons: Ext.Msg.OK
                                                    });
                                                    return;
                                                }
                                                function handleSuccess(response) {
                                                    Ext.getCmp('rearchiveFolderCancelBtn').enable();
                                                    obj = Ext.decode(response.responseText);
                                                    var request_success = obj.success;
                                                    if (request_success === false) {
                                                        Busy = false;
                                                        var request_errors = obj.errors;
                                                        Ext.Msg.show({
                                                            title: 'アーカイブ解除失敗',
                                                            msg: request_errors,
                                                            buttons: Ext.Msg.OK
                                                        });
                                                        return;
                                                    } else {
                                                        Ext.Msg.show({
                                                            title: 'アーカイブ解除',
                                                            msg: 'フォルダのアーカイブを解除しました。',
                                                            buttons: Ext.Msg.OK,
                                                            fn: function (btn)
                                                            {
                                                                if (btn == 'ok')
                                                                {
                                                                    Ext.getStore('ArchivedFolderDataStore').load();
                                                                    //Ext.getCmp('createArchiveFolderDsp').close();
                                                                }
                                                            }
                                                        });
                                                    }
                                                }
                                            },
                                            margin: '2 0 0 5',
                                            width: 100,
                                            text: '解除',
                                            tooltip: '選択した、フォルダのアーカイブを解除します。',
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
                                    id: 'archiveFolderProgress',
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
    }
});


