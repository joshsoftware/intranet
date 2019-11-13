# encoding: utf-8
#require 'carrierwave/processing/mime_types'
class FileUploader < CarrierWave::Uploader::Base
  #include CarrierWave::MimeTypes

  # Include RMagick or MiniMagick support:
  include CarrierWave::RMagick
  #include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file
  #storage :grid_fs
  # storage :fog
 # process :set_content_type
  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    # For Rails 3.1+ asset pipeline compatibility:
    #ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default_photo.gif"].compact.join('_'))
    "default_photo.gif"
  #
     #"/images/fallback/" + [thumb, "default_photo.png"].compact.join('_')
  end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  version :thumb, :if => :image? do
    process :resize_to_fit  => [100, 100]
  end

  version :medium, :if => :image? do
    process :resize_to_fit  => [255, 222]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(pdf jpg jpeg gif png doc xls xlsx odt)
  #   %w(jpg jpeg gif png)
  end
  
  def image?(new_file)
    new_file.content_type.start_with? 'image'
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
