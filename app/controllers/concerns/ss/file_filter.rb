module SS::FileFilter
  extend ActiveSupport::Concern
  include SS::SanitizerFilter

  included do
    # used at Facility::Apis::TempFilesController
    cattr_accessor :only_image, instance_accessor: false
  end

  private

  def append_view_paths
    append_view_path "app/views/ss/crud/files"
    super
  end

  def set_last_modified
    response.headers["Last-Modified"] = CGI::rfc1123_date(@item.updated.in_time_zone)
  end

  public

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if @item.in_files.blank?
      @item.errors.add :in_files, :blank
      render_create false
      return
    end

    if self.class.only_image && !@item.image?
      @item.errors.add :in_file, :image
      render_create false
      return
    end

    def @item.to_json
      saved_files.to_json({ methods: %i[humanized_name image? basename extname url thumb_url] })
    end
    render_create @item.save_files, location: { action: :index }
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if @item.in_file.blank? && @item.in_data_url.present?
      media_type, _, data = SS::DataUrl.decode(@item.in_data_url)
      raise '400' if @item.content_type != media_type

      tmp_file = Fs::UploadedFile.new('ss_file')
      tmp_file.original_filename = @item.filename
      tmp_file.content_type = @item.content_type
      tmp_file.binmode
      tmp_file.write(data)
      tmp_file.rewind

      begin
        @item.in_file = tmp_file
        render_update @item.update
      ensure
        tmp_file.close
      end
    else
      render_update @item.update
    end
  end

  def view
    set_item
    set_last_modified

    if @item.image? && request.xhr?
      render template: "view", layout: "ss/ajax"
      return
    end

    if Fs.mode == :file && Fs.file?(@item.path)
      send_file @item.path, type: @item.content_type, filename: @item.filename,
                disposition: :inline, x_sendfile: true
    else
      send_enum @item.to_io, type: @item.content_type, filename: @item.filename,
                disposition: :inline
    end
  end

  def thumb
    set_item
    set_last_modified

    if @item.try(:thumb)
      if Fs.mode == :file && Fs.file?(@item.thumb.path)
        send_file @item.thumb.path, type: @item.thumb.content_type, filename: @item.thumb.filename,
          disposition: :inline, x_sendfile: true
      else
        send_enum @item.thumb.to_io, type: @item.thumb.content_type, filename: @item.thumb.filename,
          disposition: :inline
      end
    else
      converter = SS::ImageConverter.open(@item.path)
      converter.resize_to_fit!

      send_enum converter.to_enum, type: @item.content_type, filename: @item.filename, disposition: :inline
      converter = nil
    end
  rescue => e
    raise if e.to_s.numeric?
    raise "500"
  ensure
    if converter
      converter.close rescue nil
    end
  end

  def download
    set_item
    set_last_modified

    if Fs.mode == :file && Fs.file?(@item.path)
      send_file @item.path, type: @item.content_type, filename: @item.download_filename,
        disposition: :attachment, x_sendfile: true
    else
      send_enum @item.to_io, type: @item.content_type, filename: @item.download_filename,
        disposition: :attachment
    end
  end

  def resize
    set_item
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    return if request.get?

    resizer = SS::ImageResizer.new get_params
    render_update resizer.resize(@item), { template: "resize" }
  end

  def contrast_ratio
    foreground_color = params[:f].to_s
    background_color = params[:b].to_s

    raise "400" if foreground_color.blank? || background_color.blank?

    ret = SS::ColorContrast.from_css_color(foreground_color, background_color)
    raise "400" if ret.blank?

    render json: { contrast_ratio: ret, contrast_ratio_human: ret.round(2).to_s }
  end
end
