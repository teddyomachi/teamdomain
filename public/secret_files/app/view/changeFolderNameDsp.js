/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

Ext.define('TeamDomain.view.changeFolderNameDsp', {
    extend: 'Ext.window.Window',
    alias: 'widget.changeFolderNameDsp',
    height: 200,
    hidden: false,
    id: 'changeFolderNameDsp',
    itemId: 'changeFolderNameDsp',
    width: 350,
    layout: {
        type: 'fit'
    },
    title: 'フォルダ名変更',
    constrain: true,
    initComponent: function () {
        var me = this;

        Ext.applyIf(me, {
            items: [
                {
                    xtype: 'form',
                    frame: true,
                    id: 'changeFolderName',
                    itemId: 'changeFolderName',
                    autoScroll: true,
                    bodyPadding: 5,
                    items: [
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
                            xtype: 'textfield',
                            id: 'show_folder_name',
                            margin: 0,
                            width: 320,
                            fieldLabel: 'フォルダ名',
                            labelWidth: 90,
                            name: 'text',
                            validateOnChange: false,
                            validateOnBlur: false,
                            allowBlank: false,
                            enforceMaxLength: true,
                            maxLength: 80
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
                                        title: 'フォルダ選択',
                                        msg: 'フォルダを選択してください',
                                        icon: Ext.Msg.ERROR,
                                        buttons: Ext.Msg.OK
                                    });
                                    return;
                                }

                                formX = Ext.apply({session_id: this_session_id}, formX);
                                formX = Ext.apply({request_type: 'change_folder_name'}, formX);

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
                                            title: 'フォルダ名変更失敗',
                                            msg: request_errors,
                                            buttons: Ext.Msg.OK
                                        });
                                    } else {
                                        requestRefresh();
                                    }
                                    return;
                                }

                                function handleFailure(response) {
                                    Busy = false;
                                    Ext.Msg.show({
                                        title: 'フォルダ名変更失敗',
                                        msg: 'サーバとの通信に失敗しました',
                                        buttons: Ext.Msg.OK
                                    });
                                }

                                //ファイルリスト再読み込み用
                                function requestRefresh() {
                                    sending_cont_location = formX.cont_location;
                                    sending_hash_key = formX.hash_key;

                                    var requestRefreshData = Ext.apply({session_id: this_session_id}, {cont_location: sending_cont_location});
                                    requestRefreshData = Ext.apply(requestRefreshData, {hash_key: sending_hash_key});
                                    requestRefreshData = Ext.apply({event_type: "property_change_folder_name"}, requestRefreshData);
                                    requestRefreshData = Ext.apply({request_type: "update_folder_list"}, requestRefreshData);

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
                                            title: 'フォルダ名変更失敗',
                                            msg: request_errors,
                                            buttons: Ext.Msg.OK
                                        });
                                    } else {
                                        Ext.getStore('FolderDataStoreA').load();
                                        Ext.getStore('FileDataStoreA').load();
                                        Busy = false;
                                        Ext.getCmp('changeFolderNameDsp').close();
                                    }
                                }

                                function handleFailure2(response) {
                                    Busy = false;
                                    Ext.Msg.show({
                                        title: 'フォルダ名変更失敗',
                                        msg: 'サーバとの通信に失敗しました',
                                        buttons: Ext.Msg.OK
                                    });
                                }
                            },
                            id: 'btn_change_folder_name',
                            margin: '5 0 5 210',
                            width: 100,
                            text: 'フォルダ名変更',
                            tooltip: {
                                html: 'フォルダ名を変更する場合には、現在のフォルダ名を上書きしてから、このボタンを押して下さい。'
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
    onGetDataBeforerender: function (component, eOpts) {
        if (TargetComp === 'listGridPanelA') {
            var grid = Ext.getCmp('listGridPanelA');
            var model = grid.getSelectionModel();
            var record = model.getSelection()[0];
            component.getForm().setValues({
                text: record.data.folder_name,
                hash_key: record.data.hash_key,
                cont_location: record.data.cont_location
            });
        } else {
            var activeFolders = Ext.getCmp('activeData').getForm().getFieldValues();
            component.getForm().setValues({
                text: activeFolders.activeFolderA_text,
                hash_key: activeFolders.activeFolderA_hash,
                cont_location: activeFolders.activeFolderA_cont_location
            });
        }
    }
});

