/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */


Ext.define('TeamDomain.store.ArchivedFolderDataStore', {
    extend: 'Ext.data.Store',
    requires: [
        'TeamDomain.model.ArchivedData'
    ],
    constructor: function (cfg) {
        var me = this;
        cfg = cfg || {};
        me.callParent([Ext.apply({
                model: 'TeamDomain.model.ArchivedData',
                storeId: 'ArchivedData',
                autoLoad:true,
                proxy: {
                    type: 'ajax',
                    url: 'spin/ArchivedData.sfl',
                    reader: {
                        type: 'json',
                        root: 'files'
                    }
                },
                listeners: {
                }
            }, cfg)]);
    }
});