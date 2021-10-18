require 'spec_helper'

describe "article_node_form_table", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:name) { "name-#{unique_id}" }
  let!(:basename) { "basename-#{unique_id}" }
  let!(:layout) { create_cms_layout }
  let!(:form) { create(:cms_form, cur_site: site, sub_type: 'static') }
  let!(:col1) { create(:cms_column_select, cur_site: site, cur_form: form, order: 5) }
  let!(:col2) { create(:cms_column_radio_button, cur_site: site, cur_form: form, order: 6) }
  let!(:col3) { create(:cms_column_check_box, cur_site: site, cur_form: form, order: 7) }
  let!(:article_node) { create :article_node_page, cur_site: site }

  context "basic crud" do
    before { login_cms_user }

    it do
      visit cms_nodes_path(site: site)
      click_on I18n.t("ss.links.new")

      within "#item-form" do
        within "#addon-basic" do
          wait_cbox_open do
            click_on I18n.t("ss.links.change")
          end
        end
      end
      wait_for_cbox do
        within ".mod-article" do
          click_on I18n.t("cms.nodes.article/form_table")
        end
      end
      within "#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[basename]", with: basename
        select layout.name, from: "item[layout_id]"
        select form.name, from: "item[form_id]"
        select article_node.name, from: "item[node_id]"
        click_on I18n.t("ss.buttons.save")
      end

      wait_for_notice I18n.t("ss.notice.saved")
      expect(Article::Node::FormTable.all.count).to eq 1

      # show
      expect(first('#addon-basic')).to have_text(name)

      # edit
      click_on I18n.t("ss.links.edit")
      within "#item-form" do
        click_on I18n.t("ss.buttons.save")
      end

      wait_for_notice I18n.t("ss.notice.saved")
      expect(first('#addon-basic')).to have_text(name)

      # public node
      node = Article::Node::FormTable.first
      visit node.full_url
      expect(find('table caption')).to have_text(name)
    end
  end
end
