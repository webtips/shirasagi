require 'spec_helper'

describe Cms::Form::DocsController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:name) { unique_id }
  let!(:form) { create(:cms_form, cur_site: site, sub_type: 'static') }
  let!(:col1) { create(:cms_column_select, cur_site: site, cur_form: form, order: 5) }
  let!(:col2) { create(:cms_column_radio_button, cur_site: site, cur_form: form, order: 6) }
  let!(:col3) { create(:cms_column_check_box, cur_site: site, cur_form: form, order: 7) }
  let!(:article_node) { create :article_node_page, cur_site: site }

  context 'basic crud' do
    before { login_cms_user }

    it do
      visit cms_form_dbs_path(site)
      click_on I18n.t('ss.links.new')

      # create db
      within 'form#item-form' do
        fill_in 'item[name]', with: name
        select form.name, from: "item[form_id]"
        select article_node.name, from: "item[node_id]"
        click_on I18n.t('ss.buttons.save')
      end
      form_db = Cms::FormDb.first

      # index
      visit cms_form_db_docs_path(site, form_db)
      click_on I18n.t('ss.links.new')

      # create
      within "#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[column_values][0][value]", with: col1.select_options[0]
        fill_in "item[column_values][1][value]", with: col2.select_options[1]
        fill_in "item[column_values][2][value]", with: col3.select_options[2]
        click_on I18n.t("ss.buttons.save")
      end

      wait_for_notice I18n.t("ss.notice.saved")
      expect(Article::Page.all.count).to eq 1

      # edit
      click_on I18n.t('ss.links.edit')
      within "#item-form" do
        fill_in "item[name]", with: name
        click_on I18n.t("ss.buttons.save")
      end

      # delete
      click_on I18n.t('ss.links.delete')
      within 'form' do
        click_on I18n.t('ss.buttons.delete')
      end

      wait_for_notice I18n.t("ss.notice.deleted")
      expect(Article::Page.all.count).to eq 0
    end
  end
end
