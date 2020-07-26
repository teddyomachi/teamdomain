/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

function doPreviewWindowOpen(session_id){
    
    var preview_path = getLocalPreviewFile(session_id);
    
    var tabs = new Ext.Panel({ 
        width: 688, 
	height: 432, 
        scroll: true,
	items: [{ 
            html:'<iframe src="' + preview_path + '" width="688" height="432"></iframe>'
	}]
    });     
    
    var win = new Ext.Window({
        width: 700,
        height: 500,
        title: 'プレビュー',
        items:[tabs],
        buttons: [
            {text: '閉じる', id: 'closeButton', width: 100,
                handler: function(){
                    win.close();
                }
            }
        ]
    });

    

    win.show();
    
    
    
}

