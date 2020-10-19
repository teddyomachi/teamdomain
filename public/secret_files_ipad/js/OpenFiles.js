/*
This file is not a part of Ext JS
Authored by (c) 2012 WoodvilleJapan
This should be used to open files whenever any files are selected in TeamDomain.
*/

Ext.define('Ext.TeamDomain.OpenFiles', {
	statics: {

		doFile: function(dataX, readableRight, writableRight, editableStatus, openStatus, showFileName, fileType, readChecked, writeChecked, contLocation) {

			var actionStatus= "" ;
				if (writeChecked === true) {

					if (fileType === 'folder') {
						if (readableRight === true) {
							actionStatus = 'open_folder';
						} else {
							return;
						}
					} else {
						if (readableRight !== true) {
							actionStatus = false;
							Ext.Msg.show({
								title:'ファイルを開く',
								msg: '"'+dataX.file_name+'" を開く権限がありません。',
								icon: Ext.Msg.ERROR,
								buttons: Ext.Msg.OK
							});
						} else {
							if (writableRight !== true) {
								if (editableStatus === 0) {
									actionStatus = 'lock_open';
								} else if (editableStatus === 1) {
									if (openStatus === false) {
										actionStatus = 'ref_open';
									} else {
										actionStatus = false;
										Ext.Msg.show({
											title:'ファイルを開く',
											msg: '"'+dataX.file_name+'" は既に開いています。',
											icon: Ext.Msg.ERROR,
											buttons: Ext.Msg.OK
										});	
									}
								}　else if (editableStatus === 2) {
									actionStatus = 'ref_open';
								}　else if (editableStatus === 4) {
									actionStatus = 'ref_open';
								}　else if (editableStatus === 8) {
									actionStatus = false;
									Ext.Msg.show({
										title:'ファイルを開く',
										msg: '"'+dataX.file_name+'" はエクスクルーシブ・チェックアウトされているので、開けません。',
										icon: Ext.Msg.WARNING,
										buttons: Ext.Msg.OK
									});
								}　else {
									return;
								}
							} else {
								if (editableStatus === 0) {
									actionStatus = 'lock_open';
								}　else if (editableStatus === 1) {
									if (openStatus === false) {
										actionStatus = 'just_open';
									} else {
										actionStatus = false;
									}
								}　else if (editableStatus === 2) {
									actionStatus = 'ref_open';
								}　else if (editableStatus === 4) {
									actionStatus = 'ref_open';
								}　else if (editableStatus === 8) {
									actionStatus = false;
									Ext.Msg.show({
										title:'ファイルを開く',
										msg: '"'+dataX.file_name+'" はエクスクルーシブ・チェックアウトされているので、開けません。',
										icon: Ext.Msg.WARNING,
										buttons: Ext.Msg.OK
									});
								}　else {
									return;
								}
							}
						}
					}
				} else {
					if (fileType === 'folder') {
						if (readableRight === true) {
							actionStatus = 'open_folder';
						} else {
							return;
						}
					} else {
						if (readableRight !== true) {
							actionStatus = false;
							Ext.Msg.show({
								title:'ファイルを開く',
								msg: '"'+dataX.file_name+'" を開く権限がありません。',
								icon: Ext.Msg.ERROR,
								buttons: Ext.Msg.OK
							});
						} else {
							if (writableRight !== true) {
								if (editableStatus === 0) {
									actionStatus = 'ref_open';
								} else if (editableStatus === 1) {
									if (openStatus === false) {
										actionStatus = 'ref_open';
									} else {
										actionStatus = false;
										Ext.Msg.show({
											title:'ファイルを開く',
											msg: '"'+dataX.file_name+'" は既に開いています。',
											icon: Ext.Msg.ERROR,
											buttons: Ext.Msg.OK
										});	
									}
								}　else if (editableStatus === 2) {
									actionStatus = 'ref_open';
								}　else if (editableStatus === 4) {
									actionStatus = 'ref_open';
								}　else if (editableStatus === 8) {
									actionStatus = false;
									Ext.Msg.show({
										title:'ファイルを開く',
										msg: '"'+dataX.file_name+'" はエクスクルーシブ・チェックアウトされているので、開けません。',
										icon: Ext.Msg.WARNING,
										buttons: Ext.Msg.OK
									});
								}　else {
									return;
								}
							} else {
								if (editableStatus === 0) {
									actionStatus = 'ref_open';
								}　else if (editableStatus === 1) {
									if (openStatus === false) {
										actionStatus = 'ref_open';
									} else {
										actionStatus = false;
										Ext.Msg.show({
											title:'ファイルを開く',
											msg: '"'+dataX.file_name+'" は既に開いています。',
											icon: Ext.Msg.ERROR,
											buttons: Ext.Msg.OK
										});	
									}
								}　else if (editableStatus === 2) {
									actionStatus = 'ref_open';
								}　else if (editableStatus === 4) {
									actionStatus = 'ref_open';
								}　else if (editableStatus === 8) {
									actionStatus = false;
									Ext.Msg.show({
										title:'ファイルを開く',
										msg: '"'+dataX.file_name+'" はエクスクルーシブ・チェックアウトされているので、開けません。',
										icon: Ext.Msg.WARNING,
										buttons: Ext.Msg.OK
									});
								}　else {
									return;
								}
							}
						}
					}
				}

				if (actionStatus !== false) {
					if (actionStatus === 'open_folder') {
						var dataY = Ext.apply({actionStatus: actionStatus}, dataX);
							dataY = Ext.apply({session_id: this_session_id}, dataY);
							dataY = Ext.apply({request_type: actionStatus}, dataY);
						Ext.Ajax.request({
							url: 'tdx/updatedata.tdx',
							jsonData: dataY,
							success: handleSuccess,
							failure: handleFailure
						});
					} else {
						if (actionStatus === 'lock_open') {
							wayToOpen = "writable";
						} else if (actionStatus === 'just_open') {
							wayToOpen = "writable";
						} else if (actionStatus === 'ref_open') {
							wayToOpen = "read_only";
						}
						actionStatus = 'open_file';
						openVersion1 = 'latest';
						ver_number1 = null;
						var dataY = Ext.apply({wayToOpen: wayToOpen}, dataX);
							dataY = Ext.apply({actionStatus: actionStatus}, dataY);
							dataY = Ext.apply({openVersion1: openVersion1}, dataY);
							dataY = Ext.apply({ver_number1: ver_number1}, dataY);
							dataY = Ext.apply({session_id: this_session_id}, dataY);
							dataY = Ext.apply({request_type: actionStatus}, dataY);
						Ext.Ajax.request({
							url: 'tdx/updatedata.tdx',
							jsonData: dataY,
							success: handleSuccess,
							failure: handleFailure
						});
					}
				} else {
					return;
				}
			
			function handleSuccess(response) {
				obj = Ext.decode(response.responseText);
				var request_success = obj.success;
				var request_redirect_uri = obj.redirect_uri;
				
				if (request_success === false) {
					var request_errors = obj.errors;
					Ext.Msg.show({
						title:'ファイルOPEN失敗',
						msg: request_errors,
						buttons: Ext.Msg.OK
					});
				} else {
					if (actionStatus === 'open_folder') {
						if (contLocation === 'folder_a') {
							Ext.getStore('TargetFolderAT').load();
							Ext.getStore('TargetFolderATFi').load();
							Ext.getStore('FolderDataStoreA').load({
								callback: function(records, operation, success) {
									if (success === true) {
										Ext.getStore('FileDataStoreA').load();
									}
								}
							});
						} else if (contLocation === 'folder_b') {
							Ext.getStore('TargetFolderBT').load();
							Ext.getStore('TargetFolderBTFi').load();
							Ext.getStore('FolderDataStoreB').load({
								callback: function(records, operation, success) {
									if (success === true) {
										Ext.getStore('FileDataStoreB').load();
									}
								}
							});
						} else {
							return;
						}
						return;
					} else if (actionStatus === 'open_file') {
						location.href = request_redirect_uri;
						return;
					} else {
						return;
					}
				}
				return;
			}

			function handleFailure(response) {
				Ext.Msg.show({
					title:'フォルダ・ファイルOPEN失敗',
					msg: 'フォルダ・ファイルOPENに失敗しました。('+contLocation+')('+actionStatus+')('+editableStatus+')',
					buttons: Ext.Msg.OK
				});
			}
		}
	}
});

