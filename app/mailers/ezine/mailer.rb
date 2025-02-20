class Ezine::Mailer < ActionMailer::Base
  # Deliver a verification e-mail to the entry.
  #
  # 購読申し込みに対して確認メールを配信する。
  #
  # @param [Ezine::Entry] entry
  def verification_mail(entry)
    @entry = entry
    @node = Ezine::Node::Page.find entry.node.id
    sender = Cms.sender_address(@node, @node.cur_site || @node.site)

    mail from: sender, to: entry.email, message_id: Cms.generate_message_id(@node.cur_site || @node.site)
  end

  # Deliver Ezine::Page as an e-mail.
  #
  # Ezine::Page を E-mail として配信する。
  #
  # @param [Ezine::Page] page
  # @param [Ezine::Member, Ezine::TestMember] member
  def page_mail(page, member)
    @page = page
    @member = member
    @node = Cms::Node.find page.parent.id
    sender = Cms.sender_address(@node, @node.cur_site || @node.site)

    mail from: sender, to: member.email, message_id: Cms.generate_message_id(@node.cur_site || @node.site) do |format|
      case member.email_type
      when "text"
        format.text
      when "html"
        # send multipart mail.
        # format order is important. text is first, then html is last
        # see: http://monmon.hatenablog.com/entry/2015/02/02/141722
        format.text
        format.html if @page.html.present?
      else
        # default
        format.text
      end
    end
  end
end
