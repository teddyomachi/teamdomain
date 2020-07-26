/*
 * File: app/view/DomainProperty.js
 *
 * This file was generated by Sencha Architect version 2.2.2.
 * http://www.sencha.com/products/architect/
 *
 * This file requires use of the Ext JS 4.0.x library, under independent license.
 * License of Sencha Architect does not include license for Ext JS 4.0.x. For more
 * details see http://www.sencha.com/license or contact license@sencha.com.
 *
 * This file will be auto-generated each and everytime you save your project.
 *
 * Do NOT hand edit this file.
 */

Ext.define('TeamDomain.view.DomainPropertyDsp', {
    extend: 'Ext.window.Window',
    alias: 'widget.domainpropertydsp',
    height: 300,
    hidden: false,
    id: 'domainPropertydsp',
    itemId: 'domainPropertydsp',
    width: 400,
    layout: {
        align: 'stretch',
        type: 'vbox'
    },
    title: 'エイリアス名称変更',
    initComponent: function () {
        var me = this;

        Ext.applyIf(me, {
            items: [
                {
                    xtype: 'panel',
                    height: 138,
                    hidden: false,
                    itemId: 'showDomainThumbnailDsp',
                    padding: '',
                    tpl: [
                        '<img src="data/{img}" height="128px" style="float: center" />',
                        ''
                    ],
                    bodyPadding: 5
                },
                {
                    xtype: 'tabpanel',
                    flex: 1,
                    hidden: false,
                    activeTab: 0,
                    items: [
                        {
                            xtype: 'form',
                            frame: true,
                            height: 100,
                            hidden: true,
                            id: 'showDomainPropertyDsp',
                            autoScroll: true,
                            bodyPadding: 5,
                            title: 'プロパティ',
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
                                    margin: 0,
                                    width: 320,
                                    fieldLabel: 'エイリアス名',
                                    labelWidth: 90,
                                    name: 'domain_name',
                                    allowBlank: false,
                                    emptyText: 'エイリアスを選択して下さい。'
                                },
                                {
                                    xtype: 'button',
                                    handler: function () {
                                        var formX = this.up().getForm().getFieldValues();

                                        if (formX.domain_name === '') {
                                            Ext.Msg.show({
                                                title: 'エイリアス選択',
                                                msg: 'エイリアスを選択してください',
                                                icon: Ext.Msg.ERROR,
                                                buttons: Ext.Msg.OK
                                            });
                                            return;
                                        }

                                        formX = Ext.apply({session_id: this_session_id}, formX);
                                        formX = Ext.apply({request_type: 'change_domain_name'}, formX);

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
                                                var request_errors = obj.errors;
                                                Ext.Msg.show({
                                                    title: 'エイリアス名変更失敗',
                                                    msg: request_errors,
                                                    buttons: Ext.Msg.OK
                                                });
                                            } else {
                                                Ext.getStore('DomainDataStoreA').load();
                                                Ext.getCmp('domainPropertydsp').close();
                                            }
                                            return;
                                        }

                                        function handleFailure(response) {
                                            Ext.Msg.show({
                                                title: 'エイリアス名変更失敗',
                                                msg: 'サーバとの通信に失敗しました',
                                                buttons: Ext.Msg.OK
                                            });
                                        }
                                    },
                                    id: 'btn_change_domain_name',
                                    itemId: '',
                                    margin: '5 0 5 210',
                                    width: 100,
                                    text: 'エイリアス名変更',
                                    tooltip: {
                                        html: 'エイリアス名を変更する場合には、現在のエイリアス名を上書きしてから、このボタンを押して下さい。'
                                    }
                                },
                                {
                                    xtype: 'displayfield',
                                    margin: 0,
                                    width: 320,
                                    fieldLabel: 'リンク先',
                                    labelWidth: 90,
                                    name: 'domain_link'
                                }
                            ],
                            listeners: {
                                afterrender: {
                                    fn: me.onDomainPropertyDispAfterRender,
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
    onDomainPropertyDispAfterRender: function (component, eOpts) {
        var grid = Ext.getCmp('domainGridPanelA');
        var model = grid.getSelectionModel();
        if (!model.hasSelection()) {
        } else {
            var record = model.getSelection()[0];
            component.getForm().setValues({
                hash_key: record.data.hash_key,
                cont_location: record.data.cont_location,
                domain_name: record.data.domain_name,
                domain_link: record.data.domain_link
            });
        }
    }

});