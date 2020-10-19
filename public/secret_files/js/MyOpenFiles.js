/*
This file is not a part of Ext JS
Authored by (c) 2012 WoodvilleJapan
This should be used to open files whenever any files are selected in TeamDomain.
*/

function doOpenFile(dataX, readableRight, writableRight, editableStatus, openStatus, showFileName, fileType, readChecked, writeChecked, contLocation) {

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
				actionStatus = 'ng';
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
							actionStatus = 'ng';
							Ext.Msg.show({
								title:'ファイルを開く',
								msg: '"'+dataX.file_name+'" は既に開いています。',
								icon: Ext.Msg.ERROR,
								buttons: Ext.Msg.OK
							});	
						}
					} else if (editableStatus === 2) {
						actionStatus = 'ref_open';
					} else if (editableStatus === 4) {
						actionStatus = 'ref_open';
					} else if (editableStatus === 8) {
						actionStatus = 'ng';
						Ext.Msg.show({
							title:'ファイルを開く',
							msg: '"'+dataX.file_name+'" はエクスクルーシブ・チェックアウトされているので、開けません。',
							icon: Ext.Msg.WARNING,
							buttons: Ext.Msg.OK
						});
					} else {
						return;
					}
				} else {
					if (editableStatus === 0) {
						actionStatus = 'lock_open';
					} else if (editableStatus === 1) {
						if (openStatus === false) {
							actionStatus = 'just_open';
						} else {
							actionStatus = 'ng';
						}
					} else if (editableStatus === 2) {
						actionStatus = 'ref_open';
					} else if (editableStatus === 4) {
						actionStatus = 'ref_open';
					} else if (editableStatus === 8) {
						actionStatus = 'ng';
						Ext.Msg.show({
							title:'ファイルを開く',
							msg: '"'+dataX.file_name+'" はエクスクルーシブ・チェックアウトされているので、開けません。',
							icon: Ext.Msg.WARNING,
							buttons: Ext.Msg.OK
						});
					} else {
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
				actionStatus = 'ng';
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
							actionStatus = 'ng';
							Ext.Msg.show({
								title:'ファイルを開く',
								msg: '"'+dataX.file_name+'" は既に開いています。',
								icon: Ext.Msg.ERROR,
								buttons: Ext.Msg.OK
							});	
						}
					} else if (editableStatus === 2) {
						actionStatus = 'ref_open';
					} else if (editableStatus === 4) {
						actionStatus = 'ref_open';
					} else if (editableStatus === 8) {
						actionStatus = 'ng';
						Ext.Msg.show({
							title:'ファイルを開く',
							msg: '"'+dataX.file_name+'" はエクスクルーシブ・チェックアウトされているので、開けません。',
							icon: Ext.Msg.WARNING,
							buttons: Ext.Msg.OK
						});
					} else {
						return;
					}
				} else {
					if (editableStatus === 0) {
						actionStatus = 'ref_open';
					} else if (editableStatus === 1) {
						if (openStatus === false) {
							actionStatus = 'ref_open';
						} else {
							actionStatus = 'ng';
							Ext.Msg.show({
								title:'ファイルを開く',
								msg: '"'+dataX.file_name+'" は既に開いています。',
								icon: Ext.Msg.ERROR,
								buttons: Ext.Msg.OK
							});	
						}
					} else if (editableStatus === 2) {
						actionStatus = 'ref_open';
					} else if (editableStatus === 4) {
						actionStatus = 'ref_open';
					} else if (editableStatus === 8) {
						actionStatus = 'ng';
						Ext.Msg.show({
							title:'ファイルを開く',
							msg: '"'+dataX.file_name+'" はエクスクルーシブ・チェックアウトされているので、開けません。',
							icon: Ext.Msg.WARNING,
							buttons: Ext.Msg.OK
						});
					} else {
						return;
					}
				}
			}
		}
	}

	if (actionStatus !== 'ng') {
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
		var request_status  = obj.status;
		var request_dirty   = obj.isDirty;
		var request_redirect_uri = obj.redirect_uri;
		
		if (request_success === false) {
			var request_errors = obj.errors;
			Ext.Msg.show({
				title:'フォルダ・ファイルOPEN失敗',
				msg: request_errors,
				buttons: Ext.Msg.OK
			});
		} else {
			if (actionStatus === 'open_folder') {
				if (contLocation === 'folder_a') {
					myStore		= 'FolderDataStoreA';
					myUrl		= 'spin/foldersA.sfl';
					myComponent = '#folderPanelA';
				} else {
					myStore		= 'FolderDataStoreB';
					myUrl		= 'spin/foldersB.sfl';
					myComponent = '#folderPanelB';
				}
				//------------------
				if (request_dirty === true) {
					//フォルダツリーにて選択しているフォルダを取得
					//var thisParentNode = Ext.ComponentQuery.query('#folderPanelA')[0].selModel.selected.items[0];
					//上記のデータは参照代入であるため、下のload()コードを実行すると、リフレッシュされてしまう。
					//	console.log(thisParentNode);
						Ext.getStore(myStore).load({
						url: myUrl,
						callback: function(records, operation, success) {
								//console.log('filelist-dirty');
								var thisSelectionModel = Ext.ComponentQuery.query(myComponent)[0].getSelectionModel();
								//console.log(thisSelectionModel);

								var thisActiveRecord = [];
								var data_length = thisSelectionModel.store.data.length;
								//console.log(data_length);
								
								//読み込んだTree Dataをパースし、selectedを探し、見つかった場合には、該当ノードをselectedにする。
								for (i = 0; i < data_length; i++) {
									if (thisSelectionModel.store.data.items[i].data.selected === true) {
										thisActiveRecord = thisSelectionModel.store.data.items[i];
									}
								}

								//Tree Dataにselectedの指定がなかった場合には、root nodeをselectedにする。
								if (thisActiveRecord.length > 0) {
									thisActiveRecord = thisSelectionModel.store.data.items[0];
								}
								Ext.ComponentQuery.query(myComponent)[0].selModel.doSelect(thisActiveRecord);
								//console.log(thisParentNode);
						}
					});
				} else if (request_status === 2050) {
					//console.log('filelist-partial-load');
					//PartialLoad_FileList = true;
					//フォルダツリーにて選択しているフォルダを取得
					thisParentNode = Ext.ComponentQuery.query(myComponent)[0].selModel.selected.items[0];
                                        thisParentNode.expand(false, function() {
                                            //フォルダツリーの選択場所にて部分読み込みを実行
                                            PartialLoad = true;
                                            Ext.getStore(myStore).load({
                                                node: thisParentNode,
                                                url: myUrl,
                                                callback: function(records, operation, success) {
                                                    //選択しているフォルダの子ノードを取得
                                                    var thisNodes = thisParentNode.childNodes;
                                                    //子ノードの数を取得
                                                    var thisNodesLength = thisNodes.length;
                                                    //全子ノードをパース
                                                    for (i = 0; i < thisNodesLength ; i++) {
                                                            //選択したファイルリスト中のフォルダと同一のものを特定(file_nameにて)
                                                            if ( thisNodes[i].data.folder_name === dataX.file_name ) {
                                                                    Ext.ComponentQuery.query(myComponent)[0].selModel.doSelect(thisNodes[i]);
                                                                    //上記の処理を行なうと、selectionchangeがfireし、change_folderがリクエストされる
                                                            }
                                                    }
                                                }
                                            });
					}, this);
				} else { //statusが2050でなく、isDirtyがtrueでない場合には以下が実行される。(つまり、データをサーバから新規に取得しない。)
					//console.log('filelist-no-load');
					//フォルダツリーにて選択しているフォルダを取得
					thisParentNode = Ext.ComponentQuery.query(myComponent)[0].selModel.selected.items[0];
					thisParentNode.expand();
					//選択しているフォルダの子ノードを取得
					var thisNodes = thisParentNode.childNodes;
					//子ノードの数を取得
					var thisNodesLength = thisNodes.length;
					//全子ノードをパース
					for (i = 0; i < thisNodesLength ; i++) {
						//選択したファイルリスト中のフォルダと同一のものを特定(file_nameにて)
						if ( thisNodes[i].data.folder_name === dataX.file_name ) {
							Ext.ComponentQuery.query(myComponent)[0].selModel.doSelect(thisNodes[i]);
							//上記の処理を行なうと、selectionchangeがfireし、change_folderがリクエストされる
						}
					}
				}
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

function doOpenLocalFolder(record) {
        // ファイルリストロード処理
        var thisParentNode = Ext.ComponentQuery.query('#addAgentTree')[0].selModel.selected.items[0];
        thisParentNode.expand(false,
            function() {
                //選択しているフォルダの子ノードを取得
                var thisNodes = thisParentNode.childNodes;
                //子ノードの数を取得
                var thisNodesLength = thisNodes.length;
                //全子ノードをパース
                for (i = 0; i < thisNodesLength ; i++) {
                        //選択したファイルリスト中のフォルダと同一のものを特定
                        if (thisNodes[i].data.text === record.data.text) {
                                Ext.ComponentQuery.query('#addAgentTree')[0].selModel.doSelect(thisNodes[i]);
                        }
                }
            },
            this);
}
