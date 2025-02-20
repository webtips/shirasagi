module Cms::Model::Page
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Content
  include Cms::RedirectPage
  include Cms::Reference::Layout

  included do
    include Cms::Model::PageDiscriminatorRetrieval

    class_variable_set(:@@_show_path, nil)

    define_model_callbacks :generate_file
    define_model_callbacks :remove_file
    define_model_callbacks :rename_file

    store_in collection: "cms_pages"
    set_permission_name "cms_pages"

    index({ updated: -1 })

    #text_index :name, :html

    self.default_released_type = SS.config.cms.default_released_type.presence || "same_as_updated"

    attr_accessor :window_name

    field :route, type: String, default: ->{ "cms/page" }
    field :size, type: Integer

    embeds_ids :categories, class_name: "Cms::Node"

    permit_params category_ids: []

    after_save :rename_file, if: ->{ @db_changes }
    after_save :generate_file, if: ->{ @db_changes }
    after_save :remove_file, if: ->{ @db_changes && @db_changes["state"] && !public? }
    after_save :new_size_input, if: ->{ @db_changes }
    after_destroy :remove_file

    template_variable_handler(:categories, :template_variable_handler_categories)

    liquidize do
      export as: :categories do
        categories.and_public.order_by(order: 1, name: 1)
      end
    end
  end

  def preview_path
    (@cur_site || site).then do |s|
      s.subdir ? "#{s.subdir}/#{filename}" : filename
    end
  end

  def mobile_preview_path
    (@cur_site || site).then do |s|
      ::File.join(s.subdir || "", s.mobile_location, filename).gsub(/^\//, '')
    end
  end

  def generate_file(opts = {})
    return false unless serve_static_file?
    return false unless public?
    return false unless public_node?
    return false if (@cur_site || site).generate_locked?
    run_callbacks :generate_file do
      controller = Cms::Agents::Tasks::PagesController.new
      controller.instance_variable_set(:@task, opts[:task]) if opts[:task].present?
      updated = controller.generate_page(self)
      Cms::PageRelease.release(self) if opts[:release] != false
      updated
    end
  end

  def remove_file
    run_callbacks :remove_file do
      Fs.rm_rf path
      Cms::PageRelease.close(self)
    end
  end

  def rename_file
    return unless @db_changes["filename"]
    return unless @db_changes["filename"][0]

    src = "#{(@cur_site || site).path}/#{@db_changes['filename'][0]}"
    dst = "#{(@cur_site || site).path}/#{@db_changes['filename'][1]}"
    dst_dir = ::File.dirname(dst)

    run_callbacks :rename_file do
      Fs.mkdir_p dst_dir unless Fs.exist?(dst_dir)
      Fs.mv src, dst if Fs.exist?(src)
      Cms::PageRelease.close(self, @db_changes['filename'][0])
    end
  end

  def validate_destination_filename(dst)
    dst_dir = ::File.dirname(dst).sub(/^\.$/, "")

    return errors.add :filename, :empty if dst.blank?
    return errors.add :filename, :invalid if dst !~ /^([\w\-]+\/)*[\w\-]+(#{::Regexp.escape(fix_extname)})?$/
    return errors.add :base, :branch_page_can_not_move if self.try(:branch?)

    return errors.add :base, :same_filename if filename == dst
    return errors.add :filename, :taken if Cms::Page.site(@cur_site || site).where(filename: dst).first
    return errors.add :base, :exist_physical_file if Fs.exist?("#{(@cur_site || site).path}/#{dst}")

    if dst_dir.present?
      dst_parent = Cms::Node.site(@cur_site || site).where(filename: dst_dir).first

      return errors.add :base, :not_found_parent_node if dst_parent.blank?

      allowed = dst_parent.allowed?(:read, @cur_user, site: @cur_site)
      return errors.add :base, :not_have_parent_read_permission unless allowed
    elsif route != "cms/page"
      return errors.add :base, :not_cms_page_in_root
    end
  end

  def move(dst)
    validate_destination_filename(dst)
    if is_a?(Cms::Addon::EditLock)
      errors.add :base, :locked, user: lock_owner.long_name if locked?
    end
    return false unless errors.empty?

    src = url
    self.cur_node = nil
    self.filename = dst
    self.basename = nil
    if is_a?(Cms::Addon::EditLock)
      remove_attribute(:lock_owner_id) if has_attribute?(:lock_owner_id)
      remove_attribute(:lock_until) if has_attribute?(:lock_until)
    end
    result = save
    if result && SS.config.cms.replace_urls_after_move
      Cms::Page::MoveJob.bind(site_id: @cur_site, user_id: @cur_user).perform_later(src: src, dst: url)
    end
    result
  end

  # returns admin side show path
  def private_show_path(*args)
    model = self.class.name.underscore.sub(/^.+?\//, "")
    options = args.extract_options!
    methods = []
    if parent.blank?
      options = options.merge(site: cur_site || site, id: self)
      methods << "cms_#{model}_path"
    else
      options = options.merge(site: cur_site || site, cid: parent, id: self)
      if respond_to?(:route)
        route = self.route
        route = /cms\//.match?(route) ? "node_page" : route.tr("/", "_")
        methods << "#{route}_path"

        klass = self.route.camelize.constantize rescue nil
        method = klass ? klass.class_variable_get(:@@_show_path) : nil
        methods << "#{method}_path" if method
      end
      methods << "node_#{model}_path"
    end

    helper_mod = Rails.application.routes.url_helpers
    methods.each do |method|
      path = helper_mod.send(method, *args, options) rescue nil
      return path if path.present?
    end

    nil
  end

  def sort_options
    %w(updated_desc updated_asc released_desc released_asc).map { |k| [I18n.t("ss.options.sort.#{k}"), k] }
  end

  def attached_files
    if self.class.include?(Cms::Addon::Form::Page) && self.form
      self.form_files.to_a
    elsif self.class.include?(Cms::Addon::File)
      self.files.to_a
    else
      []
    end
  end

  def owned_files
    SS::File.where(owner_item_type: self.class.name, owner_item_id: id).to_a
  end

  def html_bytesize
    return 0 if !respond_to?(:html)
    html.to_s.bytesize
  end

  def owned_files_bytesize
    owned_files.sum(&:size)
  end

  def new_size_input
    self.set(size: (html_bytesize + owned_files_bytesize))
  end

  def get_linking_cond
    cond = []

    if self.respond_to?(:url) && self.respond_to?(:full_url)
      cond << { contains_urls: { '$in' => [ self.url, self.full_url ] } }
      cond << { form_contains_urls: { '$in' => [ self.url, self.full_url ] } }
    end

    if self.respond_to?(:files) && self.files.present?
      cond << { contains_urls: { '$in' => self.files.map(&:url) } }
    end

    if self.respond_to?(:related_page_ids)
      cond << { related_page_ids: self.id }
    end

    cond
  end
  module ClassMethods
    def and_linking_pages(item)
      where(:id.ne => item.id).where("$and" => [{ "$or" => item.get_linking_cond }])
    end
  end

  private

  def fix_extname
    ".html"
  end

  def template_variable_handler_categories(name, issuer)
    ret = categories.map do |category|
      html = "<span class=\"#{category.filename.tr('/', '-')}\">"
      html << "<a href=\"#{category.url}\">#{ERB::Util.html_escape(category.name)}</a>"
      html << "</span>"
      html
    end

    p = self.parent
    if p.try(:category_node?)
      ret << begin
        html = "<span class=\"#{p.filename.tr('/', '-')}\">"
        html << "<a href=\"#{p.url}\">#{ERB::Util.html_escape(p.name)}</a>"
        html << "</span>"
        html
      end
    end

    ret.join("\n").html_safe
  end

  module ClassMethods
    def custom_order(key)
      if key.start_with?('updated_')
        all.order_by(updated: key.end_with?('_asc') ? 1 : -1)
      elsif key.start_with?('released_')
        all.order_by(released: key.end_with?('_asc') ? 1 : -1)
      else
        all
      end
    end

    private

    def set_show_path(show_path)
      class_variable_set(:@@_show_path, show_path)
    end
  end
end
