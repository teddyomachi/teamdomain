/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */


function CheckLocalFlag(target, flag)
{
    if(target === 'folder')
    {
        var folderA = Ext.getCmp('folderPanelA');
        var folderB = Ext.getCmp('folderPanelB');
        //Ext.create('TeamDomain.view.tempDsp').show();
        if(flag === 'local')
        {
            folderA.hide();
            folderB.show();
        }
        else
        {
            folderA.show();
            folderB.hide();
        }
    }
    else
    {
        if(flag === 'local')
        {

        }
        else
        {
            
        }
    }
}