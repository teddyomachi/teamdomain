/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
Ext.define('TeamDomain.view.addFileAgentDsp', {
    extend: 'Ext.window.Window',
    alias: 'widget.addFileAgentDsp',
    height: 500,
    hidden: false,
    id: 'addFileAgentDsp',
    itemId: 'addFileAgentDsp',
    width: 800,
    layout: {
        type: 'fit'
    },
    title: 'ファイル追加',
    constrain: true,
    initComponent: function () {
        var me = this;
        var timer;
        var formX; 
       var upload_id;
        formX = Ext.apply({session_id: this_session_id}, formX);
        formX = Ext.apply({request_type: 'get_node_list'}, formX);
        formX = Ext.apply({params: ['$HOME', 1, false]}, formX);
        Ext.applyIf(me, {
            items: [
                {
                    xtype: 'panel',
                    layout: {
                        align: 'stretch',
                        type: 'hbox'
                    },
                    items: [
                        {
                            xtype: 'panel',
                            width: 285,
                            layout: {
                                type: 'fit'
                            },
                            items: [
                                {
                                    xtype: 'treepanel',
                                    flex: 1,
                                    id: 'addAgentTree',
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
                        },
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
                                    id: 'addAgentList',
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
                                            renderer: function (value, metaData, record, rowIndex, colIndex, store, view) {
                                                var file_size = record.data.size;
                                                var file_type = record.data.node_type;

                                                if (file_type === "1") {
                                                    return "-";
                                                } else if (file_size < 1024) {
                                                    return "1 KB";
                                                } else if (file_size < 1048576) {
                                                    return (Math.round(file_size / 1024)) + " KB";
                                                } else {
                                                    return (Math.round(file_size / 1024 / 1024)) + " MB";
                                                }
                                            },
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
                                    ]/*,
                                    dockedItems: [
                                        {
                                            xtype: 'pagingtoolbar',
                                            dock: 'bottom',
                                            autoRender: true,
                                            id: 'addList_list',
                                            displayInfo: true,
                                            store: 'LocalFileDataStore'
                                        }
                                    ]*/
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
                                            id: 'addAgentCancelBtn',
                                            handler: function (button, event) {
                                                Ext.getCmp('addFileAgentDsp').close();
                                            },
                                            margin: '2 0 0 5',
                                            width: 100,
                                            text: 'キャンセル',
                                            tooltip: '終了します。',
                                            tooltipType: 'title'
                                        },
                                        {
                                            xtype: 'button',
                                            id: 'addAgentUploadBtn',
                                            handler: function (button, event) {

                                                var grid = Ext.getCmp('addAgentList');
                                                var model = grid.getSelectionModel();
                                                if (!model.hasSelection()) {
                                                    Ext.Msg.show({
                                                        title: 'アップロード対象選択',
                                                        msg: 'アップロードする対象を選択してください',
                                                        icon: Ext.Msg.ERROR,
                                                        buttons: Ext.Msg.OK
                                                    });
                                                    return;
                                                }

                                                this.disable();
                                                Ext.getCmp('addAgentCancelBtn').disable();
                                                Ext.getCmp('addAgentStopBtn').enable();
                                                Ext.getCmp('addAgentProgress').show();

                                                // ドメイン取得
                                                var domain = Ext.getCmp('domainGridPanelA');
                                                var dModel = domain.getSelectionModel();
                                                var dRecord = dModel.getSelection()[0];

                                                var upLoadDataList = [];
                                                var selCnt = model.getCount();
                                                var records = model.getSelection();
                                                for (var i = 0; i < selCnt; i++) {
                                                    var record = records[i];
                                                    var uploadData = Ext.apply({session_id: this_session_id});
                                                    uploadData = Ext.apply({request_type: 'upload_file'}, uploadData);
                                                    //uploadData = Ext.apply({params: ['C:' + record.data.node_path, 0, dRecord.data.domain_name + ":" + currentVirtualPath]}, uploadData);
                                                    uploadData = Ext.apply({params: [record.data.node_path, 0, currentVirtualPath]}, uploadData);
                                                    //uploadData = Ext.apply({params: ['C:' + record.data.node_path, 0, 'kozaki1/TEST3']}, uploadData);
                                                    upLoadDataList.push(uploadData);
                                                }

                                                //console.log(upLoadDataList);
                                                // 選択行取得 (１レコードのみ対応 2015/8/28 時点)
//                                                        var record = model.getSelection()[0];

//                                                        // ドメイン取得
//                                                        var domain = Ext.getCmp('domainGridPanelA');
//                                                        var dModel = domain.getSelectionModel();
//                                                        var dRecord = dModel.getSelection()[0];

//                                                        var uploadData = Ext.apply({session_id: this_session_id}, uploadData);
//                                                        uploadData = Ext.apply({request_type: 'upload_file'}, uploadData);
//                                                        uploadData = Ext.apply({params: ['C:' + record.data.node_path, 0, dRecord.data.domain_name + ":" + currentVirtualPath]}, uploadData);
//                                                        uploadData = Ext.apply({params: ['C:' + record.data.node_path, 0, currentVirtualPath]}, uploadData);

                                                Ext.Ajax.request({
                                                    url: 'http://127.0.0.1:18880/spinagent/spin_api_request',
                                                    method: 'POST',
                                                    jsonData: upLoadDataList,
                                                    success: handleSuccess,
                                                    failure: handleFailure
                                                });

                                                function handleFailure(response) {
                                                    alert('ERROR');
                                                    Ext.getCmp('addAgentCancelBtn').enable();
                                                    Busy = false;
                                                    Ext.Msg.show({
                                                        title: 'アップロード失敗',
                                                        msg: 'サーバとの通信に失敗しました',
                                                        buttons: Ext.Msg.OK
                                                    });
                                                    return;
                                                }
                                                function handleSuccess(response) {
                                                    Ext.getCmp('addAgentCancelBtn').enable();
                                                    obj = Ext.decode(response.responseText);
                                                    var request_success = obj.success;
                                                    if (request_success === false) {
                                                        Busy = false;
                                                        var request_errors = obj.errors;
                                                        Ext.Msg.show({
                                                            title: 'アップロード失敗',
                                                            msg: request_errors,
                                                            buttons: Ext.Msg.OK
                                                        });
                                                        return;
                                                    } else {
                                                        upload_id = obj.result;
                                                        status_get();
                                                    }
                                                }
                                                function status_get() {

                                                    var param = 'session_id=' + this_session_id
                                                            + '&upload_id=' + upload_id;
                                                    var total_size = 0;
                                                    var upload_size = 0;
                                                    var request_status;

                                                    timer = setInterval(function () {

                                                        Ext.Ajax.request({
                                                            //urlを変更2016/1/26
                                                            //url: 'http://127.0.0.1:18880/spinagent/spin_api_request/upload_status',
                                                            url: 'http://127.0.0.1:18880/spin_rest/upload_status?'+param,
                                                            method: 'GET',
                                                            async: false,
                                                            success: handleSuccess2,
                                                            failure: handleFailure2
                                                        });
                                                        function handleFailure2(response) {
                                                            Busy = false;
                                                            Ext.Msg.show({
                                                                title: 'アップロード失敗-通信エラー',
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
                                                                    title: 'アップロード失敗-サーバエラー',
                                                                    msg: request_errors,
                                                                    buttons: Ext.Msg.OK
                                                                });
                                                                clearInterval(timer);
                                                                Ext.getCmp('addAgentStopBtn').disable();
                                                                Ext.getCmp('addAgentUploadBtn').enable();
                                                                Ext.getCmp('addAgentProgress').updateProgress(0, " ");
                                                                var store = Ext.getStore('FolderDataStoreA');
                                                                var nodeinterface = select_record;
                                                                Ext.apply(store.proxy.extraParams,
                                                                        {
                                                                            Rebuilding_flag: 1
                                                                        });
                                                                store.load({
                                                                    node: nodeinterface,
                                                                    url: 'spin/foldersA.sfl',
                                                                    callback: function (rec, opt, success)
                                                                    {
                                                                        Ext.getStore("FileDataStoreA").load();
                                                                        Ext.apply(store.proxy.extraParams,
                                                                        {
                                                                            Rebuilding_flag: 0
                                                                        });
                                                                    }
                                                                });
                                                                return;
                                                            } else {
                                                                total_size = obj.size_to_upload;
                                                                upload_size = obj.uploaded_size;
                                                                console.log('total:' + total_size);
                                                                console.log('upload:' + upload_size);
                                                                if (1024 <= request_success) {
                                                                    request_status = 1;
                                                                } else {
                                                                    request_status = 0;
                                                                }
                                                                // 進捗状況の更新
                                                                Ext.getCmp('addAgentProgress').updateProgress(upload_size / total_size, upload_size + " / " + total_size + " Byte");

                                                                if (1 === request_status) {
                                                                    //Ext.getCmp('addAgentProgress').hide();

                                                                    Ext.Msg.show({
                                                                        title: 'アップロードロード',
                                                                        msg: 'アップロードが完了しました。',
                                                                        icon: Ext.Msg.INFO,
                                                                        buttons: Ext.Msg.OK
                                                                    });
                                                                    clearInterval(timer);
                                                                    Ext.getCmp('addAgentStopBtn').disable();
                                                                    Ext.getCmp('addAgentUploadBtn').enable();
                                                                    Ext.getCmp('addAgentProgress').updateProgress(0, " ");
                                                                    
                                                                    var selected = Ext.getCmp("folderPanelA").getSelectionModel().selected.items[0].data;
                                                                    var dataF = Ext.apply({session_id: this_session_id}, selected);
                                                                    dataF = Ext.apply({request_type: "change_folder"}, dataF);

                                                                    Ext.Ajax.request({
                                                                        url: 'tdx/updatedata.tdx',
                                                                        //url: 'php/request.php',
                                                                        jsonData: dataF,
                                                                        success: after_success_load,
                                                                        failure: after_success_load_failure
                                                                    });

                                                                    function after_success_load()
                                                                    {
                                                                        var store = Ext.getStore('FolderDataStoreA');
                                                                        var nodeinterface = select_record;
                                                                        Ext.apply(store.proxy.extraParams,
                                                                        {
                                                                            Rebuilding_flag: 1
                                                                        });
                                                                        store.load(
                                                                        {
                                                                            node: nodeinterface,
                                                                            url: 'spin/foldersA.sfl',
                                                                            callback: function(rec, opt, success)
                                                                            {
                                                                                Ext.getStore("FileDataStoreA").load();
                                                                                Ext.apply(store.proxy.extraParams,
                                                                                {
                                                                                    Rebuilding_flag: 0
                                                                                });
                                                                            }
                                                                        });
                                                                    }
                                                                    
                                                                    function after_success_load_failure()
                                                                    {
                                                                        Ext.Msg.show({
                                                                        title: 'ロード失敗',
                                                                        msg: 'フォルダのロードが失敗しました。',
                                                                        icon: Ext.Msg.INFO,
                                                                        buttons: Ext.Msg.OK
                                                                    });
                                                                    }
                                                                }

                                                            }
                                                        }

                                                    }, 2000);

                                                }

                                            },
                                            margin: '2 0 0 5',
                                            width: 100,
                                            text: 'アップロード',
                                            tooltip: '選択した、ファイル・フォルダをアップロードします。',
                                            tooltipType: 'title'
                                        },
                                        {
                                            xtype: 'button',
                                            id: 'addAgentStopBtn',
                                            disabled: true,
                                            handler: function (button, event) {

                                                var sendData = Ext.apply({session_id: this_session_id});
                                                sendData = Ext.apply({request_type: 'cancel_upload'}, sendData);
                                                sendData = Ext.apply({params: [ upload_id]}, sendData);

                                                Ext.Ajax.request({
                                                    url: 'http://127.0.0.1:18880/spinagent/spin_api_request',
                                                    method: 'POST',
                                                    jsonData: sendData,
                                                    success: handleSuccess3,
                                                    failure: handleFailure3
                                                });

                                                function handleFailure3(response) {
                                                    Busy = false;
                                                    Ext.getCmp('addAgentStopBtn').disable();
                                                    Ext.Msg.show({
                                                        title: 'アップロード中断失敗',
                                                        msg: 'サーバとの通信に失敗しました',
                                                        buttons: Ext.Msg.OK
                                                    });
                                                    return;
                                                }
                                                function handleSuccess3(response) {
                                                    obj = Ext.decode(response.responseText);
                                                    Ext.getCmp('addAgentStopBtn').disable();
                                                    Ext.getCmp('addAgentUploadBtn').enable();
                                                    //Ext.getCmp('addAgentProgress').hide();

                                                    clearInterval(timer);
                                                    Ext.getCmp('addAgentProgress').updateProgress(0, " ");
                                                    Ext.Msg.show({
                                                        title: 'アップロード',
                                                        msg: 'アップロードを中断しました。',
                                                        icon: Ext.Msg.INFO,
                                                        buttons: Ext.Msg.OK
                                                    });
                                                }

                                            },
                                            margin: '2 0 0 5',
                                            width: 100,
                                            text: '中断',
                                            tooltip: 'アップロードを中断します。',
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
                                    id: 'addAgentProgress',
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
