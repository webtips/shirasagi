class Gws::StaffRecord::GroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::StaffRecord::SettingFilter

  model Gws::StaffRecord::Group

  navi_view "gws/main/navi"

  before_action :set_year

  private

  def set_crumbs
    set_year
    @crumbs << ["#{@cur_year.name} " + t("mongoid.models.gws/staff_record/group"), gws_staff_record_groups_path]
  end

  public

  def index
    @items = @cur_year.yearly_groups.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def download
    items = @cur_year.yearly_groups.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site)

    @item = @model.new(fix_params)
    send_data @item.export_csv(items), filename: "staff_record_#{@cur_year.code}_groups_#{Time.zone.now.to_i}.csv"
  end

  def import
    return if request.get?

    @item = @model.new(get_params)
    result = @item.import_csv
    flash.now[:notice] = t("ss.notice.saved") if result
    render_create result, location: { action: :index }, render: { template: "import" }
  end
end
