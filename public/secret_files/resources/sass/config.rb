# $ext_path: This should be the path of the Ext JS SDK relative to this file
$ext_path = "../../../ext"

# sass_path: the directory your Sass files are in. THIS file should also be in the Sass folder
# Generally this will be in a resources/sass folder
# <root>/resources/sass
sass_path = File.dirname(__FILE__)

# css_path: the directory you want your CSS files to be.
# Generally this is a folder in the parent directory of your Sass files
# <root>/resources/css
# sass_pathディレクトリの親に戻り、その配下のcssフォルダの位置をcss_pathとする。
css_path = File.join(sass_path, "..", "css")

# output_style: The output style for your compiled CSS
# nested, expanded, compact, compressed
# More information can be found here http://sass-lang.com/docs/yardoc/file.SASS_REFERENCE.html#output_style
output_style = :nested

# We need to load in the Ext4 themes folder, which includes all it's default styling, images, variables and mixins
# 以下によって、2行目で指定したExt JSのSDK配下のExt 4 themesをロードする
# line 77, ../../../ext/resources/themes/stylesheets/ext4/default/core/_reset.scss
# 上記を分解すると以下の通りとなる。(ここまでは、このファイルにて指定した通りである。)
# ../../../ext/resources/themes/
# /stylesheets/ext4/default/core/_reset.scss
load File.join(File.dirname(__FILE__), $ext_path, 'resources', 'themes')
