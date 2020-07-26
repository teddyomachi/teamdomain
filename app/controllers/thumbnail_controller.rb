# coding: utf-8

require 'utilities/image_utilities'

class ThumbnailController < ApplicationController
  
  def thumbnail_generator
    ImageUtility::Thumbnail.generate_thumbnail_in_directory '/usr2/teamdomain/spinvfs/root1'
  end
  
  def thumbnail_view
    render request.headers['REQUEST_URI']
  end
  
end
