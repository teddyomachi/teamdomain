require 'rubygems'
require 'rmagick'
require 'fileutils'

module ImageUtility
  
  class Thumbnail
    
    def self.generate_thumbnail_image source_file
      
      my_vfiles = '/usr2/teamdomain/spinvfs/root1/'
      my_thumbnail_images = '/usr2/teamdomain/spinvfs/root1_thumbnail/'
      image_source = my_vfiles + source_file
      unless File.exist? image_source
        return false
      end
      thumbnail_image = my_thumbnail_images + source_file + '.png'
      if File.exist? thumbnail_image
        return "thumbnail_image/" + source_file + '.png'
      else
        return "thumbnail_image/" + source_file + '.png'
#        return ''
      end

#      # サムネールの出力先
#      # @target_path = '/usr/local/www/rails/thumbnail'
#      target_path = my_thumbnail_images
#      #サムネール作成の基準日時（差分の単位は秒）
#      # @ago = Time.now - 60 * 60 * 24 * 19
#      #サムネールの解像度
#      w = 250.0
#      h = 190.0
#      r = 1.0 * w / h
#    
#      image = Magick::ImageList.new(image_source)
#      ratio = 1.0 * image.columns / image.rows
#      if ratio > r
#        image.resize!(h * ratio, h)
#        image.crop!(Magick::CenterGravity,w,h)
#      else
#        image.resize!(w, w / ratio)
#        image.crop!(Magick::CenterGravity,w,h)
#      end #=> end of 'ratio' check
#      fname = source_file.split('/')[-1]
#      target = thumbnail_image
#      target_dir = File::dirname(target)
#      unless File.exists?(target_dir)
#        FileUtils::mkdir_p(target_dir)
#      end
#      image.write(target)
#      return "thumbnail_image/" + source_file + '.png'
    end
    
    def self.generate_thumbnail(source_file,content_type_id_string)
    
#      _vfile = '/usr2/teamdomain/spinvfs/root1'
      # サムネールの出力先
      # @target_path = '/usr/local/www/rails/thumbnail'
      target_path = '/usr2/teamdomain/spinvfs/root1_thumbnail'
      #サムネール作成の基準日時（差分の単位は秒）
      # @ago = Time.now - 60 * 60 * 24 * 19
      #サムネールの解像度
      w = 250.0
      h = 190.0
      r = 1.0 * w / h
    
      if content_type_id_string =~ / video\// then
      else
      image = Magick::ImageList.new(source_file)
      ratio = 1.0 * image.columns / image.rows
      if ratio > r
        image.resize!(h * ratio, h)
        image.crop!(Magick::CenterGravity,w,h)
      else
        image.resize!(w, w / ratio)
        image.crop!(Magick::CenterGravity,w,h)
      end #=> end of 'ratio' check
      fname = source_file.split('/')[-1]
      target = "#{target_path}/#{fname}.png"
      target_dir = File::dirname(target)
      unless File.exists?(target_dir)
        FileUtils::mkdir_p(target_dir)
      end
      image.write(target)
      end #=> end of '.m4v' check
      return target
    end
    
    def self.generate_thumbnail_in_directory dirpath
      Dir.glob("#{dirpath}/*").each do |f|
        if File::ftype(f) == 'file' and
           ( `file -i #{f}` =~ / image\// or `file -i #{f}` =~ / video\// ) then
          c_type = `file -i #{f}`
      
          self.generate_thumbnail(f,c_type)    
      
        end
      end
    end
    
  end
end

