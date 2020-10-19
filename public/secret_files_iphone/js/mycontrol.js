prepareData: function(data) {
var lock_check = "";
if (data.lock === 0) { lock_check = "small_icon/no_locked.png";}
if (data.lock === 1) { lock_check = "small_icon/my_locked.png";}
if (data.lock === 2) { lock_check = "small_icon/locked.png";}
if (data.lock === 4) { lock_check = "small_icon/sco.png";}
if (data.lock === 8) { lock_check = "small_icon/eco.png";}

var fileSizeUpper = data.file_size_upper;
var fileSize      = data.file_size;
var size          = fileSizeUpper * Math.pow(2, 31) + fileSize;
var rounded_size;

if (size === "" || size == 0) {
	rounded_size = "-";
} else if (size < 1024) {
	rounded_size = size + " B";
} else if (size < 1048576) {
	rounded_size = (Math.round(size / 1024)) + " KB";
} else if (size < 1073741824) {
	rounded_size = (Math.round(((size*10) / 1048576))/10) + " MB";
} else if (size < 1099511627776) {
	rounded_size = (Math.round(((size*100) / 1073741824))/100) + " GB";
} else if (size < 1125899906842624) {
	rounded_size = (Math.round(((size*100) / 1099511627776))/100) + " TB";
} else {
	rounded_size = (Math.round(((size*100) / 1125899906842624))/100) + " PB";
}

Ext.apply(data, {
	shortName: Ext.util.Format.ellipsis(data.file_name, 20),
	lock_check_img: lock_check,
	file_disp_size: rounded_size
});

return data;
}