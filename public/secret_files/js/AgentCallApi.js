/* 
 * Agent リクエスト　API
 */

/* 
 * upload_folder 
 */
function doUpLoadFolder(session_id, folder_path){
    /*    
    var formX = this.up().getForm().getFieldValues();
    
    formX = Ext.apply({session_id: session_id}, formX);
    formX = Ext.apply({folder_path: folder_path}, formX);

    Ext.Ajax.request({
            url: 'tdx/updatedata.tdx',
            method: 'POST',
            jsonData: formX,
            success: handleSuccess,
            failure: handleFailure
    });    
    
    */
}

/* 
 * download_folder 
 */
function doDownLoadFolder(session_id, hssh_key){
    /*
    var return_json = new Ajax.request(
                            url,
                            {method: 'get',
                             parameters: 'session_id=' + session_id + '&hssh_key = '+ hssh_key
                            });
    return return_json;    
    */
}

/* 
 * get_upload_status
 */
function getUpLoadStatus(session_id, request_id, status_request){
    var return_json;
    
    if(2 === status_request){
        // 中断
        return_json = '{"total_size":100, "uploaded_size":'+ request_id +', "status":2}';
    }else{
        // ステータス
        if(100 === request_id){
            return_json = '{"total_size":100, "uploaded_size":'+ request_id +', "status":1}';
        }else{
            return_json = '{"total_size":100, "uploaded_size":'+ request_id +', "status":0}';
        }
    }
    
    /*
    var return_json = new Ajax.request(
                            url,
                            {method: 'get',
                             parameters: 'session_id=' + session_id + 
                                         '&request_id = '+ request_id +
                                         '&status_request = '+ status_request
                            });    
    */
    return return_json;
}

/* 
 * get_local_folder_path 
 */
function getLocalFolderPath(session_id, folder_path){
    /*
    var return_json = new Ajax.request(
                            url,
                            {method: 'get',
                             parameters: 'session_id=' + session_id + '&folder_path = '+ folder_path
                            });
    return return_json;
    
    
    
    */
   
}

/* 
 * get_local_folder_tree
 */
function getLocalFolderTree(session_id, folder_path){
    /*
    var return_json = new Ajax.request(
                            url,
                            {method: 'get',
                             parameters: 'session_id=' + session_id + '&folder_path = '+ folder_path
                            });
    return return_json;
    */
    
    
    var json_url = 'json_data/test.json';
    return json_url;
}

/* 
 * get_local_preview_file
 */
function getLocalPreviewFile(session){
    /*
    var formX = this.up().getForm().getFieldValues();
    
    formX = Ext.apply({session_id: session_id}, formX);
    formX = Ext.apply({folder_path: folder_path}, formX);

    Ext.Ajax.request({
            url: 'tdx/updatedata.tdx',
            method: 'POST',
            jsonData: formX,
            success: handleSuccess,
            failure: handleFailure
    });    
    
    function handleSuccess(response) {
        obj = Ext.decode(response.responseText);

        var request_success      = obj.success;
        var request_url          = obj.url;
        var html_url;
    
        if (request_success === false) {
            Busy = false;
            var request_errors = obj.errors;
            Ext.Msg.show({
                    title:'プレビュー',
                    msg: 'ファイル送信失敗',
                    buttons: Ext.Msg.OK
            });
            return;
        }
        return request_url;
    
        
    }

    function handleFailure(response) {
        Busy = false;
        Ext.Msg.show({
                title:'プレビュー',
                msg: 'プレビューファイルURL取得に失敗しました',
                buttons: Ext.Msg.OK
        });
        return;
    }    
    */
    
    var html_url = 'preview/Preview.html';
    return html_url;
}



