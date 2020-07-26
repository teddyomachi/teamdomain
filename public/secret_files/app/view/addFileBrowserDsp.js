/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

Ext.define('TeamDomain.view.addFileBrowserDsp', {
    extend: 'Ext.window.Window',
    alias: 'widget.addFileBrowser',
    height: 200,
    hidden: false,
    id: 'addFileBrowserDsp',
    itemId: 'addFileBrowserDsp',
    width: 450,
    layout: {
        type: 'fit'
    },
    title: 'ファイル追加',
    constrain: true,
    initComponent: function () {
        var me = this;

        Ext.applyIf(me, {
            items: [
                {
                    xtype: 'form',
                    frame: true,
                    id: 'createFile',
                    itemId: 'createFile',
                    autoScroll: true,
                    bodyPadding: 5,
                    items: [
                        {
                            xtype: 'fieldset',
                            padding: '0 10 0 10',
                            layout: {
                                type: 'auto'
                            },
                            title: 'このフォルダの配下にファイルを追加',
                            items: [
                                {
                                    xtype: 'hiddenfield',
                                    name: 'request_type',
                                    value: 'upload_file'
                                },
                                {
                                    xtype: 'hiddenfield',
                                    name: 'session_id'
                                },
                                {
                                    xtype: 'hiddenfield',
                                    name: 'original_place'
                                },
                                {
                                    xtype: 'hiddenfield',
                                    name: 'cont_location'
                                },
                                {
                                    xtype: 'hiddenfield',
                                    name: 'hash_key'
                                },
                                {
                                    xtype: 'checkboxfield',
                                    hidden: true,
                                    name: 'folder_readable_status',
                                    value: false,
                                    inputValue: 'true',
                                    uncheckedValue: 'false'
                                },
                                {
                                    xtype: 'checkboxfield',
                                    hidden: true,
                                    name: 'folder_writable_status',
                                    value: false,
                                    inputValue: 'true',
                                    uncheckedValue: 'false'
                                },
                                {
                                    xtype: 'displayfield',
                                    height: 20,
                                    width: 303,
                                    name: 'text'
                                }
                            ]
                        },
                        {
                            xtype: 'fieldset',
                            padding: '0 10 0 10',
                            title: 'ファイルを選択',
                            items: [
                                {
                                    xtype: 'filefield',
                                    anchor: '100%',
                                    id: 'uploadFile',
                                    itemId: 'uploadFile',
                                    name: 'upload_file',
                                    validateOnChange: false,
                                    validateOnBlur: false,
                                    allowBlank: false,
                                    buttonText: 'ファイル選択'
                                            /*
                                             listeners: {
                                             change: {
                                             fn: me.onUploadFileChange,
                                             scope: me
                                             }
                                             }
                                             */
                                },
                                {
                                    xtype: 'hiddenfield',
                                    fieldLabel: 'Label',
                                    name: 'another_name'
                                }
                            ]
                        },
                        {
                            xtype: 'button',
                            handler: function (button, event) {
                                if (Busy === true) {
                                    return;
                                }
                                Busy = true;

                                var formX = this.up().getForm().getFieldValues();

                                if (formX.text === '') {
                                    Busy = false;
                                    Ext.Msg.show({
                                        title: 'フォルダ選択',
                                        msg: 'フォルダの選択を確認してください',
                                        icon: Ext.Msg.ERROR,
                                        buttons: Ext.Msg.OK
                                    });
                                    return;
                                }

                                var formY = this.up('form').getForm();

                                var up_filename = formY._fields.items[8].value;

                                if (Ext.isEmpty(up_filename)) {
                                    Busy = false;
                                    Ext.Msg.show({
                                        title: '追加ファイル選択',
                                        msg: '追加ファイルを選択してください',
                                        icon: Ext.Msg.ERROR,
                                        buttons: Ext.Msg.OK
                                    });
                                    return;
                                } else {
                                    up_filename = up_filename.replace('C:\\fakepath\\', '');
                                    if (up_filename.length > 80) {
                                        Busy = false;
                                        Ext.Msg.show({
                                            title: 'ファイル名長オーバー',
                                            msg: 'ファイル名は80文字までです。短くしてください',
                                            icon: Ext.Msg.ERROR,
                                            buttons: Ext.Msg.OK
                                        });
                                        return;
                                    }

                                    var dataY = Ext.apply({session_id: this_session_id}, formX);
                                    dataY = Ext.apply({upload_filename: up_filename}, dataY);
                                    dataY = Ext.apply({request_type: "upload_file"}, dataY);

                                    Ext.Ajax.request({
                                        url: 'tdx/updatedata.tdx',
                                        jsonData: dataY,
                                        success: handleSuccess,
                                        failure: handleFailure
                                    });
                                }

                                function handleSuccess(response) {

                                    obj = Ext.decode(response.responseText);

                                    var request_success = obj.success;
                                    var request_hashkey = obj.hashkey;
                                    var request_redirect_uri = obj.redirect_uri;
                                    var new_filename = this_session_id + request_hashkey;

                                    if (request_success === false) {
                                        Busy = false;
                                        var request_errors = obj.errors;
                                        Ext.Msg.show({
                                            title: 'ファイル送信失敗',
                                            msg: 'ファイル送信失敗',
                                            icon: Ext.Msg.ERROR,
                                            buttons: Ext.Msg.OK
                                        });
                                    } else {
                                        Ext.getCmp('createFile').getForm().setValues({
                                            another_name: new_filename
                                        });
                                        sendFile(formY, up_filename, request_redirect_uri);
                                    }
                                    return;
                                }

                                function handleFailure(response) {
                                    Busy = false;
                                    Ext.Msg.show({
                                        title: 'ファイル追加失敗',
                                        msg: 'サーバとの通信に失敗しました',
                                        icon: Ext.Msg.ERROR,
                                        buttons: Ext.Msg.OK
                                    });
                                    return;
                                }

                                function sendFile(formY, up_filename, request_redirect_uri) {
                                    console.log(request_redirect_uri);
                                    //Ext.Msg.show({msg: request_redirect_uri, buttons: Ext.Msg.OK});
                                    formY.submit({
                                        url: request_redirect_uri,
                                        waitTitle: 'ファイル追加',
                                        waitMsg: 'ファイルを追加中です...',
                                        timeout: 7200000,
                                        success: function (form, action) {
//                                                               if(action.result.success === true){
                                            if (formX.folder_readable_status === false && formX.folder_writable_status === true) {
                                                Ext.Msg.show({
                                                    title: 'ファイルの追加完了',
                                                    msg: up_filename + '<br/>サーバに追加しました',
                                                    buttons: Ext.Msg.OK
                                                });
                                            }
                                            requestRefresh();
                                            formY._fields.items[8].value = '';
                                            //                                                             }
                                        },
                                        failure: function (response) {
                                            Busy = false;
                                            if (action.failureType === CONNECT_FAILURE) {
                                                Ext.Msg.alert('Error', 'Status:' + action.response.status + ': ' + action.response.statusText);
                                            } else if (action.failureType === SERVER_INVALID) {
                                                Ext.Msg.alert('Invalid', action.result.errormsg);
                                            } else {
                                                Ext.Msg.show({
                                                    title: 'ファイルの追加失敗',
                                                    msg: up_filename + '<br/>のアップロードに失敗しました',
                                                    icon: Ext.Msg.ERROR,
                                                    buttons: Ext.Msg.OK
                                                });
                                            }
                                        }

                                    });
                                }

                                function requestRefresh() {
                                    sending_session_id = formX.session_id;
                                    sending_cont_location = formX.cont_location;
                                    sending_hash_key = formX.hash_key;
                                    var requestRefreshData = Ext.apply({session_id: sending_session_id}, {cont_location: sending_cont_location});
                                    requestRefreshData = Ext.apply(requestRefreshData, {hash_key: sending_hash_key});
                                    requestRefreshData = Ext.apply({event_type: "property_upload_file"}, requestRefreshData);
                                    requestRefreshData = Ext.apply({request_type: "update_file_list"}, requestRefreshData);

                                    Ext.Ajax.request({
                                        url: 'tdx/updatedata.tdx',
                                        jsonData: requestRefreshData,
                                        success: handleSuccess2,
                                        failure: handleFailure2
                                    });
                                }

                                function handleSuccess2(response) {
                                    obj = Ext.decode(response.responseText);
                                    var request_success = obj.success;
                                    var request_status = obj.status;

                                    if (request_success === false) {
                                        Busy = false;
                                        var request_errors = obj.errors;
                                        Ext.Msg.show({
                                            title: 'ファイル送信失敗',
                                            msg: request_errors,
                                            icon: Ext.Msg.ERROR,
                                            buttons: Ext.Msg.OK
                                        });
                                    } else {
                                        Ext.getStore('FileDataStoreA').load();
                                        Busy = false;
                                        Ext.getCmp('addFileBrowserDsp').close();
                                    }
                                }

                                function handleFailure2(response) {
                                    Busy = false;
                                    Ext.Msg.show({
                                        title: 'ファイル追加失敗',
                                        msg: 'サーバとの通信に失敗しました',
                                        buttons: Ext.Msg.OK
                                    });
                                }
                            },
                            id: 'btn_upload_file',
                            margin: '0 0 0 305',
                            width: 100,
                            text: '追加',
                            tooltip: {
                                html: 'ファイルを追加するフォルダを確認してから、「ファイル選択」ボタンを押して、追加するファイルを選択して下さい。<br/>確認が済んだら、このボタンを押して下さい。'
                            }
                        }
                    ],
                    listeners: {
                        beforerender: {
                            fn: me.onGetDataBeforerender,
                            scope: me
                        }
                    }
                }
            ],
            listeners: {
                afterrender: {
                    fn: me.onReCyclerAfterRender,
                    scope: me
                }
            }
        });

        me.callParent(arguments);
    },
    onReCyclerAfterRender: function (component, eOpts) {
        Ext.getStore('RecyclerDataStore').load();
    },
    onGetDataBeforerender: function (component, eOpts) {
        var activeFolders = Ext.getCmp('activeData').getForm().getFieldValues();
        component.getForm().setValues({
                session_id: this_session_id,
                text: activeFolders.activeFolderA_text,
                hash_key: activeFolders.activeFolderA_hash,
                cont_location: activeFolders.activeFolderA_cont_location,
                folder_readable_status: activeFolders.activeFolderA_readable,
                folder_writable_status: activeFolders.activeFolderA_writable,
                original_place: activeFolders.activeFolderA_original_place
            });
        //if (TargetComp === 'folderPanelA') {
        /*console.log(activeFolders);
        if(activeFolders.activeFolderA_original_place === 'folder_tree'){
            component.getForm().setValues({
                session_id: this_session_id,
                text: activeFolders.activeFolderA_text,
                hash_key: activeFolders.activeFolderA_hash,
                cont_location: activeFolders.activeFolderA_cont_location,
                folder_readable_status: activeFolders.activeFolderA_readable,
                folder_writable_status: activeFolders.activeFolderA_writable,
                original_place: activeFolders.activeFolderA_original_place
            });
        } else {
            console.log('test2');
            var grid = Ext.getCmp(TargetComp);
            var model = grid.getSelectionModel();
            var record = model.getSelection()[0];
            component.getForm().setValues({
                session_id: this_session_id,
                text: record.data.folder_name,
                hash_key: record.data.hash_key,
                cont_location: record.data.cont_location,
                folder_readable_status: record.data.folder_readable_status,
                folder_writable_status: record.data.folder_writable_status,
                original_place: activeFolders.activeFolderA_original_place
            });
        }*/
    }
});

