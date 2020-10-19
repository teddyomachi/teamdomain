/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
Ext.define('TeamDomain.view.addLocalFileAgentDsp', {
    extend: 'Ext.window.Window',
    alias: 'widget.addLocalFileAgentDsp',
    height: 500,
    hidden: false,
    id: 'addLocalFileAgentDsp',
    itemId: 'addLocalFileAgentDsp',
    width: 400,
    layout: {
        type: 'fit'
    },
    title: 'ファイルダウンロード',
    constrain: true,
    initComponent: function () {
        var me = this;
        var timer;
        var formX;
        var download_id;
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
                        type:'fit'
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
                                    id: 'downloadAgentTree',
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
                                    name: 'addAgent_cont_location'
                                },
                                {
                                    xtype: 'hiddenfield',
                                    fieldLabel: 'Label',
                                    name: 'addAgent_hash_key'
                                },
                                {
                                    xtype: 'hiddenfield',
                                    id: 'target_folder_writable_status',
                                    fieldLabel: 'Label',
                                    name: 'addAgent_folder_writable_status'
                                }
                            ]
                        }/*,
                        {
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
                                    id: 'downFolderList',
                                    autoScroll: true,
                                    store: 'FileDataStoreA',
                                    viewConfig: {
                                        emptyText: 'データがありません',
                                        listeners: {
                                            /*beforedrop: {
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
                                                return '<img src="' + record.data.thumbnail_image + '" style="max-width:25px;max-height: 25px"/>';
                                            },
                                            padding: 0,
                                            width: 35,
                                            dataIndex: 'file_type',
                                            text: 'TP'
                                        },
                                        {
                                            xtype: 'gridcolumn',
                                            minWidth: 150,
                                            width: 150,
                                            dataIndex: 'file_name',
                                            text: '名前',
                                            flex: 1
                                        },
                                        {
                                            xtype: 'gridcolumn',
                                            width: 100,
                                            align: 'right',
                                            renderer: function (value, metaData, record, rowIndex, colIndex, store, view) {
                                                var file_size = record.data.file_size;
                                                var file_type = record.data.file_type;
                                                var fileSizeUpper = record.data.file_size_upper;
                                                var size = fileSizeUpper * Math.pow(2, 31) + file_size;
                                                if (file_type === "folder") {
                                                    return "-";
                                                } else if (size < 1024) {
                                                    return "1 KB";
                                                } else if (size < 1048576) {
                                                    return (Math.round(size / 1024)) + " KB";
                                                } else {
                                                    return (Math.round(size / 1024 / 1024)) + " MB";
                                                }
                                            },
                                            dataIndex: 'file_size',
                                            text: 'サイズ'
                                        },
                                        {
                                            xtype: 'datecolumn',
                                            renderer: function (value, metaData, record, rowIndex, colIndex, store, view) {
                                                if (typeof value === "string") {
                                                    value = parseInt(value);
                                                }
                                                var dtDate = new Date(value * 1000);
                                                return Ext.util.Format.date(dtDate, 'Y-M-d H:i:s');
                                            },
                                            width: 140,
                                            dataIndex: 'created_at',
                                            text: '作成日'
                                        },
                                        {
                                            xtype: 'datecolumn',
                                            renderer: function (value, metaData, record, rowIndex, colIndex, store, view) {
                                                if (typeof value === "string") {
                                                    value = parseInt(value);
                                                }
                                                var dtDate = new Date(value * 1000);
                                                return Ext.util.Format.date(dtDate, 'Y-M-d H:i:s');
                                            },
                                            width: 140,
                                            dataIndex: 'updated_at',
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
                                            store: 'FileDataStoreA'
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
                            layout: {
                                type: 'fit'
                            },
                            items: [
                                {
                                    xtype: 'fieldcontainer',
                                    items: [
                                        {
                                            xtype: 'button',
                                            id:'downloadAgentCancelBtn',
                                            handler: function (button, event) {
                                                Ext.getCmp('addLocalFileAgentDsp').close();
                                            },
                                            margin: '2 0 0 5',
                                            width: 100,
                                            text: 'キャンセル',
                                            tooltip: '終了します。',
                                            tooltipType: 'title'
                                        },
                                        {
                                            xtype: 'button',
                                            id: 'addAgentDownloadBtn',
                                            //disabled:true,
                                            handler: function (button, event) {
                                                //this.disable();
                                                Ext.getCmp('downloadAgentCancelBtn').disable();
                                                Ext.getCmp('downloadAgentStopBtn').enable();
                                                Ext.getCmp('downloadAgentProgress').show();
                                                Ext.getCmp('addLocalFileAgentDsp').setHeight(500);
                                                
                                                var grid = Ext.getCmp(TargetComp);
                                                var model = grid.getSelectionModel();
                                                var record = model.getSelection()[0];
                                                
                                                // ドメイン取得
                                                var domain = Ext.getCmp('domainGridPanelA');
                                                var dModel = domain.getSelectionModel();
                                                var dRecord = dModel.getSelection()[0];

                                                var vpath = record.data.virtual_path;
                                                var offset = dRecord.data.vpath.length;
                                                var send_vpath = vpath.slice(offset);
                                                
                                                //ローカルフォルダ取得
                                                var lgrid = Ext.getCmp('downloadAgentTree');
                                                var lmodel = lgrid.getSelectionModel();
                                                var lrecord = lmodel.getSelection()[0];
                                                
                                                var depth = 0;
                                                
                                                var sendData=Ext.apply({session_id: this_session_id});
                                                sendData=Ext.apply({request_type: 'download_file'}, sendData);
                                                //sendData=Ext.apply({params: ['C:' + lrecord.data.node_path]}, sendData);
                                                sendData=Ext.apply({params: 
                                                            [
                                                                dRecord.data.domain_name + ":" + send_vpath,
                                                                depth,
                                                                lrecord.data.node_path
                                                                //"$HOME"
                                                            ]}, sendData);
                                                console.log(sendData);
                                                
                                                Ext.Ajax.request({
                                                    url: 'http://127.0.0.1:18880/spinagent/spin_api_request',
                                                    method: 'POST',
                                                    jsonData: sendData,
                                                    success: handleSuccess,
                                                    failure: handleFailure
                                                });
                                                
                                                function handleFailure(response) {
                                                    alert('ERROR');
                                                    Ext.getCmp('downloadAgentCancelBtn').enable();
                                                    Busy = false;
                                                    Ext.Msg.show({
                                                        title: 'ダウンロード失敗',
                                                        msg: 'サーバとの通信に失敗しました',
                                                        buttons: Ext.Msg.OK
                                                    });
                                                    return;
                                                }
                                                function handleSuccess(response) {
                                                    Ext.getCmp('downloadAgentCancelBtn').enable();
                                                    obj = Ext.decode(response.responseText);
                                                    var request_success = obj.success;
                                                    if (request_success === false) {
                                                        Busy = false;
                                                        var request_errors = obj.errors;
                                                        Ext.Msg.show({
                                                            title: 'ダウンロード失敗',
                                                            msg: request_errors,
                                                            buttons: Ext.Msg.OK
                                                        });
                                                        return;
                                                    } else {
                                                        download_id = obj.result;
                                                        status_get();
                                                    }
                                                }
                                                
                                                function status_get() {
                                                    var param = 'session_id=' + this_session_id
                                                            + '&download_id=' + download_id;
                                                    var total_size = 0;
                                                    var download_size = 0;
                                                    var request_status;
                                                                                                        
                                                    timer = setInterval(function () {

                                                        Ext.Ajax.request({
                                                            //url: 'http://127.0.0.1:18880/spinagent/spin_api_request/upload_status',
                                                            url: 'http://127.0.0.1:18880/spin_rest/download_status?' + param,
                                                            method: 'GET',
                                                            async: false,
                                                            success: handleSuccess2,
                                                            failure: handleFailure2
                                                        });
                                                        function handleFailure2(response) {
                                                            Busy = false;
                                                            Ext.Msg.show({
                                                                title: 'ダウンロード失敗-通信エラー',
                                                                msg: 'サーバとの通信に失敗しました',
                                                                buttons: Ext.Msg.OK
                                                            });
                                                            return;
                                                        }
                                                        function handleSuccess2(response) {
                                                            obj = Ext.decode(response.responseText);
                                                            var request_success = obj.upload_status;

                                                            if (request_success < -1) {
                                                                Busy = false;
                                                                var request_errors = obj.errors;
                                                                Ext.Msg.show({
                                                                    title: 'ダウンロード失敗-サーバエラー',
                                                                    msg: request_errors,
                                                                    buttons: Ext.Msg.OK
                                                                });
                                                                clearInterval(timer);
                                                                return;
                                                            } else {
                                                                total_size = obj.size_to_download;
                                                                download_size = obj.downloaded_size;
                                                                console.log('total:' + total_size);
                                                                console.log('download:' + download_size);
                                                                if (1024 <= request_success) {
                                                                    request_status = 1;
                                                                } else {
                                                                    request_status = 0;
                                                                }
                                                                // 進捗状況の更新
                                                                Ext.getCmp('downloadAgentProgress').updateProgress(download_size / total_size, download_size + " / " + total_size + " Byte");

                                                                if (1 === request_status) {
                                                                    Ext.getCmp('downloadAgentProgress').hide();

                                                                    Ext.Msg.show({
                                                                        title: 'ダウンロード',
                                                                        msg: 'ダウンロードが完了しました。',
                                                                        icon: Ext.Msg.INFO,
                                                                        buttons: Ext.Msg.OK
                                                                    });
                                                                    clearInterval(timer);
                                                                    Ext.getCmp('downloadAgentStopBtn').disable();
                                                                    Ext.getCmp('downloadAgentCancelBtn').enable();
                                                                    Ext.getCmp('addAgentDownloadBtn').enable();
                                                                }
                                                            }
                                                        }
                                                    }, 500);
                                                }

                                                // TEST用 --
                                                /*var return_json;
                                                var jsonObj;
                                                var total_size = 100;
                                                var upload_size = 0;
                                                var request_status;

                                                var test_count = 0;
                                                timer = setInterval(function () {
                                                    upload_size = test_count;
                                                    if (total_size <= upload_size) {
                                                        request_status = 1;
                                                    } else {
                                                        request_status = 0;
                                                    }

                                                    // 進捗状況の更新
                                                    Ext.getCmp('downloadAgentProgress').updateProgress(upload_size / total_size, upload_size + " / " + total_size + " Byte");

                                                    if (1 === request_status || upload_size >= total_size) {
                                                        Ext.getCmp('downloadAgentProgress').hide();

                                                        Ext.Msg.show({
                                                            title: 'ダウンロード',
                                                            msg: 'ダウンロードが完了しました。',
                                                            icon: Ext.Msg.INFO,
                                                            buttons: Ext.Msg.OK
                                                        });
                                                        clearInterval(timer);
                                                        Ext.getCmp('downloadAgentStopBtn').disable();
                                                        Ext.getCmp('downloadAgentCancelBtn').enable();
                                                        Ext.getCmp('addAgentDownloadBtn').enable();
                                                    }
                                                    test_count += 10;
                                                }, 300);*/
                                                // TEST用 --
                                            },
                                            margin: '2 0 0 5',
                                            width: 100,
                                            text: 'ダウンロード',
                                            tooltip: '選択した、ファイル・フォルダをダウンロードします。',
                                            tooltipType: 'title'
                                        },
                                        {
                                            xtype: 'button',
                                            id: 'downloadAgentStopBtn',
                                            disabled: true,
                                            handler: function (button, event) {
                                                this.disable();
                                                Ext.getCmp('addAgentDownloadBtn').enable();
                                                Ext.getCmp('downloadAgentProgress').hide();

                                                clearInterval(timer);
                                                Ext.getCmp('downloadAgentProgress').updateProgress(0, " ");
                                                Ext.Msg.show({
                                                    title: 'ダウンロード',
                                                    msg: 'ダウンロードを中断しました。',
                                                    icon: Ext.Msg.INFO,
                                                    buttons: Ext.Msg.OK
                                                });
                                            },
                                            margin: '2 0 0 5',
                                            width: 100,
                                            text: '中断',
                                            tooltip: 'ダウンロードを中断します。',
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
                                    id: 'downloadAgentProgress',
                                    width: 450,
                                    hidden: true
                                }
                            ]
                        }
                    ]
                }
            ],
            listeners: {
                
            }
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


