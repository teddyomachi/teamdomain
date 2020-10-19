/*
 * アップロード機能
 */
function doFileUploadManager(session_id){
    
    // ローカルパス取得
    var json_url;
    json_url = getLocalFolderTree(session_id, "");
    
    var request_id;
    var timer;
    var sel_id, sel_text, sel_hash_key;
    
    var win;

    var filename = {
        id: 'filename',
        xtype: 'textfield',
        anchor: '100%',
        fieldLabel: 'ファイル名'    
    };
    var selfile = {
        xtype: 'fieldset',
        title: '選択ファイル',
        items: [filename]
    };

    var store = Ext.create('Ext.data.TreeStore',{
        proxy: {
            type: 'ajax',
            url: json_url
        },
        root: {
            text: 'ファイル名',
            id: 'id',
            expanded: true
        },
        folderSort: false
    });

    var tree =  new Ext.tree.TreePanel({
        store: store,
        renderTo: Ext.getBody(),
        height: 350,
        useArrows: true,
        lines: true,
        rootVisible: false, 
        dockedItems: [{
            xtype: 'toolbar',
            items: [{
                text: '全て表示',
                handler: function(){
                    tree.expandAll();
                }
            },{
                text: '全て閉じる',
                handler: function(){
                    tree.collapseAll();
                }
            }]
        }],
        listeners: {
            itemclick: function(s,r) {
                sel_id = r.data.id;
                sel_text = r.data.text;
                sel_hash_key = r.data.hash_key;
                Ext.getCmp('filename').setValue(sel_text);
            }
        }
    });

    var pbar = new Ext.ProgressBar({
        region: 'south',
        text: "",
        hidden: true
    });

    var win = new Ext.Window({
        title: 'アップロードファイル選択',
        width:  400,
        height: 500,
        modal:  false,
        items: [tree, selfile, pbar],
        buttons: [
            {text: 'キャンセル', id: 'cancelButton', width: 100,
                handler: function(){
                    win.close();
                }
            },
            {text: 'アップロード', id: 'uploadButton', width: 100,
                handler: function(){
                    //  ファイル未選択
                    if(""===Ext.getCmp('filename').getValue()){
                        Ext.Msg.show({
                            title:'アップロード',
                            msg: 'アップロード対称が選択されていません。',
                            icon: Ext.Msg.ERROR,
                            buttons: Ext.Msg.OK
                        });                     
                        return false;
                    }
             
                    // アップロードボタン使用不可
                    Ext.getCmp('uploadButton').disable();
                    
                    var return_json;
                    var jsonObj;

                    // Agentによりファイルアップデート
                    return_json = doUpLoadFolder(session_id, "");                 
                 
                    pbar.updateProgress(0, " ");
                    if (!pbar.rendered){  // 描画されていない場合は描画する
                        pbar.render("pbar");
                    } else {
                        pbar.text = "";
                        pbar.show();
                    }
                    var return_json;
                    var total_size;
                    var upload_size = 0;
                    var request_status;
                 
                    // TEST用 --
                    var test_count = 0;
                    // TEST用 --
                    timer = setInterval(function() {
                        // Agentよりアップロードステータス取得
//                          return_json = getUpLoadStatus(session_id, request_id, 1);
                        // TEST用 --
                        return_json = getUpLoadStatus(session_id, test_count, 1);
                        // TEST用 --
                        jsonObj = JSON.parse(return_json);
                        total_size = jsonObj.total_size;
                        upload_size = jsonObj.uploaded_size;
                        request_status = jsonObj.status;
                     
                        // 進捗状況の更新
                        pbar.updateProgress(upload_size/total_size, upload_size+" / "+total_size+" Byte");

                        // request_statusが1でアップロード完了
                        if (1 === request_status || upload_size >= total_size) {
                            Ext.Msg.show({
                                title:'アップロード',
                                msg: 'アップロードが完了しました。',
                                icon: Ext.Msg.INFO,
                                buttons: Ext.Msg.OK
                            });
                            pbar.updateProgress(0, " ");
                            clearInterval(timer);
                        
                            // アップロードボタン使用可
                            Ext.getCmp('uploadButton').enable();                        
                            
                            pbar.hide();
                        }
                         
                        //  TEST用 -- 
                        test_count += 10;
                        //  TEST用 -- 
                    }, 300);
                }
            },
            {text: '中断', id: 'stopButton', width: 100,
                handler: function(){
                    // Agentにuploadの中断をリクエスト
                    getUpLoadStatus(session_id, request_id, 2);
                    
                    // プログレスバー停止
                    clearInterval(timer);
                    Ext.Msg.show({
                            title:'アップロード',
                            msg: 'アップロードを中断しました。',
                            icon: Ext.Msg.INFO,
                            buttons: Ext.Msg.OK
                    });
                    pbar.updateProgress(0, " ");

                    // アップロードボタン使用可
                    Ext.getCmp('uploadButton').enable();
                    
                    pbar.hide();
                }
            }
        ]
    });
    
    win.show();
    
}

/*
 * ダウンロード機能
 */
function doFileDownloadManager(session_id){

    // ローカルパス取得
    var json_url;
    json_url = getLocalFolderTree(session_id, "");
    
    var request_id;
    var timer;
    var sel_id, sel_text, sel_hash_key;
    
    var win;

    var filename = {
        id: 'filename',
        xtype: 'textfield',
        anchor: '100%',
        fieldLabel: 'ファイル名'    
    };
    var selfile = {
        xtype: 'fieldset',
        title: '選択ファイル',
        items: [filename]
    };

    var store = Ext.create('Ext.data.TreeStore',{
        proxy: {
            type: 'ajax',
            url: json_url
        },
        root: {
            text: 'ファイル名',
            id: 'id',
            expanded: true
        },
        folderSort: false
    });

    var tree =  new Ext.tree.TreePanel({
        store: store,
        renderTo: Ext.getBody(),
        height: 350,
        useArrows: true,
        lines: true,
        rootVisible: false, 
        dockedItems: [{
            xtype: 'toolbar',
            items: [{
                text: '全て表示',
                handler: function(){
                    tree.expandAll();
                }
            },{
                text: '全て閉じる',
                handler: function(){
                    tree.collapseAll();
                }
            }]
        }],
        listeners: {
            itemclick: function(s,r) {
                sel_id = r.data.id;
                sel_text = r.data.text;
                sel_hash_key = r.data.hash_key;
                Ext.getCmp('filename').setValue(sel_text);
            }
        }
    });

    var pbar = new Ext.ProgressBar({
        region: 'south',
        text: "",
        hidden: true
    });

    var win = new Ext.Window({
        title: 'ダウンロードファイル選択',
        width:  400,
        height: 500,
        items: [tree, selfile, pbar],
        buttons: [
            {text: 'キャンセル', id: 'cancelButton', width: 100,
                handler: function(){
                    win.close();
                }
            },
            {text: 'ダウンロード', id: 'uploadButton', width: 100,
                handler: function(){
                    //  ファイル未選択
                    if(""===Ext.getCmp('filename').getValue()){
                        Ext.Msg.show({
                            title:'ダウンロード',
                            msg: 'ダウンロード対称が選択されていません。',
                            icon: Ext.Msg.ERROR,
                            buttons: Ext.Msg.OK
                        });                     
                        return false;
                    }
                    
                    // ダウンロードボタン使用不可
                    Ext.getCmp('uploadButton').disable();
                 
                    var return_json;
                    var jsonObj;

                    // Agentによりファイルダウンロード
                    return_json = doDownLoadFolder(session_id, sel_hash_key);                 
                 
                    pbar.updateProgress(0, " ");
                    if (!pbar.rendered){  // 描画されていない場合は描画する
                        pbar.render("pbar");
                    } else {
                        pbar.text = "";
                        pbar.show();
                    }
                    var return_json;
                    var total_size;
                    var upload_size = 0;
                    var request_status;
                 
                    // TEST用 --
                    var test_count = 0;
                    // TEST用 --
                    timer = setInterval(function() {
                        // Agentよりダウンロードステータス取得
//                          return_json = getUpLoadStatus(session_id, request_id, 1);
                        // TEST用 --
                        return_json = getUpLoadStatus(session_id, test_count, 1);
                        // TEST用 --
                        jsonObj = JSON.parse(return_json);
                        total_size = jsonObj.total_size;
                        upload_size = jsonObj.uploaded_size;
                        request_status = jsonObj.status;
                     
                        // 進捗状況の更新
                        pbar.updateProgress(upload_size/total_size, upload_size+" / "+total_size+" Byte");

                        // request_statusが1でダウンロード完了
                        if (1 === request_status || upload_size >= total_size) {
                            Ext.Msg.show({
                                title:'ダウンロード',
                                msg: 'ダウンロードが完了しました。',
                                icon: Ext.Msg.INFO,
                                buttons: Ext.Msg.OK
                            });
                            pbar.updateProgress(0, " ");
                            clearInterval(timer);
                        
                            // ダウンロードボタン使用可
                            Ext.getCmp('uploadButton').enable();     
                            
                            pbar.hide();
                        }
                     
                        //  TEST用 --
                        test_count += 10;
                        //  TEST用 --
                    }, 300);
                }
            },
            {text: '中断', id: 'stopButton', width: 100,
                handler: function(){
                    // Agentにuploadの中断をリクエスト
                    getUpLoadStatus(session_id, request_id, 2);
                    
                    // プログレスバー停止
                    clearInterval(timer);
                    Ext.Msg.show({
                            title:'ダウンロード',
                            msg: 'ダウンロードを中断しました。',
                            icon: Ext.Msg.INFO,
                            buttons: Ext.Msg.OK
                    });
                    pbar.updateProgress(0, " ");

                    // ダウンロードボタン使用可
                    Ext.getCmp('uploadButton').enable();
                    
                    pbar.hide();                    
                }
            }
        ]
    });
    
    win.show();
    
}

/*
 * ローカル管理機能
 */
function doLocalFileManager(session_id){
    
    //ローカルパス取得
    var org_url,new_url;
    org_url = getLocalFolderTree(session_id, "");
    new_url = getLocalFolderTree(session_id, "");
    
    var org_store = Ext.create('Ext.data.TreeStore',{
        proxy:{
            type:'ajax',
            url: org_url
        },
        root:{
            text: 'ファイル名',
            id: 'id',
            expanded: true
        },
        folderSort: true,
        sorters: [{
            property: 'text',
            direction: 'ASC'
        }]        
    });
    var new_store = Ext.create('Ext.data.TreeStore',{
        proxy:{
            type:'ajax',
            url: new_url
        },
        root:{
            text: 'ファイル名',
            id: 'id',
            expanded: true
        },
        folderSort: true,
        sorters: [{
            property: 'text',
            direction: 'ASC'
        }]
    });
    
    var org_id, org_text, org_hash_key;
    var org_tree = new Ext.tree.TreePanel({
        id: org_tree,
        store: org_store,
        width: 490,
        height: 465,
        rootVisible: false, 
        dockedItems: [{
            xtype: 'toolbar',
            items: [{
                text: '全て表示',
                handler: function(){
                    org_tree.expandAll();
                }
            },{
                text: '全て閉じる',
                handler: function(){
                    org_tree.collapseAll();
                }
            }]
        }],
        listeners: {
            itemclick: function(s,r){
                org_id = r.data.id;
                org_text = r.data.text;
                org_hash_key = r.data.hash_key;
            }
        },
        viewConfig: {
            plugins: {
                ptype: 'treeviewdragdrop',
                appendOnly: true
            }
        },
        renderTo: Ext.getBody()
    });

    var new_id, new_text, new_hash_key;
    var new_tree = new Ext.tree.TreePanel({
        id: 'new_tree',
        store: new_store,
        width: 490,
        height: 465,
        rootVisible: false,
        dockedItems: [{
            xtype: 'toolbar',
            items: [{
                text: '全て表示',
                handler: function(){
                    new_tree.expandAll();
                }
            },{
                text: '全て閉じる',
                handler: function(){
                    new_tree.collapseAll();
                }
            }]
        }],
        listeners: {
           itemclick: function(s,r){
               new_id = r.data.id;
               new_text = r.data.text;
               new_hash_key = r.data.hash_key;
           }
        },
        viewConfig: {
            plugins: {
                ptype: 'treeviewdragdrop',
                appendOnly: true
            }
        },
        renderTo: Ext.getBody()       
    });
    
    var taskPanel = new Ext.panel.Panel({
        width: 588,
        height: 465,
        layout: 'border',
        items: [
            {
                xtype: 'panel',
                flex: 1,
                region: 'west',
                title: '変更前フォルダ',
                items: [org_tree]
            },
            {
                xtype: 'panel',
                flex: 1,
                region: 'center',
                title: '変更後フォルダ',
                items: [new_tree]
            }
        ],
        buttons: [
            {text: 'キャンセル', id: 'cancelButton', width: 100,
                handler: function(){
                    win.close();
                }
            },
            {text: '実行', id: 'execButton', width: 100,
                handler: function(){
                    Ext.Msg.show({
                            title:'ローカル管理',
                            msg: '変更を反映しました。',
                            icon: Ext.Msg.INFO,
                            buttons: Ext.Msg.OK
                    });
                    win.close();
                }
            }
        ]        
    });
    
    var win = new Ext.Window({
        width: 600,
        height: 500,
        title: 'ローカルフォルダ管理',
        items:[taskPanel]
    });
    
    win.show();
}

