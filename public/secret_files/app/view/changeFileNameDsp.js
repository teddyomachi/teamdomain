/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

Ext.define('TeamDomain.view.changeFileNameDsp', {
	extend: 'Ext.window.Window',
	alias: 'widget.changeFileNameDsp',

	height: 200,
	hidden: false,
	id: 'changeFileNameDsp',
	itemId: 'changeFileNameDsp',
	width: 350,
	layout: {
		type: 'fit'
	},
	title: 'ファイル名変更',
        constrain: true,
	initComponent: function() {
		var me = this;

		Ext.applyIf(me, {
			items: [
                            {
                                xtype: 'form',
                                frame: true,
                                id: 'changeFileName',
                                itemId: 'changeFileName',
                                autoScroll: true,
                                bodyPadding: 5,
                                items: [
                                                {
                                                        xtype: 'hiddenfield',
                                                        fieldLabel: 'Label',
                                                        name: 'cont_location'
                                                },
                                                {
                                                        xtype: 'hiddenfield',
                                                        fieldLabel: 'Label',
                                                        name: 'hash_key'
                                                },
                                                {
                                                        xtype: 'textfield',
                                                        id: 'change_file_name',
                                                        margin: 0,
                                                        width: 320,
                                                        fieldLabel: 'ファイル名',
                                                        labelWidth: 90,
                                                        name: 'file_name',
                                                        validateOnChange: false,
                                                        validateOnBlur: false,
                                                        allowBlank: false,
                                                        enforceMaxLength: true,
                                                        maxLength: 80
                                                },
                                                {
                                                        xtype: 'textfield',
                                                        hidden: true,
                                                        id: 'change_file_title',
                                                        margin: 0,
                                                        width: 320,
                                                        fieldLabel: 'タイトル',
                                                        labelWidth: 90,
                                                        name: 'title',
                                                        allowBlank: false,
                                                        emptyText: '--'
                                                },
                                                {
                                                        xtype: 'textfield',
                                                        hidden: true,
                                                        id: 'change_file_subtitle',
                                                        margin: 0,
                                                        width: 320,
                                                        fieldLabel: 'サブタイトル',
                                                        labelWidth: 90,
                                                        name: 'subtitle',
                                                        emptyText: '--'
                                                },
                                                {
                                                        xtype: 'textfield',
                                                        hidden: true,
                                                        id: 'change_file_keyword',
                                                        margin: 0,
                                                        width: 320,
                                                        fieldLabel: 'キーワード',
                                                        labelWidth: 90,
                                                        name: 'keyword',
                                                        emptyText: '--'
                                                },
                                                {
                                                        xtype: 'textareafield',
                                                        height: 32,
                                                        id: 'change_file_description',
                                                        margin: 0,
                                                        width: 320,
                                                        fieldLabel: '説明',
                                                        labelWidth: 90,
                                                        name: 'description'
                                                },
                                                {
                                                        xtype: 'button',
                                                        handler: function() {
                                                                if (Busy === true) { return; }
                                                                Busy = true;

                                                                var formX = this.up().getForm().getFieldValues();

                                                                if (formX.file_name === '') {
                                                                        Busy = false;
                                                                        Ext.Msg.show({
                                                                                title:'ファイル選択',
                                                                                msg: 'ファイルを選択してください',
                                                                                icon: Ext.Msg.ERROR,
                                                                                buttons: Ext.Msg.OK
                                                                        });
                                                                        return;
                                                                }

                                                                formX = Ext.apply({session_id: this_session_id}, formX);
                                                                formX = Ext.apply({request_type: 'change_file_property'}, formX);

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
                                                                                        title:'ファイル名等変更失敗',
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
                                                                                title:'ファイル名等変更失敗',
                                                                                msg: 'サーバとの通信に失敗しました',
                                                                                buttons: Ext.Msg.OK
                                                                        });
                                                                }

                                                                function requestRefresh() {
                                                                        sending_cont_location	= formX.cont_location;
                                                                        sending_hash_key		= formX.hash_key;

                                                                        var requestRefreshData	= Ext.apply({session_id: this_session_id}, {cont_location: sending_cont_location});
                                                                        requestRefreshData	= Ext.apply(requestRefreshData, {hash_key: sending_hash_key});
                                                                        requestRefreshData	= Ext.apply({event_type: "property_change_file_property"}, requestRefreshData);
                                                                        requestRefreshData	= Ext.apply({request_type: "update_file_list"}, requestRefreshData);

                                                                        Ext.Ajax.request({
                                                                                url: 'tdx/updatedata.tdx',
                                                                                jsonData: requestRefreshData,
                                                                                success: handleSuccess3,
                                                                                failure: handleFailure3
                                                                        });

                                                                }

                                                                function handleSuccess3(response) {
                                                                        obj = Ext.decode(response.responseText);

                                                                        var request_success = obj.success;
                                                                        var request_status  = obj.status;

                                                                        if (request_success === false) {
                                                                                Busy = false;
                                                                                var request_errors  = obj.errors;
                                                                                Ext.Msg.show({
                                                                                        title:'ファイル名等変更失敗',
                                                                                        msg: request_errors,
                                                                                        buttons: Ext.Msg.OK
                                                                                });
                                                                        } else {
                                                                                Ext.getStore('FileDataStoreA').load();
                                                                                Busy = false;
                                                                                Ext.getCmp('changeFileNameDsp').close();
                                                                        }
                                                                }

                                                                function handleFailure3(response) {
                                                                        Busy = false;
                                                                        Ext.Msg.show({
                                                                                title:'サブフォルダの作成失敗',
                                                                                msg: 'サーバとの通信に失敗しました',
                                                                                buttons: Ext.Msg.OK
                                                                        });
                                                                }

                                                        },
                                                        id: 'btn_change_file_property',
                                                        margin: '5 0 5 210',
                                                        width: 100,
                                                        text: '変更',
                                                        tooltip: {
                                                                html: 'ファイル名、キーワード、説明を上書きしてから、このボタンを押して下さい。<br/>既に同一フォルダに存在するファイルと同一名を入力した場合には、エラーとなり、変更は実行されません。'
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
        
        onGetDataBeforerender: function(component, eOpts) {
                var grid = Ext.getCmp('listGridPanelA');
                var model = grid.getSelectionModel();
                var record = model.getSelection()[0];
                component.getForm().setValues({
                        change_file_name: record.data.file_name,
                        hash_key: record.data.hash_key,
                        cont_location: record.data.cont_location,
                        change_file_description: record.data.description
                });
        }        
 });    
