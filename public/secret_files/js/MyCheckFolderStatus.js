/*
 This file is not a part of Ext JS
 Authored by (c) 2012 WoodvilleJapan
 This should be used to check the codition whenever any contents are selected in TeamDomain.
 */

function showFolderTitle(readChecked, writeChecked, ownerChecked, folderPanelName, folderPanelTitle) {
    var readableUrl = ' R<img src="data/small_icon/ok_icon.png" />';
    var unReadableUrl = ' R<img src="data/small_icon/ng_icon.png" />';
    var writableUrl = ' W<img src="data/small_icon/ok_icon.png" />';
    var unWritableUrl = ' W<img src="data/small_icon/ng_icon.png" />';
    var meOwnerUrl = ' O<img src="data/small_icon/ok_icon.png" />';
    var otherOwnerUrl = ' O';
    var nonOwnerUrl = ' O?';

    if (readChecked === true) {
        folderPanelName = folderPanelName + readableUrl;
    } else {
        folderPanelName = folderPanelName + unReadableUrl;
    }
    if (writeChecked === true) {
        folderPanelName = folderPanelName + writableUrl;
    } else {
        folderPanelName = folderPanelName + unWritableUrl;
    }
    if (ownerChecked === 'me') {
        folderPanelName = folderPanelName + meOwnerUrl;
    } else if (ownerChecked === 'other') {
        folderPanelName = folderPanelName + otherOwnerUrl;
    } else {
        folderPanelName = folderPanelName + nonOwnerUrl;
    }
    Ext.getCmp(folderPanelTitle).setTitle(folderPanelName);
}

function doCheckFolder(readChecked, writeChecked, ownerChecked, controllerChecked, targetStatus, listScreen, iconScreen, thumbnailScreen) {

    if (Ext.isEmpty(targetStatus)) {
        targetStatus = true;
    }
    if (readChecked === true) {
        Ext.getCmp(listScreen).enable();
        Ext.getCmp(thumbnailScreen).enable();
    } else {
        Ext.getCmp(listScreen).disable();
        Ext.getCmp(thumbnailScreen).disable();
    }

    //if (ownerChecked === 'me' || controllerChecked === true) {
    /*
     if (controllerChecked === true) {
     Ext.getCmp('folderAccess').enable();
     } else {
     Ext.getCmp('folderAccess').disable();
     }
     */

    /*
     if ((writeChecked === true && ownerChecked === 'me') || (readChecked === true && writeChecked === true)) {
     Ext.getCmp('show_folder_name').enable();
     Ext.getCmp('btn_change_folder_name').enable();
     } else {
     Ext.getCmp('show_folder_name').disable();
     Ext.getCmp('btn_change_folder_name').disable();
     }
     */
    /*
     var ccpd_status = 0;
     var new_folder_name_status = 0;
     if (readChecked === true && targetStatus === true) {
     Ext.getCmp('btn_copy_folder').enable();
     ccpd_status = 1;
     new_folder_name_status = 1;
     } else {
     Ext.getCmp('btn_copy_folder').disable();
     }

     if (readChecked === true && writeChecked === true && targetStatus === true) {
     Ext.getCmp('btn_move_folder').enable();
     ccpd_status = 1;
     new_folder_name_status = 1;
     } else {
     Ext.getCmp('btn_move_folder').disable();
     }

     if (readChecked === true && writeChecked === true) {
     Ext.getCmp('btn_delete_folder').enable();
     ccpd_status = 1;
     } else {
     Ext.getCmp('btn_delete_folder').disable();
     }

     if (new_folder_name_status === 1) {
     Ext.getCmp('new_folder_name').enable();
     } else {
     Ext.getCmp('new_folder_name').disable();
     }

     if (ownerChecked === 'me') {
     Ext.getCmp('releaseFolderOwnership').enable();
     } else {
     Ext.getCmp('releaseFolderOwnership').disable();
     }

     if (readChecked === true && ownerChecked === 'nobody') {
     Ext.getCmp('obtainFolderOwnership').enable();
     } else {
     Ext.getCmp('obtainFolderOwnership').disable();
     }

     if (readChecked === true && writeChecked === true) {
     Ext.getCmp('createSubFolder').enable();
     } else {
     Ext.getCmp('createSubFolder').disable();
     }

     if (writeChecked === true) {
     Ext.getCmp('createFile').enable();
     } else {
     Ext.getCmp('createFile').disable();
     }

     if (readChecked === true) {
     Ext.getCmp('searchCondition').enable();
     } else {
     Ext.getCmp('searchCondition').disable();
     }
     */
}

function doCheckTargetFolder(originalReadStatus, originalWriteStatus, writeChecked) {
    if (Ext.isEmpty(originalReadStatus)) {
        originalReadStatus = true;
    }
    if (Ext.isEmpty(originalWriteStatus)) {
        originalWriteStatus = true;
    }

    if (originalReadStatus === true && writeChecked === true) {
        Ext.getCmp('btn_copy_folder').enable();
    } else {
        Ext.getCmp('btn_copy_folder').disable();
    }

    if (originalReadStatus === true && originalWriteStatus === true && writeChecked === true) {
        Ext.getCmp('btn_move_folder').enable();
    } else {
        Ext.getCmp('btn_move_folder').disable();
    }
}

function doCheckTargetFolderFi(originalReadChecked, originalWriteChecked, targetWriteChecked, fileLockChecked, fileWriteChecked, fileOpenChecked) {
//fileLockChecked, fileWriteChecked, fileOpenChecked�E�ɂ��E�Ẵ`�E�F�E�b�E�N�E�͍폜�E��E��E�Ă��E��E�B
    if (Ext.isEmpty(originalReadChecked)) {
        originalReadStatus = true;
    } else {
        originalReadStatus = originalReadChecked;
    }

    if (Ext.isEmpty(originalWriteChecked)) {
        originalWriteStatus = true;
    } else {
        originalWriteStatus = originalWriteChecked;
    }

    if (originalReadStatus === true && originalWriteStatus === true) {
        Ext.getCmp('btn_copy_folder').enable();
    } else {
        Ext.getCmp('btn_copy_folder').disable();
        //console.log(originalReadStatus);
        //console.log(originalWriteStatus);
    }

    if (originalReadStatus === true && originalWriteStatus === true && targetWriteChecked === true) {
        Ext.getCmp('btn_move_folder').enable();
    } else {
        Ext.getCmp('btn_move_folder').disable();
    }
}

//�E��E��E�́A�E�h�E��E��E�C�E��E�A�E�ɂ�selectionchange�E��E��E��E��E�΂��E��E��E�ہAFolderDataStoreA�E�̃f�E�[�E�^�E��E�ǂݍ��E�񂾌�ɓǂݍ��E�܂��E�B
//model, selected�E�̓h�E��E��E�C�E��E�A�E��E�onGridpanelSelectionChangeDA�E��E��E��E�p�E��E��E��E��E��E�B
//target_pane�E��E�"#folderPanelA"�E�Ƃ��E��E��E��E��E��E��E��E�B
function afterLoaded(model, selected, target_pane) {

    var thisSelectionModel = Ext.ComponentQuery.query(target_pane)[0].getSelectionModel();
    //�E��E�L�E�ɂ��E��E�āAFolderTreeA�E�̃R�E��E��E�|�E�[�E�l�E��E��E�g�E�ɂ�selectionModel�E��E��E�w�E�肵�E�Ă��E��E�B
    var thisFolders = thisSelectionModel.store.data;
    //console.log(thisFolders);

    var thisActiveRecord = [];
    var data_length = thisFolders.length;

    //�E�ǂݍ��E��E�Tree Data�E��E��E�p�E�[�E�X�E��E��E�Aselected�E��E�T�E��E��E�A�E��E��E���E��E��E��E��E�ꍁE��ɂ́A�E�Y�E��E��E�m�E�[�E�h�E��E�selected�E�ɂ��E��E�B
    for (i = 0; i < data_length; i++) {
        if (thisFolders.items[i].data.selected === true) {
            thisActiveRecordId = thisFolders.items[i].id;
            thisActiveRecord = thisFolders.items[i];
        }
    }

    //Tree Data�E��E�selected�E�̎w�E�肪�E�Ȃ��E��E��E��E��E�ꍁE��ɂ́Aroot node�E��E�selected�E�ɂ��E��E�B
    if (thisActiveRecord.length === 0) {
        thisActiveRecordId = thisFolders.items[0].id;
        thisActiveRecord = thisFolders.items[0];
    }

    thisSelectionModel.doSelect(thisActiveRecord);
    //thisSelectionModel.select(thisActiveRecord);
    //console.log(thisSelectionModel);

    //Ext.ComponentQuery.query(target_pane)[0].selModel.doSelect(thisActiveRecord);

    /*
     var thisPane = Ext.getCmp('folderPanelA');
     //console.log(thisPane.selModel);
     thisPane.selModel.doSelect(thisActiveRecord.data.index);
     //console.log(Ext.ComponentQuery.query(target_pane)[0].selModel);

     //console.log(thisActiveRecordId);
     //Ext.getCmp('folderPanelA').getSelectionModel().select(thisActiveRecordId);
     */

    var this_recordsA = Ext.ComponentQuery.query(target_pane)[0].getSelectionModel().store.data;
    /*
     var thisActiveRecordA;
     //Log In �E��E��E��E�̏��E��E�
     if (InitialFlagA === true) {
     var data_length = this_recordsA.length;
     //�E�ǂݍ��E��E�Tree Data�E��E��E�p�E�[�E�X�E��E��E�Aselected�E��E�T�E��E�
     for (i = 0; i < data_length; i++) {
     if (this_recordsA.items[i].data.selected === true) {
     thisActiveRecordA = this_recordsA.items[i];
     }
     }

     //Tree Data�E��E�selected�E�̎w�E�肪�E�Ȃ��E��E��E��E��E�ꍁE��ɂ́Aroot node�E��E�selected�E�ɂ��E��E�B
     if (!thisActiveRecordA) {
     thisActiveRecordA = this_recordsA.items[0];
     }

     InitialFlagA = false;

     //�E��E�ƒ��E�̏��E��E�
     } else {
     if (PartialLoad_FileList === true) {
     var data_length = this_recordsA.length;
     //�E�ǂݍ��E��E�Tree Data�E��E��E�p�E�[�E�X�E��E��E�Aselected�E��E�T�E��E�
     for (i = 0; i < data_length; i++) {
     if (this_recordsA.items[i].data.selected === true) {
     thisActiveRecordA = this_recordsA.items[i];
     }
     }

     //Tree Data�E��E�selected�E�̎w�E�肪�E�Ȃ��E��E��E��E��E�ꍁE��ɂ́Aroot node�E��E�selected�E�ɂ��E��E�B
     if (!thisActiveRecordA) {
     thisActiveRecordA = this_recordsA.items[0];
     }

     PartialLoad_FileList = false;
     } else {
     thisActiveRecordA = LastSelectedNodeA;
     }
     }

     Ext.ComponentQuery.query(target_pane)[0].getSelectionModel().doSelect(thisActiveRecordA);
     */
}

function afterLoadedA(treestore, node, records) {
    //�E��E��E��E��E��E��E�[�E�h�E��E��E�ɂ͎��E��E��E�I�E��E��E��E��E��E��E��E��E�Ȃ��E�B
    if (FolderLoadingCountA === 0) {
        FolderLoadingCountA = 1;
    } else {
        if (FolderLoadingCountA === 1) {
            FolderLoadingCountA = 2;
        }
        if (PartialLoad === true) {
            PartialLoad = false;
        } else {
            var target_pane = "folderPanelA";
            console.log('>> before getCmp');
            var thisSelectionModel = Ext.getCmp(target_pane).getSelectionModel();
            console.log('>> after getCmp, thisSelectionModel = ' + thisSelectionModel.toString());
            // var thisSelectionModel = Ext.ComponentQuery.query(target_pane)[0].getSelectionModel();
            //var selected = Ext.getCmp("folderPanelA").getSelectionModel().selected.items[0].data;
            // console.log(thisSelectionModel);

            //�E��E�L�E�ɂ��E��E�āAFolderTreeA�E�̃R�E��E��E�|�E�[�E�l�E��E��E�g�E�ɂ�selectionModel�E��E��E�w�E�肵�E�Ă��E��E�B
            var thisFolders = thisSelectionModel.store.data;

            var thisActiveRecord = null;
            var data_length = thisSelectionModel.store.data.length;

            //�E�ǂݍ��E��E�Tree Data�E��E��E�p�E�[�E�X�E��E��E�Aselected�E��E�T�E��E��E�A�E��E��E���E��E��E��E��E�ꍁE��ɂ́A�E�Y�E��E��E�m�E�[�E�h�E��E�selected�E�ɂ��E��E�B
            for (i = 0; i < data_length; i++) {
                if (thisFolders.items[i].data.selected === true) {
                    thisActiveRecordId = thisFolders.items[i].id;
                    thisActiveRecord = thisFolders.items[i];
                    break;
                }
            }

            // if (data_length > 0) {
            //     thisActiveRecord = thisSelectionModel.getSelection();
            //     } else {
            //         thisActiveRecord = thisFolders.items[0];
            // }
            console.log(data_length);
            console.log(thisSelectionModel.toString());
            // Tree Data�E��E�selected�E�̎w�E�肪�E�Ȃ��E��E��E��E��E�ꍁE��ɂ́Aroot node�E��E�selected�E�ɂ��E��E�B

            if (Object.keys(thisActiveRecord).length === 0) {
                if (Object.keys(records).length !== 0) {
                    thisActiveRecordId = thisFolders.items[0].id;
                    thisActiveRecord = thisFolders.items[0];
                } else {
                    Ext.getCmp('domainGridPanelA').enable();
                    return;
                }
            }
            thisSelectionModel.doSelect(thisActiveRecord);
            if (thisActiveRecord === null){
                Ext.getCmp('domainGridPanelA').enable();
            }
        }
    }
}

function afterLoadedB(treestore, node, records) {
    //�E��E��E��E��E��E��E�[�E�h�E��E��E�y�E��E�1�E��E�ڂ́E���E�[�E�h�E��E��E�ɂ͎��E��E��E�I�E��E��E��E��E��E��E��E��E�Ȃ��E�B
    if (FolderLoadingCountB === 0) {
        FolderLoadingCountB = FolderLoadingCountB + 1;
    } else {
        if (PartialLoad === true) {
            PartialLoad = false;
        } else {
            var target_pane = "folderPanelB";
            console.log(Ext.getCmp(target_pane));
            var thisSelectionModel = Ext.ComponentQuery.query(target_pane)[0].getSelectionModel();

            //�E��E�L�E�ɂ��E��E�āAFolderTreeA�E�̃R�E��E��E�|�E�[�E�l�E��E��E�g�E�ɂ�selectionModel�E��E��E�w�E�肵�E�Ă��E��E�B
            var thisFolders = thisSelectionModel.store.data;

            var thisActiveRecord = [];
            var data_length = thisSelectionModel.store.data.length;

            //�E�ǂݍ��E��E�Tree Data�E��E��E�p�E�[�E�X�E��E��E�Aselected�E��E�T�E��E��E�A�E��E��E���E��E��E��E��E�ꍁE��ɂ́A�E�Y�E��E��E�m�E�[�E�h�E��E�selected�E�ɂ��E��E�B
            for (i = 0; i < data_length; i++) {
                if (thisFolders.items[i].data.selected === true) {
                    thisActiveRecordId = thisFolders.items[i].id;
                    thisActiveRecord = thisFolders.items[i];
                }
            }

            //Tree Data�E��E�selected�E�̎w�E�肪�E�Ȃ��E��E��E��E��E�ꍁE��ɂ́Aroot node�E��E�selected�E�ɂ��E��E�B
            if (Object.keys(thisActiveRecord).length === 0) {
                if (Object.keys(records).length !== 0) {
                    thisActiveRecordId = thisFolders.items[0].id;
                    thisActiveRecord = thisFolders.items[0];
                } else {
                    return;
                }
            }

            thisSelectionModel.doSelect(thisActiveRecord);
            FolderLoadingCountB = FolderLoadingCountB + 1;
        }
    }
}

function trashMoveFolder() {
    var activeData = Ext.getCmp('activeData').getForm().getFieldValues();

    /*var grid = Ext.getCmp('folderPanelA');
     var model = grid.getSelectionModel();
     if (!model.hasSelection()) {
     Ext.Msg.show({
     title: '削除フォルダ選択',
     msg: '削除するフォルダを選択してください',
     icon: Ext.Msg.ERROR,
     buttons: Ext.Msg.OK
     });
     return;
     }
     record = model.getSelection()[0];*/

    if (typeof activeData.activeFolderA_name === "undefined") {
        Ext.Msg.show({
            title: '削除フォルダ選択',
            msg: '削除するフォルダを選択してください',
            icon: Ext.Msg.ERROR,
            buttons: Ext.Msg.OK
        });
        return;
    }

    var formX;
    formX = Ext.apply({session_id: this_session_id}, formX);
    formX = Ext.apply({request_type: 'delete_folder'}, formX);
    formX = Ext.apply({original_place: 'folder_tree'}, formX);
    formX = Ext.apply({cont_location: activeData.activeFolderA_cont_location}, formX);
    formX = Ext.apply({hash_key: activeData.activeFolderA_hash}, formX);
    formX = Ext.apply({folder_writable_status: activeData.activeFolderA_writable}, formX);
    formX = Ext.apply({folder_readable_status: activeData.activeFolderA_readable}, formX);
    formX = Ext.apply({target_folder_writable: activeData.activeFolderA_parent_writable}, formX);
    formX = Ext.apply({folder_name: activeData.activeFolderA_name}, formX);
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
                title: 'フォルダの削除失敗',
                msg: request_errors,
                buttons: Ext.Msg.OK
            });
        } else {
            //Ext.getStore('FolderDataStoreA').load();
            var store = Ext.getStore('FolderDataStoreA');

            var nodeinterface = select_record.parentNode;
            Ext.apply(store.proxy.extraParams,
                {
                    Rebuilding_flag: 1
                });
            store.load(
                {
                    node: nodeinterface,
                    url: 'spin/foldersA.sfl',
                    callback: function (rec, opt, success) {
                        Ext.getStore("FileDataStoreA").load();
                        Ext.apply(store.proxy.extraParams,
                            {
                                Rebuilding_flag: 0
                            });
                    }
                });
            Ext.getStore('FileDataStoreA').load();
        }
        return;
    }

    function handleFailure(response) {
        Ext.Msg.show({
            title: 'フォルダ削除失敗',
            msg: 'サーバとの通信に失敗しました',
            buttons: Ext.Msg.OK
        });
    }
}

function trashMoveFile() {
    //var grid = Ext.getCmp('listGridPanelA');
    var response_count = 0;
    var folder_up_flag = 0;
    var selected_data_hash = {};
    selected_data_hash = GetSeledtedData(this_session_id, selected_data_hash);
    if (selected_data_hash === -1) {
        Ext.Msg.show({
            title: '削除対象選択',
            msg: '削除する対象を選択してください',
            icon: Ext.Msg.ERROR,
            buttons: Ext.Msg.OK
        });
        return;
    }
    /*var grid = Ext.getCmp(TargetComp);
     var model = grid.getSelectionModel();
     if (!model.hasSelection()) {
     Ext.Msg.show({
     title: '削除対象選択',
     msg: '削除する対象を選択してください',
     icon: Ext.Msg.ERROR,
     buttons: Ext.Msg.OK
     });
     return;
     }*/

    var file_type = selected_data_hash.file_type;
    var selCnt = selected_data_hash.selCnt;
    for (var i = 0; i < selCnt; i++) {
        var formX = selected_data_hash.data[i];
        Ext.Ajax.request({
            url: 'tdx/updatedata.tdx',
            method: 'POST',
            jsonData: formX,
            success: handleSuccess,
            failure: handleFailure
        });
    }
    /*var selCnt = model.getCount();
     var records = model.getSelection();
     for (var i = 0; i < selCnt; i++) {
     var record = records[i];
     var file_type;
     var formX = null;
     formX = Ext.apply({session_id: this_session_id}, formX);
     formX = Ext.apply({request_type: 'delete_folder'}, formX);
     formX = Ext.apply({original_place: 'file_list'}, formX);
     formX = Ext.apply({cont_location: record.data.cont_location}, formX);
     formX = Ext.apply({hash_key: record.data.hash_key}, formX);
     if (record.data.file_type === 'folder') {
     file_type = 'フォルダ';
     formX = Ext.apply({folder_writable_status: record.data.file_writable_status}, formX);
     formX = Ext.apply({folder_readable_status: record.data.file_readable_status}, formX);
     formX = Ext.apply({target_folder_writable: record.data.folder_writable_status}, formX);
     formX = Ext.apply({folder_name: record.data.file_name}, formX);
     } else {
     file_type = 'ファイル';
     formX = Ext.apply({file_writable_status: record.data.file_writable_status}, formX);
     formX = Ext.apply({lock: record.data.lock}, formX);
     formX = Ext.apply({file_name: record.data.file_name}, formX);
     }

     Ext.Ajax.request({
     url: 'tdx/updatedata.tdx',
     method: 'POST',
     jsonData: formX,
     success: handleSuccess,
     failure: handleFailure
     });
     }*/

    function handleSuccess(response) {
        response_count++;
        obj = Ext.decode(response.responseText);
        var request_success = obj.success;

        if (request_success === false) {
            var request_errors = obj.errors;
            Ext.Msg.show({
                title: file_type + 'の削除失敗',
                msg: request_errors,
                buttons: Ext.Msg.OK
            });
        } else {
            var deleted_node_type = obj.deleted_node_type;
            if (deleted_node_type == 1) {
                folder_up_flag = 1;
            }
            if (response_count == selCnt) {
                if (folder_up_flag == 1) {
                    var store = Ext.getStore('FolderDataStoreA');
                    //var nodeinterface = select_record;
                    var nodeinterface;
                    nodeinterface = GetParentNode(nodeinterface, store);

                    Ext.apply(store.proxy.extraParams,
                        {
                            Rebuilding_flag: 1
                        });
                    store.load(
                        {
                            node: nodeinterface,
                            url: 'spin/foldersA.sfl',
                            callback: function (rec, opt, success) {
                                Ext.getStore("FileDataStoreA").load();
                                Ext.apply(store.proxy.extraParams,
                                    {
                                        Rebuilding_flag: 0
                                    });
                                response_count = 0;
                                folder_up_flag = 0;
                            }
                        });
                } else {
                    Ext.getStore('FileDataStoreA').load();
                }
            }
        }
        return;
    }

    function handleFailure(response) {
        Ext.Msg.show({
            title: file_type + '削除失敗',
            msg: 'サーバとの通信に失敗しました',
            buttons: Ext.Msg.OK
        });
    }
}

function clipboardMoveFolder(opType) {
    if (Busy === true) {
        return;
    }
    Busy = true;
    var opTypeStr;
    if (opType === 'copy') {
        opTypeStr = 'コピー';
    } else {
        opTypeStr = 'カット';
    }
    var grid = Ext.getCmp('folderPanelA');
    var model = grid.getSelectionModel();
    if (!model.hasSelection()) {
        Busy = false;
        Ext.Msg.show({
            title: opTypeStr + 'フォルダ選択',
            msg: opTypeStr + 'するフォルダを選択してください',
            icon: Ext.Msg.ERROR,
            buttons: Ext.Msg.OK
        });
        return;
    }
    // クリップボードクリア
    if (false === clipBoardAllClear()) {
        Busy = false;
        return;
    }
    record = model.getSelection()[0];
    var formX;
    formX = Ext.apply({session_id: this_session_id}, formX);
    formX = Ext.apply({request_type: opType + '_clipboard'}, formX);
    //formX = Ext.apply({original_place: 'folder_tree'}, formX);
    formX = Ext.apply({original_place: TargetComp}, formX);
    formX = Ext.apply({cont_location: record.data.cont_location}, formX);
    formX = Ext.apply({hash_key: record.data.hash_key}, formX);
    formX = Ext.apply({folder_writable_status: record.data.folder_writable_status}, formX);
    formX = Ext.apply({folder_readable_status: record.data.folder_readable_status}, formX);
    formX = Ext.apply({target_folder_writable: record.data.parent_writable_status}, formX);
    formX = Ext.apply({folder_name: record.data.folder_name}, formX);
    Ext.Ajax.request({
        url: 'tdx/updatedata.tdx',
        method: 'POST',
        jsonData: formX,
        success: handleSuccess,
        failure: handleFailure
    });

    function handleSuccess(response) {
        Busy = false;
        obj = Ext.decode(response.responseText);
        var request_success = obj.success;

        if (request_success === false) {
            var request_errors = obj.errors;
            Ext.Msg.show({
                title: 'フォルダの' + opTypeStr + '失敗',
                msg: request_errors,
                buttons: Ext.Msg.OK
            });
        } else {
//                    Ext.getStore('FolderDataStoreA').load();
//                   Ext.getStore('FileDataStoreA').load();
        }
        return;
    }

    function handleFailure(response) {
        Busy = false;
        Ext.Msg.show({
            title: 'フォルダ' + opTypeStr + '失敗',
            msg: 'サーバとの通信に失敗しました',
            buttons: Ext.Msg.OK
        });
    }
}

function clipboardMoveFile(opType) {
    if (Busy === true) {
        return;
    }
    Busy = true;
    var opTypeStr;
    if (opType === 'copy') {
        opTypeStr = 'コピー';
    } else {
        opTypeStr = 'カット';
    }
    //var grid = Ext.getCmp('listGridPanelA');
    var grid = Ext.getCmp(TargetComp);
    var model = grid.getSelectionModel();
    if (!model.hasSelection()) {
        Busy = false;
        Ext.Msg.show({
            title: opTypeStr + '対象選択',
            msg: opTypeStr + 'する対象を選択してください',
            icon: Ext.Msg.ERROR,
            buttons: Ext.Msg.OK
        });
        return;
    }

    // クリチE�Eボ�Eドクリア
    if (false === clipBoardAllClear()) {
        Busy = false;
        return;
    }

    var strMsg;
    var selCnt = model.getCount();
    var records = model.getSelection();
    for (var i = 0; i < selCnt; i++) {
        var record = records[i];
        var file_type;
        var formX = null;
        formX = Ext.apply({session_id: this_session_id}, formX);
        formX = Ext.apply({request_type: opType + '_clipboard'}, formX);
        //formX = Ext.apply({original_place: 'file_list'}, formX);
        formX = Ext.apply({original_place: TargetComp}, formX);
        formX = Ext.apply({cont_location: record.data.cont_location}, formX);
        formX = Ext.apply({hash_key: record.data.hash_key}, formX);
        if (record.data.file_type === 'folder') {
            file_type = 'フォルダ';
            formX = Ext.apply({folder_writable_status: record.data.file_writable_status}, formX);
            formX = Ext.apply({folder_readable_status: record.data.file_readable_status}, formX);
            formX = Ext.apply({target_folder_writable: record.data.folder_writable_status}, formX);
            formX = Ext.apply({folder_name: record.data.file_name}, formX);
        } else {
            file_type = 'ファイル';
            formX = Ext.apply({file_writable_status: record.data.file_writable_status}, formX);
            formX = Ext.apply({lock: record.data.lock}, formX);
            formX = Ext.apply({file_name: record.data.file_name}, formX);
        }
        Ext.Ajax.request({
            url: 'tdx/updatedata.tdx',
            method: 'POST',
            jsonData: formX,
            success: handleSuccess,
            failure: handleFailure
        });
    }

    function handleSuccess(response) {
        Busy = false;
        obj = Ext.decode(response.responseText);
        var request_success = obj.success;

        if (request_success === false) {
            var request_errors = obj.errors;
            Ext.Msg.show({
                title: file_type + 'の' + opTypeStr + '失敗',
                msg: request_errors,
                buttons: Ext.Msg.OK
            });
        } else {
            Ext.getStore('FileDataStoreA').load();
        }
        return;
    }

    function handleFailure(response) {
        Busy = false;
        Ext.Msg.show({
            title: file_type + opTypeStr + '失敗',
            msg: 'サーバとの通信に失敗しました',
            buttons: Ext.Msg.OK
        });
    }
}

function clipBoardAllClear() {
    var clear;
    clear = Ext.apply({session_id: this_session_id}, clear);
    clear = Ext.apply({request_type: "clipboard_all_clear"}, clear);
    Ext.Ajax.request({
        url: 'tdx/updatedata.tdx',
        timeout: 0,
        jsonData: clear,
        async: false,
        success: handleSuccessClear,
        failure: handleFailureClear
    });

    function handleSuccessClear(response) {
        obj = Ext.decode(response.responseText);
        var request_success = obj.success;
        if (request_success === false) {
            var request_errors = obj.errors;
            Ext.Msg.show({
                title: '「クリップボードの全クリア」の失敗',
                msg: request_errors,
                buttons: Ext.Msg.OK
            });
        }
        return request_success;
    }

    function handleFailureClear(response) {
        Ext.Msg.show({
            title: '「クリップボードの全クリア」の失敗',
            msg: 'サーバとの通信に失敗しました。',
            buttons: Ext.Msg.OK
        });
        return false;
    }
}

function clipboardDataPaste(location) {
    if (Busy === true) {
        return;
    }
    Busy = true;

    var paste;
    paste = Ext.apply({session_id: this_session_id}, paste);
    paste = Ext.apply({request_type: "paste_file_all"}, paste);
    if ('file_listA' === location) {
        // ハッシュキー取征E
        var grid = Ext.getCmp('listGridPanelA');
        var record = grid.getSelectionModel().getSelection()[0];
        paste = Ext.apply({hash_key: record.data.hash_key}, paste);
    }
    Ext.Ajax.request({
        url: 'tdx/updatedata.tdx',
        timeout: 0,
        jsonData: paste,
        success: handleSuccess,
        failure: handleFailure
    });

    function handleSuccess(response) {
        console.log('test');
        obj = Ext.decode(response.responseText);
        var request_success = obj.success;
        if (request_success === false) {
            Busy = false;
            var request_errors = obj.errors;
            Ext.Msg.show({
                title: '「クリップボードの貼り付け」の失敗',
                msg: request_errors,
                buttons: Ext.Msg.OK
            });
        } else {
            requestRefresh();
        }

        return request_success;
    }

    function handleFailure(response) {
        Busy = false;
        Ext.Msg.show({
            title: '「クリップボードの貼り付け」の失敗',
            msg: 'サーバとの通信に失敗しました。',
            buttons: Ext.Msg.OK
        });
        return false;
    }

    function requestRefresh() {
        var requestRefreshData = Ext.apply({session_id: this_session_id});
        requestRefreshData = Ext.apply({event_type: "property_paste_file"}, requestRefreshData);
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
                title: '「クリップボードの貼り付け」の失敗',
                msg: request_errors,
                buttons: Ext.Msg.OK
            });
            return;
        } else {
            Ext.getStore('FolderDataStoreA').load();
            Ext.getStore('FileDataStoreA').load();
            Busy = false;
        }
    }

    function handleFailure2(response) {
        Busy = false;
        Ext.Msg.show({
            title: '「クリップボードの貼り付け」の失敗',
            msg: 'サーバとの通信に失敗しました',
            buttons: Ext.Msg.OK
        });
        return;
    }
}

function createAliasDomain() {
    try {
        var alias;
        alias = Ext.apply({session_id: this_session_id}, alias);
        alias = Ext.apply({request_type: "create_alias_domain"}, alias);

        var target = Ext.getCmp('opend_by').value;
        var grid = Ext.getCmp(target);
        var model = grid.getSelectionModel();
        if (!model.hasSelection()) {
            Ext.Msg.show({
                title: opTypeStr + 'フォルダ選択',
                msg: opTypeStr + 'するフォルダを選択してください',
                icon: Ext.Msg.ERROR,
                buttons: Ext.Msg.OK
            });
            return;
        }
        var record = model.getSelection()[0];
        alias = Ext.apply({hash_key: record.data.hash_key}, alias);
        alias = Ext.apply({target: target}, alias);

        Ext.Ajax.request({
            url: 'tdx/updatedata.tdx',
            timeout: 0,
            jsonData: alias,
            success: handleSuccess,
            failure: handleFailure
        });
    } catch (e) {
        Ext.Msg.show({msg: e, buttons: Ext.Msg.OK});
    }
    function handleSuccess(response) {
        obj = Ext.decode(response.responseText);
        var request_success = obj.success;
        if (request_success === false) {
            var request_errors = obj.errors;
            Ext.Msg.show({
                title: 'エイリアスの作成失敗',
                msg: request_errors,
                buttons: Ext.Msg.OK
            });
        } else {
            Ext.getStore('DomainDataStoreA').load();
        }
        return request_success;
    }

    function handleFailure(response) {
        Ext.Msg.show({
            title: 'エイリアスの作成失敗',
            msg: 'サーバとの通信に失敗しました。',
            buttons: Ext.Msg.OK
        });
        return false;
    }
}

function deleteAliasDomain() {
    try {
        var alias;
        alias = Ext.apply({session_id: this_session_id}, alias);
        alias = Ext.apply({request_type: "delete_alias_domain"}, alias);

        var grid = Ext.getCmp('domainGridPanelA');
        var model = grid.getSelectionModel();
        if (!model.hasSelection()) {
            Ext.Msg.show({
                title: 'エイリアス選択',
                msg: '削除するエイリアスを選択してください',
                icon: Ext.Msg.ERROR,
                buttons: Ext.Msg.OK
            });
            return;
        }
        var record = model.getSelection()[0];
        if (record.data.domain_name === 'ROOT Domain') {
            Ext.Msg.show({
                title: 'エイリアス解除',
                msg: 'ルートドメインは削除できません。',
                icon: Ext.Msg.ERROR,
                buttons: Ext.Msg.OK
            });
            return;
        } else if (record.data.domain_name === 'ワークエリア') {
            Ext.Msg.show({
                title: 'エイリアス解除',
                msg: 'パーソナルドメインは削除できません。',
                icon: Ext.Msg.ERROR,
                buttons: Ext.Msg.OK
            });
            return;
        }
        alias = Ext.apply({hash_key: record.data.hash_key}, alias);

        Ext.Ajax.request({
            url: 'tdx/updatedata.tdx',
            timeout: 0,
            jsonData: alias,
            success: handleSuccess,
            failure: handleFailure
        });
    } catch (e) {
        Ext.Msg.show({msg: e, buttons: Ext.Msg.OK});
    }
    function handleSuccess(response) {
        obj = Ext.decode(response.responseText);
        var request_success = obj.success;
        if (request_success === false) {
            var request_errors = obj.errors;
            Ext.Msg.show({
                title: 'エイリアスの削除失敗',
                msg: request_errors,
                buttons: Ext.Msg.OK
            });
        } else {
            Ext.getStore('DomainDataStoreA').load();
        }
        return request_success;
    }

    function handleFailure(response) {
        Ext.Msg.show({
            title: 'エイリアスの削除失敗',
            msg: 'サーバとの通信に失敗しました。',
            buttons: Ext.Msg.OK
        });
        return false;
    }
}


function updateLock() {
    if (Busy === true) {
        return;
    }
    Busy = true;

    var grid = Ext.getCmp('listGridPanelA');
    var model = grid.getSelectionModel();
    if (!model.hasSelection()) {
        Busy = false;
        Ext.Msg.show({
            title: 'ロック・ロック解除対象選択',
            msg: 'ロック・ロック解除する対象を選択してください',
            icon: Ext.Msg.ERROR,
            buttons: Ext.Msg.OK
        });
        return;
    }

    var selCnt = model.getCount();
    var records = model.getSelection();
    var fileList = [];
    var failureList = '';
    for (var i = 0; i < selCnt; i++) {
        var record = records[i];
        if (record.data.file_type === 'folder') {
            continue;
        }
        if (2 === record.data.lock) {
            failureList += record.data.file_name + '<br/>';
            continue;
        }

        var fileInfo = {
            folder_hash_key: record.data.folder_hash_key,
            lock: record.data.lock,
            file_name: record.data.file_name
        };

        fileList.push(fileInfo);
    }

    if (failureList.length > 0) {
        Busy = false;
        Ext.Msg.show({
            title: 'ロック・ロック解除の失敗',
            msg: '異なるユーザにロックされているファイルが存在します<br/>' + failureList,
            buttons: Ext.Msg.OK
        });
        return;
    }

    var formX = null;
    formX = Ext.apply({session_id: this_session_id}, formX);
    formX = Ext.apply({request_type: 'update_file_lock'}, formX);
    formX = Ext.apply({file_list: fileList}, formX);

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
                title: 'ロック・ロック解除の失敗',
                msg: '失敗したファイルが存在します<br/>' + request_errors,
                buttons: Ext.Msg.OK
            });
        } else {
            Ext.Msg.show({
                title: 'ロチE��・ロチE��解除成功',
                msg: '選択したファイルの更新が完亁E��ました',
                buttons: Ext.Msg.OK
            });
        }
        requestRefresh();
        return;
    }

    function handleFailure(response) {
        Busy = false;
        Ext.Msg.show({
            title: 'ロック・ロック解除失敗',
            msg: 'サーバとの通信に失敗しました',
            buttons: Ext.Msg.OK
        });
    }

    function requestRefresh() {
        // 選択ファイルのhash_keyとcon_locationを取得し、親チE��レクトリ検索条件とする
        var record = model.getSelection()[0];

        var formY = null;
        formY = Ext.apply({session_id: this_session_id}, formY);
        formY = Ext.apply({cont_location: record.data.cont_location}, formY);
        formY = Ext.apply({hash_key: record.data.hash_key}, formY);
        formY = Ext.apply({request_type: "update_force_file_list"}, formY);

        Ext.Ajax.request({
            url: 'tdx/updatedata.tdx',
            jsonData: formY,
            success: refreshHandleSuccess,
            failure: refreshHandleFailure
        });
    }

    function refreshHandleSuccess(response) {
        Busy = false;
        obj = Ext.decode(response.responseText);
        var request_success = obj.success;
        if (request_success === false) {
            var request_errors = obj.errors;
            Ext.Msg.show({
                title: '画面情報更新失敗',
                msg: '画面をリロードしてください<br/>' + request_errors,
                buttons: Ext.Msg.OK
            });
        } else {
            Ext.getStore('FileDataStoreA').load();
        }
    }

    function refreshHandleFailure(response) {
        Busy = false;
        Ext.Msg.show({
            title: '画面情報更新失敗',
            msg: 'サーバとの通信に失敗しました',
            buttons: Ext.Msg.OK
        });
    }
}
