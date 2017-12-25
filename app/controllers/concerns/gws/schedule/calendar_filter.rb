module Gws::Schedule::CalendarFilter
  extend ActiveSupport::Concern

  included do
    prepend_view_path "app/views/gws/schedule/plans"
    menu_view "gws/schedule/main/menu"
    helper Gws::Schedule::PlanHelper
  end

  def popup
    set_item

    if @item.readable?(@cur_user) || @item.member?(@cur_user)
      render file: "popup", layout: false
    else
      render file: "popup_hidden", layout: false
    end
  end
end
