/*
 * File: app/view/FileCard.js
 *
 * This file was generated by Sencha Architect version 2.2.2.
 * http://www.sencha.com/products/architect/
 *
 * This file requires use of the Sencha Touch 2.2.x library, under independent license.
 * License of Sencha Architect does not include license for Sencha Touch 2.2.x. For more
 * details see http://www.sencha.com/license or contact license@sencha.com.
 *
 * This file will be auto-generated each and everytime you save your project.
 *
 * Do NOT hand edit this file.
 */

Ext.define('BoomBoxMobile.view.FileCard', {
	extend: 'Ext.Container',
	alias: 'widget.filecard',

	config: {
		itemId: 'fileCard',
		layout: {
			type: 'fit'
		},
		items: [
			{
				xtype: 'titlebar',
				docked: 'top',
				style: 'font-size:small',
				title: 'BOOMBOX Mobile',
				items: [
					{
						xtype: 'button',
						itemId: 'parentBtn',
						style: 'font-size:x-small',
						ui: 'back',
						text: '戻る'
					},
					{
						xtype: 'button',
						itemId: 'backBtn',
						style: 'font-size:x-small',
						text: 'ワークエリア'
					},
					{
						xtype: 'button',
						align: 'right',
						docked: 'top',
						itemId: 'logoutBtn',
						style: 'font-size:x-small',
						ui: 'decline-round',
						text: 'ログアウト'
					}
				]
			},
			{
				xtype: 'list',
				itemId: 'fileList',
				itemTpl: Ext.create('Ext.XTemplate', 
					'<tpl for=".">',
					'	<table width="100%">',
					'		<tr>',
					'			<td rowspan="2" style="width:10%;margin:0;padding:0">',
					'				<div style="text-align:center">',
					'					<img src="{icon_image}" style="width: 36px" />',
					'				</div>',
					'				<div style="text-align:center">',
					'					<span style="font-size:x-small">{file_type}</span>',
					'				</div>',
					'			</td>',
					'			<td  rowspan="2" style="width:40%;font-size:x-small">{file_name:ellipsis(16,true)}</td>',
					'			<td style="width:15%;font-size:x-small">',
					'				<tpl if="file_type !== \'folder\'">',
					'					ver: {file_version}',
					'				</tpl>',
					'			</td>',
					'			<td style="width:35%;font-size:x-small">更新:<br/>{updated_at:date("Y-m-d H:i:s")}</td>',
					'		</tr>',
					'		<tr>',
					'			<!--<td style="width:40%;font-size:x-small">{title:ellipsis(16,true)}</td>-->',
					'			<td style="width:15%;font-size:x-small">{[this.formSize(values.file_size)]}</td>	',
					'			<td style="width:35%;font-size:x-small">{modifier}</td>',
					'		</tr>',
					'	</table>',
					'</tpl>',
					'',
					{
						formSize: function(value) {
							var size      = value;
							var rounded_size;

							if (size === "" || size === 0 || size === null) {
								rounded_size = "";
							} else if (size < 1024) {
								rounded_size = size + " B";
							} else if (size < 1048576) {
								rounded_size = (Math.round(size / 1024)) + " KB";
							} else if (size < 1073741824) {
								rounded_size = (Math.round(((size*10) / 1048576))/10) + " MB";
							} else if (size < 1099511627776) {
								rounded_size = (Math.round(((size*100) / 1073741824))/100) + " GB";
							} else if (size < 1125899906842624) {
								rounded_size = (Math.round(((size*100) / 1099511627776))/100) + " TB";
							} else {
								rounded_size = (Math.round(((size*100) / 1125899906842624))/100) + " PB";
							}

							return rounded_size;
						}
					}
				),
				store: 'FileStore',
				striped: true,
				plugins: [
					{
						autoPaging: true,
						loadMoreText: 'もっとデータを読み込みます...',
						noMoreRecordsText: 'これ以上のデータはありません',
						type: 'listpaging'
					}
				]
			},
			{
				xtype: 'toolbar',
				docked: 'bottom',
				items: [
					{
						xtype: 'label',
						docked: 'right',
						html: '(c) 2018 MAKEWAVE JAPAN Co.,Ltd.All rights reserved.',
						margin: 10,
						style: 'font-size:xx-small'
					}
				]
			}
		],
		listeners: [
			{
				fn: 'onMybutton5Tap1',
				event: 'tap',
				delegate: '#parentBtn'
			},
			{
				fn: 'onMybutton5Tap',
				event: 'tap',
				delegate: '#backBtn'
			},
			{
				fn: 'onMybutton2Tap',
				event: 'tap',
				delegate: '#logoutBtn'
			},
			{
				fn: 'onFileListItemSingletap',
				event: 'itemsingletap',
				delegate: '#fileList'
			}
		]
	},

	onMybutton5Tap1: function(button, e, eOpts) {
		var thisData = Ext.apply({session_id: SessionId}, {parent_hash_key: CurrentNode[FolderNode]});
		var sendingData = Ext.apply({request_type: "back_to_parent_m"}, thisData);

		//送信処理
		Ext.Ajax.request({
			//change here
			url: 'tdx/updatedata.tdx',
			jsonData: sendingData,
			success: handleSuccess,
			failure: handleFailure
		});

		// Ajax通信成功時の処理
		function handleSuccess(response) {
			var obj = Ext.decode(response.responseText);
			var request_success = obj.success;
			var request_message = obj.message;

			if (request_success === true) {
				//Ext.getStore('FileStore').load();
				var parentStore = Ext.getStore('FileStore');
				parentStore.loadPage(1);
				FolderNode = FolderNode - 1;
				var ptBtn = Ext.ComponentQuery.query('#parentBtn')[0];
				if (FolderNode === 0) {
					ptBtn.hide();
				} else {
					ptBtn.show();
				}
			} else {
				Ext.Msg.alert(
				'親フォルダを選択できませんでした',
				request_message,
				Ext.emptyFn
				);
				return;
			}
		}

		// Ajax通信失敗時の処理
		function handleFailure(response) {
			Ext.Msg.show({
				title:'Network ERROR',
				msg: 'Error Message',
				buttons: Ext.Msg.OK
			});
			return;
		}

	},

	onMybutton5Tap: function(button, e, eOpts) {
		targetCard = Ext.ComponentQuery.query('#viewport')[0];
		targetCard.setActiveItem(1).show();

	},

	onMybutton2Tap: function(button, e, eOpts) {
		targetCard = Ext.ComponentQuery.query('#viewport')[0];
		targetCard.setActiveItem(0).show();

	},

	onFileListItemSingletap: function(dataview, index, target, record, e, eOpts) {
		CurrentParent = record.data.hash_key;

		if (record.data.file_type === "folder") {
			var thisData = Ext.apply({session_id: SessionId}, {folder: record.data});
			var sendingData = Ext.apply({request_type: "open_folder_m"}, thisData);

			//送信処理
			Ext.Ajax.request({
				//change here
				url: 'tdx/updatedata.tdx',
				jsonData: sendingData,
				success: handleSuccess,
				failure: handleFailure
			});

		} else {
			//targetCardの表示
			targetCard = Ext.ComponentQuery.query('#viewport')[0];
			targetCard.setActiveItem(3).show();
		}


		// Ajax通信成功時の処理
		function handleSuccess(response) {
			var obj = Ext.decode(response.responseText);
			var request_success = obj.success;
			var request_message = obj.message;

			if (request_success === true) {
				Ext.getStore('FileStore').loadPage(1);
				FolderNode = FolderNode + 1;
				CurrentNode[FolderNode] = CurrentParent;
				var ptBtn = Ext.ComponentQuery.query('#parentBtn')[0];
				if (FolderNode === 0) {
					ptBtn.hide();
				} else {
					ptBtn.show();
				}
			} else {
				Ext.Msg.alert(
				'フォルダを選択できませんでした',
				request_message,
				Ext.emptyFn
				);
				return;
			}
		}

		// Ajax通信失敗時の処理
		function handleFailure(response) {
			Ext.Msg.show({
				title:'Network ERROR',
				msg: 'Error Message',
				buttons: Ext.Msg.OK
			});
			return;
		}

	}

});