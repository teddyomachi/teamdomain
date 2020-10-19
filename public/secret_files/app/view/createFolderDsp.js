/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

Ext.define('TeamDomain.view.createFolderDsp', {
    extend: 'Ext.window.Window',
    alias: 'widget.createFolderDsp',
    height: 200,
    hidden: false,
    id: 'createFolderDsp',
    itemId: 'createFolderDsp',
    width: 350,
    layout: {
        type: 'fit'
    },
    title: 'フォルダ作成',
    constrain: true,
    initComponent: function () {
        var me = this;

        Ext.applyIf(me, {
            items: [
                {
                    xtype: 'form',
                    frame: true,
                    id: 'createSubFolder',
                    itemId: 'createSubFolder',
                    autoScroll: true,
                    bodyPadding: 5,
                    items: [
                        {
                            xtype: 'fieldset',
                            padding: '0 10 0 10',
                            title: 'このフォルダの配下に新たにフォルダを作成',
                            items: [
                                {
                                    xtype: 'hiddenfield',
                                    anchor: '100%',
                                    fieldLabel: 'Label',
                                    name: 'original_place'
                                },
                                {
                                    xtype: 'hiddenfield',
                                    anchor: '100%',
                                    fieldLabel: 'Label',
                                    name: 'cont_location'
                                },
                                {
                                    xtype: 'hiddenfield',
                                    anchor: '100%',
                                    fieldLabel: 'Label',
                                    name: 'hash_key'
                                },
                                {
                                    xtype: 'displayfield',
                                    anchor: '100%',
                                    height: 20,
                                    name: 'text'
                                }
                            ]
                        },
                        {
                            xtype: 'fieldset',
                            padding: '0 10 0 10',
                            title: '新しいフォルダの名前を入力',
                            items: [
                                {
                                    xtype: 'textfield',
                                    anchor: '100%',
                                    id: 'new_folder',
                                    name: 'new_folder',
                                    validateOnChange: false,
                                    validateOnBlur: false,
                                    allowBlank: false,
                                    enforceMaxLength: true,
                                    maxLength: 80
                                }
                            ]
                        },
                        {
                            xtype: 'button',
                            handler: function () {
                                if (Busy === true) {
                                    return;
                                }
                                Busy = true;
                                var formX = this.up().getForm().getFieldValues();

                                if (formX.text === '') {
                                    Busy = false;
                                    Ext.Msg.show({
                                        title: 'サブフォルダ作成対象フォルダの選択',
                                        msg: 'サブフォルダを作成するフォルダを選択してください',
                                        icon: Ext.Msg.ERROR,
                                        buttons: Ext.Msg.OK
                                    });
                                    return;
                                }

                                if (formX.new_folder === '') {
                                    Busy = false;
                                    Ext.Msg.show({
                                        title: 'サブフォルダ名の入力',
                                        msg: 'サブフォルダ名を入力してください',
                                        icon: Ext.Msg.ERROR,
                                        buttons: Ext.Msg.OK
                                    });
                                    return;
                                }

                                formX = Ext.apply({session_id: this_session_id}, formX);
                                formX = Ext.apply({request_type: 'create_sub_folder'}, formX);

                                Ext.Ajax.request({
                                    url: 'tdx/updatedata.tdx',
                                    method: 'POST',
                                    jsonData: formX,
                                    success: handleSuccess,
                                    failure: handleFailure
                                });

                                function handleSuccess(response) {
                                    obj = Ext.decode(response.responseText);
                                    var request_success = obj.success;

                                    if (request_success === false) {
                                        Busy = false;
                                        var request_errors = obj.errors;
                                        Ext.Msg.show({
                                            title: 'サブフォルダの作成失敗',
                                            msg: request_errors,
                                            buttons: Ext.Msg.OK
                                        });
                                        return;
                                    } else {
                                        requestRefresh();
                                    }
                                }

                                function handleFailure(response) {
                                    Busy = false;
                                    Ext.Msg.show({
                                        title: 'サブフォルダの作成失敗',
                                        msg: 'サーバとの通信に失敗しました',
                                        buttons: Ext.Msg.OK
                                    });
                                    return;
                                }

                                function requestRefresh() {
                                    sending_cont_location = formX.cont_location;
                                    sending_hash_key = formX.hash_key;

                                    var requestRefreshData = Ext.apply({session_id: this_session_id}, {cont_location: sending_cont_location});
                                    requestRefreshData = Ext.apply(requestRefreshData, {hash_key: sending_hash_key});
                                    requestRefreshData = Ext.apply({event_type: "property_create_subfolder"}, requestRefreshData);
                                    requestRefreshData = Ext.apply({request_type: "update_folder_list"}, requestRefreshData);
                                    requestRefreshData = Ext.apply({original_place: formX.original_place}, requestRefreshData);
                                    
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

                                    if (request_success === false) {
                                        Busy = false;
                                        var request_errors = obj.errors;
                                        Ext.Msg.show({
                                            title: 'サブフォルダの作成失敗',
                                            msg: request_errors,
                                            buttons: Ext.Msg.OK
                                        });
                                        return;
                                    } else {
                                        var store = Ext.getStore('FolderDataStoreA');
                                        var nodeinterface = select_record;
                                        store.load({
                                            node: nodeinterface,
                                            url: 'spin/foldersA.sfl'
                                        });
                                        Ext.getStore('FileDataStoreA').load();
                                        Busy = false;
                                        Ext.getCmp('createFolderDsp').close();
                                    }
                                }

                                function handleFailure2(response) {
                                    Busy = false;
                                    Ext.Msg.show({
                                        title: 'サブフォルダの作成失敗',
                                        msg: 'サーバとの通信に失敗しました',
                                        buttons: Ext.Msg.OK
                                    });
                                    return;
                                }
                            },
                            id: 'btn_create_subfolder',
                            margin: '0 0 0 100',
                            width: 100,
                            text: '作成',
                            tooltip: '新しいフォルダの名前を入力してから、このボタンを押して下さい。'
                        },
                        {
                            xtype: 'button',
                            width: 100,
                            margin: '0 0 0 10',
                            text: 'キャンセル',
                            listeners: {
                                click: {
                                    fn: me.onButtonClick1
                                },
                                scope: me
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
            ]
        });

        me.callParent(arguments);

    },
    onButtonClick1: function (button, e, eOpts) {
        this.close();
    },
    onGetDataBeforerender: function (component, eOpts) {
        var activeFolders = Ext.getCmp('activeData').getForm().getFieldValues();
        component.getForm().setValues({
            text: activeFolders.activeFolderA_text,
            hash_key: activeFolders.activeFolderA_hash,
            cont_location: activeFolders.activeFolderA_cont_location,
            //original_place: "folder_tree"
            original_place: TargetComp
        });
    }

});