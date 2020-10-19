/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */


function CheckSelectedClass(target_id, index, element)
{
    var target_table = Ext.get(target_id).dom.childNodes[0];
    var target_tbody;
    var target_row;
    var ctrl_key = element.ctrlKey;
    var click_type = element.type;
    if (typeof target_table !== "undefined")
    {
        target_tbody = target_table.childNodes[0];
        if (typeof target_tbody !== "undefined")
        {
            target_row = target_tbody.rows[index + 1];
            if (typeof target_row !== "undefined")
            {
                if (ctrl_key === false)
                {
                    if (click_type === "click")
                    {
                        var row_length = target_tbody.rows.length;
                        for (var i = 1; i < row_length; i++)
                        {
                            var classlist = target_tbody.rows[i].classList;
                            var classlist_length = classlist.length;
                            for (var j = 0; j < classlist_length; j++)
                            {
                                if (classlist[j] === "x-grid-row-selected")
                                {
                                    classlist.remove("x-grid-row-selected");
                                }
                                if (classlist[j] === "x-grid-row-focused")
                                {
                                    classlist.remove("x-grid-row-focused");
                                }
                            }
                        }
                    }
                    else
                    {
                        var intersection;
                        var activeData = Ext.getCmp('activeData').getForm().getFieldValues();
                        var grid = Ext.getCmp(TargetComp);
                        var model = grid.getSelectionModel();

                        if (!model.hasSelection())
                        {
                            return -1;
                        }

                        var selCnt = model.getCount();
                        var records = model.getSelection();
                        intersection = CheckSelectedTarget(activeData, intersection, selCnt, records);
                        if (intersection.length < 1)
                        {
                            var row_length = target_tbody.rows.length;
                            for (var i = 1; i < row_length; i++)
                            {
                                var classlist = target_tbody.rows[i].classList;
                                var classlist_length = classlist.length;
                                for (var j = 0; j < classlist_length; j++)
                                {
                                    if (classlist[j] === "x-grid-row-selected")
                                    {
                                        classlist.remove("x-grid-row-selected");
                                    }
                                    if (classlist[j] === "x-grid-row-focused")
                                    {
                                        classlist.remove("x-grid-row-focused");
                                    }
                                }
                            }
                        }
                    }
                }
                target_row.classList.add("x-grid-row-selected", "x-grid-row-focused");
            } else
            {
                console.log('target_row is undefined');
            }
        } else
        {
            console.log('target_tbody is undefined');
        }
    } else
    {
        console.log('target_table is undefined');
    }
}

function CheckSelectedMove(element, target)
{
    if (target.xtype === "gridview")
    {
        var click_type = element.type;
        if (click_type === "contextmenu")
        {
            var intersection;
            var activeData = Ext.getCmp('activeData').getForm().getFieldValues();
            var grid = Ext.getCmp("listGridPanelA");
            var model = grid.getSelectionModel();

            var selCnt = model.getCount();
            var records = model.getSelection();
            intersection = CheckSelectedTarget(activeData, intersection, selCnt, records);

            if (intersection < 1)
            {
                var grid_view = grid.getView();
                var node_index = 0;
                node_index = Number(activeData.activeFolderA_current_file);
                grid_view.select(node_index);
            }
        }
    }
}

function SetActiveData(target, record, element, index)
{
    var target_id = element.currentTarget.id;
    var selected_data = record.data;
    var parent_writable_status;
    var original_place;
    var folder_name;
    var writable;
    var readable;

    if (target.xtype === "treeview")
    {
        parent_writable_status = selected_data.parent_writable_status;
        original_place = 'folder_tree';
        folder_name = selected_data.folder_name;
        writable = selected_data.folder_readable_status;
        readable = selected_data.folder_writable_status;
        Ext.getCmp('activeData').getForm().setValues({
            activeFolderA_current_folder: record.getId()
        });
    } else
    {
        parent_writable_status = selected_data.folder_writable_status;
        original_place = 'file_list';
        folder_name = selected_data.file_name;
        writable = selected_data.file_readable_status;
        readable = selected_data.file_writable_status;
        Ext.getCmp('activeData').getForm().setValues({
            activeFolderA_current_file: record.index
        });
    }

    Ext.getCmp('activeData').getForm().setValues({
        activeFolderA_name: folder_name,
        activeFolderA_hash: selected_data.hash_key,
        activeFolderA_readable: readable,
        activeFolderA_writable: writable,
        activeFolderA_text: folder_name,
        activeFolderA_cont_location: selected_data.cont_location,
        activeFolderA_original_place: original_place,
        activeFolderA_owner: selected_data.owner,
        activeFolderA_parent_writable: parent_writable_status
    });
    if (selected_data.leaf === false)
    {
        Ext.getCmp('activeData').getForm().setValues({
            activeFolderA_file_type: 'folder'
        });
    } else
    {
        Ext.getCmp('activeData').getForm().setValues({
            activeFolderA_file_type: selected_data.file_type,
            activeFolderA_lock: selected_data.lock
        });
    }
    //CheckSelectedClass(target_id, index, element);
    CheckSelectedMove(element, target);
}

function CheckSelectedTarget(activeData, intersection, selCnt, records)
{

    var selected_record_array = [];
    var active_data_array = [];
    for (var i = 0; i < selCnt; i++)
    {
        selected_record_array.push(records[i].data.hash_key);
    }
    active_data_array.push(activeData.activeFolderA_hash);
    intersection = _.intersection(selected_record_array, active_data_array);
    return intersection;
}

function GetSeledtedData(this_session_id, rethash)
{
    var intersection;
    var activeData = Ext.getCmp('activeData').getForm().getFieldValues();
    var grid = Ext.getCmp(TargetComp);
    var model = grid.getSelectionModel();

    if (!model.hasSelection())
    {
        return -1;
    }

    var selCnt = model.getCount();
    var records = model.getSelection();
    intersection = CheckSelectedTarget(activeData, intersection, selCnt, records);
    if (intersection.length > 0)
    {
        var retdata_array = [];
        for (var i = 0; i < selCnt; i++)
        {
            var retdata = {};
            retdata.session_id = this_session_id;
            retdata.request_type = 'delete_folder';
            retdata.original_place = 'file_list';
            retdata.hash_key = records[i].data.hash_key;
            retdata.cont_location = records[i].data.cont_location;
            if (records[i].data.file_type === 'folder')
            {
                rethash.file_type = 'フォルダ';
                retdata.folder_writable_status = records[i].data.file_writable_status;
                retdata.folder_readable_status = records[i].data.file_readable_status;
                retdata.target_folder_writable = records[i].data.folder_writable_status;
                retdata.folder_name = records[i].data.file_name;
            } else
            {
                rethash.file_type = 'ファイル';
                retdata.file_writable_status = records[i].data.file_writable_status;
                retdata.lock = records[i].data.lock;
                retdata.file_name = records[i].data.file_name;
            }
            retdata_array.push(retdata);
        }
        rethash.selCnt = retdata_array.length;
        rethash.data = retdata_array;
    } else
    {
        var retdata = {};
        retdata.session_id = this_session_id;
        retdata.request_type = 'delete_folder';
        retdata.original_place = 'file_list';
        retdata.hash_key = activeData.activeFolderA_hash;
        retdata.cont_location = activeData.activeFolderA_cont_location;
        if (activeData.activeFolderA_file_type === 'folder')
        {
            rethash.file_type = 'フォルダ';
            retdata.folder_writable_status = activeData.activeFolderA_writable;
            retdata.folder_readable_status = activeData.activeFolderA_readable;
            retdata.target_folder_writable = activeData.activeFolderA_writable;
            retdata.folder_name = activeData.activeFolderA_name;
        } else
        {
            rethash.file_type = 'ファイル';
            retdata.file_writable_status = activeData.activeFolderA_writable;
            retdata.lock = activeData.activeFolderA_lock;
            retdata.file_name = activeData.activeFolderA_name;
        }
        var retdata_array = [];
        retdata_array.push(retdata);
        rethash.selCnt = retdata_array.length;
        rethash.data = retdata_array;
    }
    return rethash;
}

function GetParentNode(parent_node, store)
{
    var activeData = Ext.getCmp('activeData').getForm().getFieldValues();
    var current_folder_id = activeData.activeFolderA_current_folder;
    var parent_node = store.getNodeById(current_folder_id);
    return parent_node;
}