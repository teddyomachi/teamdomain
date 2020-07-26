/*
 This file is not a part of Ext JS
 Authored by (c) 2012 WoodvilleJapan
 This should be used to show context menu whenever right mouse button clicked in TeamDomain.
 */

var tree_context_menu;

var changeDomainName = Ext.create('Ext.Action', {
    icon: 'images/changeDomainName.gif',
    text: '名前を変更',
    disabled: false,
    handler: function (widget, event) {
//		Ext.getCmp('eastSidePanel').expand();
//		Ext.getCmp('domainpropertydsp').show();
//		Ext.getCmp('showDomainProperty').show();
        Ext.create('TeamDomain.view.DomainPropertyDsp').show();
    }
});

var createRootFolder = Ext.create('Ext.Action', {
    icon: 'images/createRootFolder.png',
    text: 'フォルダ作成',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('domainProperty').show();
        Ext.getCmp('createFolder').show();
    }
});

var appendRootFile = Ext.create('Ext.Action', {
    icon: 'images/appendRootFile.png',
    text: 'ファイル追加',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('domainProperty').show();
        Ext.getCmp('createRootFile').show();
    }
});

var openTrashbox = Ext.create('Ext.Action', {
    icon: 'images/openTrashbox.png',
    text: 'ゴミ箱を開く',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('reCycler').show();
    }
});

var changeFolderName = Ext.create('Ext.Action', {
    icon: 'images/changeFolderName.gif',
    text: 'フォルダ名変更',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.changeFolderNameDsp').show();
    }
});

var moveFolder = Ext.create('Ext.Action', {
    icon: 'images/moveFolder.png',
    text: '移動',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('folderProperty').show();
        Ext.getCmp('operateFolder').show();
        Ext.getCmp('ccpdFolder').show();
    }
});

var deleteFolder = Ext.create('Ext.Action', {
    icon: 'images/deleteFolder.png',
    text: '削除',
    disabled: false,
    handler: function (widget, event) {
//		Ext.getCmp('eastSidePanel').expand();
//		Ext.getCmp('folderProperty').show();
//		Ext.getCmp('operateFolder').show();
//		Ext.getCmp('ccpdFolder').show();

    }
});

var releaseFolderOwnership = Ext.create('Ext.Action', {
    icon: 'images/releaseFolderOwnership.png',
    text: '所有権のリリース　',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('folderProperty').show();
        Ext.getCmp('operateFolder').show();
        Ext.getCmp('releaseFolderOwnership').show();
    }
});

var acquireFolderOwnership = Ext.create('Ext.Action', {
    icon: 'images/acquireFolderOwnership.png',
    text: '所有権の取得',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('folderProperty').show();
        Ext.getCmp('operateFolder').show();
        Ext.getCmp('obtainFolderOwnership').show();
    }
});

var createSubFolder = Ext.create('Ext.Action', {
    icon: 'images/createSubFolder.png',
    text: 'フォルダ作成',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.createFolderDsp').show();
    }
});

var appendFile = Ext.create('Ext.Action', {
    icon: 'images/appendFile.png',
    text: 'ファイル追加',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.addFileBrowserDsp').show();
    }
});

var searchFiles = Ext.create('Ext.Action', {
    icon: 'images/searchFiles.png',
    text: '検索',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').show();
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('searchCondition').show();
    }
});

var displayProperty = Ext.create('Ext.Action', {
    icon: 'images/displayProperty.png',
    text: 'プロパティ表示・変更',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.FileProperty').show();
    }
});

var displayPropertyExpanded = Ext.create('Ext.Action', {
    icon: 'images/displayPropertyExpanded.png',
    text: '拡張プロパティ表示・変更　',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('fileProperty').show();
        Ext.getCmp('thisFileProperty').show();
        Ext.getCmp('showFileExtension').show();
    }
});

var displayPropertyDetails = Ext.create('Ext.Action', {
    icon: 'images/displayPropertyDetails.png',
    text: 'プロパティ詳細表示・変更',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('fileProperty').show();
        Ext.getCmp('thisFileProperty').show();
        Ext.getCmp('showFileDetails').show();
    }
});

var openFile = Ext.create('Ext.Action', {
    icon: 'images/openFile.png',
    text: '開く',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('fileProperty').show();
        Ext.getCmp('thisFileOpen').show();
        Ext.getCmp('openFile').show();
    }
});

var openFileVer = Ext.create('Ext.Action', {
    icon: 'images/openFileVer.png',
    text: 'バージョンを指定して開く',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('fileProperty').show();
        Ext.getCmp('thisFileOpen').show();
        Ext.getCmp('openVer').show();
    }
});

var openFileApp = Ext.create('Ext.Action', {
    icon: 'images/openFileApp.png',
    text: 'アプリケーションを指定して開く',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('fileProperty').show();
        Ext.getCmp('thisFileOpen').show();
        Ext.getCmp('openApp').show();
    }
});

var moveFile = Ext.create('Ext.Action', {
    icon: 'images/moveFile.png',
    text: '移動',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('fileProperty').show();
        Ext.getCmp('thisFileControl').show();
        Ext.getCmp('ccpdFile').show();
    }
});

var deleteFile = Ext.create('Ext.Action', {
    icon: 'images/deleteFile.png',
    text: '削除',
    disabled: false,
    handler: function (widget, event) {
//		Ext.getCmp('eastSidePanel').expand();
//		Ext.getCmp('fileProperty').show();
//		Ext.getCmp('thisFileControl').show();
//		Ext.getCmp('ccpdFile').show();
    }
});

var checkourFile = Ext.create('Ext.Action', {
    icon: 'images/checkourFile.png',
    text: 'チェックアウト',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('fileProperty').show();
        Ext.getCmp('thisFileControl').show();
        Ext.getCmp('checkOut').show();
    }
});

var lockFile = Ext.create('Ext.Action', {
    icon: 'images/lockFile.gif',
    text: 'ロック・解除',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('fileProperty').show();
        Ext.getCmp('thisFileControl').show();
        Ext.getCmp('changeLock').show();
    }
});

var releaseFileOwnership = Ext.create('Ext.Action', {
    icon: 'images/releaseFileOwnership.png',
    text: '所有権のリリース・取得',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('fileProperty').show();
        Ext.getCmp('thisFileControl').show();
        Ext.getCmp('changeOwner').show();
    }
});

var sendingFile = Ext.create('Ext.Action', {
    icon: 'images/sendingFile.png',
    text: 'メール添付',
    disabled: false,
    handler: function (widget, event) {
        Ext.getCmp('eastSidePanel').expand();
        Ext.getCmp('fileProperty').show();
        Ext.getCmp('sendMail').show();
    }
});

var settingFolderAccessRight = Ext.create('Ext.Action', {
    icon: 'images/settingFileAccessRight.png',
    text: '共有・通知を設定',
    disabled: false,
    handler: function (widget, event) {

        Ext.create('TeamDomain.view.PrivilegeDsp').show();
//		Ext.getCmp('privilegeDsp').show();
//		Ext.getCmp('folderAccess').show();
    }
});

var settingFileAccessRight = Ext.create('Ext.Action', {
    icon: 'images/settingFileAccessRight.png',
    text: 'アクセス権の設定',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.PrivilegeDsp').show();
//		Ext.getCmp('privilegeDsp').show();
//		Ext.getCmp('fileAccess').show();
    }
});

var downloadFile = Ext.create('Ext.Action', {
    icon: 'images/Download.png',
    text: 'ローカルへダウンロード',
    disabled: false,
    handler: function (widget, event) {
        console.log('test');
        downloadFileByMenu();
    }
});

var downloadFolder = Ext.create('Ext.Action', {
    icon: 'images/Download.png',
    text: 'ダウンロード',
    disabled: false,
    handler: function (widget, event) {
    }
});

var copyFolder = Ext.create('Ext.Action', {
    icon: 'images/copyFolder.gif',
    text: 'コピー',
    disabled: false,
    handler: function (widget, event) {
        clipboardMoveFolder('copy');
    }
});

var copyFile = Ext.create('Ext.Action', {
    icon: 'images/copyFile.gif',
    text: 'コピー',
    disabled: false,
    handler: function (widget, event) {
        clipboardMoveFile('copy');
    }
});

var cutFile = Ext.create('Ext.Action', {
    icon: 'images/Cut.png',
    text: 'カット',
    disabled: false,
    handler: function (widget, event) {
        clipboardMoveFile('cut');
    }
});

var cutFolder = Ext.create('Ext.Action', {
    icon: 'images/Cut.png',
    text: 'カット',
    disabled: false,
    handler: function (widget, event) {
        clipboardMoveFolder('cut');
    }
});

var pasteFile = Ext.create('Ext.Action', {
    icon: 'images/Paste.png',
    text: 'ペースト',
    disabled: false,
    handler: function (widget, event) {
        clipboardDataPaste('file_listA');
    }
});

var pasteFileUnderFolder = Ext.create('Ext.Action', {
    icon: 'images/Paste.png',
    text: 'ペースト',
    disabled: false,
    handler: function (widget, event) {
        clipboardDataPaste('folder_a');
    }
});

var checkInOut = Ext.create('Ext.Action', {
    icon: 'images/checkourFile.png',
    text: 'チェックイン・チェックアウト',
    disabled: false,
    handler: function (widget, event) {
    }
});

var fileLockUnlock = Ext.create('Ext.Action', {
    icon: 'images/lockFile.gif',
    text: 'ロック・ロック解除',
    disabled: false,
    handler: function (widget, event) {
        updateLock();
    }
});

var optClipboard = Ext.create('Ext.Action', {
    icon: 'data/small_icon/Clipboard.png',
    text: 'クリップボードを表示',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.ClipBoard').show();
    }
});

var optUserGroup = Ext.create('Ext.Action', {
    icon: 'data/small_icon/User_group.png',
    text: 'グループ設定',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.GroupDsp').show();
    }
});

var optUserMng = Ext.create('Ext.Action', {
    icon: 'data/small_icon/User.png',
    text: 'ユーザー管理',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.UserDsp').show();
    }
});

var optSystemConfig = Ext.create('Ext.Action', {
    icon: 'data/small_icon/system_config.png',
    text: 'システム設定',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.optionWin').show();
    }
});

var deleteAlias = Ext.create('Ext.Action', {
    icon: 'data/small_icon/system_config.png',
    text: 'エイリアスを解除',
    disabled: false,
    handler: function (widget, event) {
        deleteAliasDomain();
    }
});

var createAlias = Ext.create('Ext.Action', {
    icon: 'data/small_icon/system_config.png',
    text: 'エイリアスを作成',
    disabled: false,
    handler: function (widget, event) {
        createAliasDomain();
    }
});

var sendUrlLink = Ext.create('Ext.Action', {
    icon: 'data/small_icon/system_config.png',
    text: 'URLリンク送信',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.urlLinkCreate').show();
    }
});

var trashFolder = Ext.create('Ext.Action', {
    icon: 'data/small_icon/Trash.png',
    text: 'ゴミ箱に移動',
    disabled: false,
    handler: function (widget, event) {
        trashMoveFolder();
    }
});

var trashFile = Ext.create('Ext.Action', {
    icon: 'data/small_icon/Trash.png',
    text: 'ゴミ箱に移動',
    disabled: false,
    handler: function (widget, event) {
        trashMoveFile();
    }
});

var changeFileName = Ext.create('Ext.Action', {
    icon: 'images/changeFolderName.gif',
    text: 'ファイル名変更',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.changeFileNameDsp').show();
    }
});

var displayPropertyFolder = Ext.create('Ext.Action', {
    icon: 'images/displayProperty.png',
    text: 'プロパティ表示',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.FolderPropertyDsp').show();
    }
});

var displayPropertyFile = Ext.create('Ext.Action', {
    icon: 'images/displayProperty.png',
    text: 'プロパティ表示',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.FilePropertyDsp').show();
    }
});

var addSynchronousFolder = Ext.create('Ext.Action', {
    icon: 'images/displayProperty.png',
    text: '同期フォルダ作成',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.createSyncFolderDsp').show();
    }
});

var delSynchronousFolder = Ext.create('Ext.Action', {
    icon: 'images/displayProperty.png',
    text: '同期フォルダ解除',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.resetSyncFolderDsp').show();
    }
});

var addArchiveFolder = Ext.create('Ext.Action', {
    icon: 'images/displayProperty.png',
    text: 'アーカイブフォルダ作成',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.createArchiveFolderDsp').show();
    }
});

var delArchiveFolder = Ext.create('Ext.Action', {
    icon: 'images/displayProperty.png',
    text: 'アーカイブフォルダ解除',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.resetArchiveFolderDsp').show();
    }
});

var multiPagePreview = Ext.create('Ext.Action', {
    icon: 'images/displayProperty.png',
    text: 'プレビュー',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.PreviewDsp').show();
    }
});

var appendFileAgent = Ext.create('Ext.Action', {
    icon: 'images/appendFile.png',
    text: 'ローカルからアップロード',
    disabled: false,
    handler: function (widget, event) {
        var grid = Ext.getCmp('listGridPanelA');
        var model = grid.getSelectionModel();
        var record = model.getSelection()[0];
        var root = Ext.getCmp('active_op_name').value;
        var virtual_path = record.data.virtual_path;
        var offset = virtual_path.search(root);
        //currentVirtualPath = virtual_path.slice(offset);
        currentVirtualPath = record.data.virtual_path;
        //alert(currentVirtualPath);

        /*var domain = Ext.getCmp('domainGridPanelA');
        var dModel = domain.getSelectionModel();
        var dRecord = dModel.getSelection()[0];

        var upLoadDataList = [];
        var selCnt = model.getCount();
        var records = model.getSelection();
        for (var i = 0; i < selCnt; i++) {
            var record = records[i];
            var uploadData = Ext.apply({session_id: this_session_id});
            uploadData = Ext.apply({request_type: 'upload_file'}, uploadData);
            uploadData = Ext.apply({params: ['C:' + record.data.node_path, 0, dRecord.data.domain_name + ":" + currentVirtualPath]}, uploadData);
            //uploadData = Ext.apply({params: ['C:' + record.data.node_path, 0, currentVirtualPath]}, uploadData);
            //uploadData = Ext.apply({params: ['C:' + record.data.node_path, 0, 'kozaki1/TEST3']}, uploadData);
            upLoadDataList.push(uploadData);
        }
        alert(upLoadDataList[0].params[2]);*/
        //console.log(upLoadDataList[0].params);
        Ext.create('TeamDomain.view.addFileAgentDsp').show();
    }
});

var appendFileAgentOnFolder = Ext.create('Ext.Action', {
    icon: 'images/appendFile.png',
    text: 'ローカルからアップロード',
    disabled: false,
    handler: function (widget, event) {
        var grid = Ext.getCmp('folderPanelA');
        var model = grid.getSelectionModel();
        var record = model.getSelection()[0];
        var root = Ext.getCmp('active_op_name').value;
        var virtual_path = record.data.vpath;
        var offset = virtual_path.search(root);
        //currentVirtualPath = virtual_path.slice(offset);
        currentVirtualPath = record.data.vpath;
        Ext.create('TeamDomain.view.addFileAgentDsp').show();
    }
});

var downloadFileAgent = Ext.create('Ext.Action', {
    icon: 'images/Download.png',
    text: 'ローカルへダウンロード',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.addLocalFileAgentDsp').show();
    }
});

var downloadFileGeneration = Ext.create('Ext.Action', {
    icon: 'images/Download.png',
    text: 'ローカルへダウンロード(世代指定)',
    disabled: false,
    handler: function (widget, event) {
        Ext.create('TeamDomain.view.openFileVersionDsp').show();
    }
});

var openFileAgent = Ext.create('Ext.Action', {
    icon: 'images/openFile.png',
    text: 'ローカルで開く',
    disabled: false,
    handler: function (widget, event) {
    }
});
