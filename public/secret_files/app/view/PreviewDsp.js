/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */


Ext.define('TeamDomain.view.PreviewDsp', {
	extend: 'Ext.window.Window',
	alias: 'widget.previewDsp',

	height: 600,
	hidden: false,
	id: 'previewDsp',
	itemId: 'previewDsp',
	width: 800,
        modal: true,
	layout: {
		type: 'fit'
	},
	title: 'マルチページプレビュー',
        constrain: true,
	initComponent: function() {
                //var preview_path;
		var me = this;
		Ext.applyIf(me, {
			items: [
                            {
                                xtype: 'panel',
                                frame: true,
                                id: 'previewDspShow',
                                itemId: 'previewDspShow',
                                autoScroll: true,
                                bodyPadding: 5,
                                items: [
                                        /*{
                                            html:'<iframe src='+preview_path+' width="788" height=485" scrolling="yes"></iframe>'
                                        }*/
                                ],
                                dockedItems: [
                                        {
                                                xtype: 'toolbar',
                                                dock: 'bottom',
                                                ui: 'footer',
                                                items: [
                                                        {
                                                                xtype: 'tbfill'
                                                        },
                                                        {
                                                                xtype: 'button',
                                                                width: 100,
                                                                text: 'キャンセル',
                                                                listeners: {
                                                                        click: {
                                                                                fn: me.onButtonClick,
                                                                                scope: me
                                                                        }
                                                                }
                                                        }
                                                ]
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
        
        onButtonClick: function(component, eOpts) {
            this.close();
        },
        
        onGetDataBeforerender: function(component, eOpts) {
            //try{
            var grid = Ext.getCmp('listGridPanelA');
            var model = grid.getSelectionModel();
            var record = model.getSelection()[0];

            var formX;
            formX = Ext.apply({session_id: this_session_id}, formX);
            formX = Ext.apply({request_type: 'file_preview'}, formX);
            formX = Ext.apply({original_place: 'file_list'}, formX);
            formX = Ext.apply({cont_location: record.data.cont_location}, formX);
            formX = Ext.apply({hash_key: record.data.hash_key}, formX);
            formX = Ext.apply({file_name: record.data.file_name}, formX);

            Ext.Ajax.request({
                url: 'tdx/updatedata.tdx',
                jsonData: formX,
                method: 'POST',
                success: handleSuccess,
                failure: handleFailure
            });

            function handleSuccess(response) {
                    obj = Ext.decode(response.responseText);
                    var request_success = obj.success;

                    if (request_success === false) {
                            var request_errors = obj.errors;
                            Ext.Msg.show({
                                    title: 'マルチページプレビューの作成失敗',
                                    msg: request_errors,
                                    buttons: Ext.Msg.OK
                            });
                    } else {
                            preview_path = '<iframe src="' + obj.preview_file_path + '" width="788" height="485"><script type="text/javascript">document.domain = document.domain</script></iframe>';  
                            Ext.getCmp('previewDspShow').add({html:preview_path});
                    }
                    return;
            }

            function handleFailure(response) {
                    Ext.Msg.show({
                            title: 'マルチページプレビューの作成失敗',
                            msg: 'サーバとの通信に失敗しました',
                            buttons: Ext.Msg.OK
                    });
            }   
            /*}catch(e){
                Ext.Msg.show({
                        title: 'マルチページプレビューの作成失敗',
                        msg: e,
                        buttons: Ext.Msg.OK
                });                
            }*/
        }   
 });    