module Member::Addon::LoginLink
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :login_link_url, type: String
    permit_params :login_link_url
    validates :login_link_url, "sys/trusted_url" => true
  end

  def find_login_link_url
    ret = self.login_link_url.presence
    return ret if ret

    ret = self.parent.redirect_url.presence rescue nil
    return ret if ret

    ret = Member::Node::Mypage.site(@cur_site || self.site).first.url rescue nil
    return ret if ret
  end
end
