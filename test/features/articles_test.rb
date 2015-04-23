#
#
# == License:
# Fairmondo - Fairmondo is an open-source online marketplace.
# Copyright (C) 2013 Fairmondo eG
#
# This file is part of Fairmondo.
#
# Fairmondo is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairmondo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairmondo.  If not, see <http://www.gnu.org/licenses/>.
#
require_relative '../test_helper'

include Warden::Test::Helpers

feature 'Article creation' do
  before do
    @user = FactoryGirl.create :user
    login_as @user
  end

  scenario 'article creation with an invalid user should redirect with an error' do
    @user.standard_address.first_name = nil
    visit new_article_path
    current_path.must_equal edit_user_registration_path
    page.must_have_content I18n.t 'article.notices.incomplete_profile'
  end

  def fill_form_with_valid_article
    fill_in I18n.t('formtastic.labels.article.title'), with: 'Article title'

    within('#article_category_ids_input') do
      select Category.root.name, from: 'article_category_ids'
    end
    within('#article_condition_input') do
      choose 'article_condition_new'
    end

    fill_in I18n.t('formtastic.labels.article.price'), with: '5,00'

    if @user.is_a? LegalEntity
      fill_in I18n.t('formtastic.labels.article.basic_price'), with: '99,99'
      select I18n.t('enumerize.article.basic_price_amount.kilogram'), from: I18n.t('formtastic.labels.article.basic_price_amount')
      select 7, from: I18n.t('formtastic.labels.article.vat')
    end
    fill_in I18n.t('formtastic.labels.article.content'), with: 'Article content'
    check 'article_transport_pickup'
    fill_in 'article_transport_details', with: 'transport_details'
    check 'article_payment_cash'
    fill_in 'article_payment_details', with: 'payment_details'
  end

  scenario 'article and template creation with a valid user' do
    visit new_article_path
    page.must_have_content(I18n.t('article.titles.new'))

    fill_form_with_valid_article

    # social producer
    check 'article_fair'
    within('#article_fair_kind_input') do
      choose 'article_fair_kind_social_producer'
    end
    within('#article_social_producer_questionnaire_attributes_nonprofit_association_input') do
      choose 'article_social_producer_questionnaire_attributes_nonprofit_association_true'
    end
    check 'article_social_producer_questionnaire_attributes_nonprofit_association_checkboxes_youth_and_elderly'
    within('#article_social_producer_questionnaire_attributes_social_businesses_muhammad_yunus_input') do
      choose 'article_social_producer_questionnaire_attributes_social_businesses_muhammad_yunus_false'
    end
    within('#article_social_producer_questionnaire_attributes_social_entrepreneur_input') do
      choose 'article_social_producer_questionnaire_attributes_social_entrepreneur_false'
    end

    # Template
    fill_in 'article_article_template_name', with: 'template'
    assert_difference 'Article.unscoped.count', 2 do
      click_button I18n.t('article.labels.continue_to_preview')
    end

    current_path.must_equal article_path Article.first
  end

  scenario 'article creation with a quantity higher than 1' do
    visit new_article_path
    fill_form_with_valid_article

    # Increase Quantity
    fill_in 'article_quantity', with: '2'

    assert_difference 'Article.unscoped.count', 1 do
      click_button I18n.t('article.labels.continue_to_preview')
    end
  end

  scenario 'empty friendly_percent_organisation with friendly_percent' do
    visit new_article_path
    fill_form_with_valid_article
    # choose friendly_percent
    select('35', from: 'article_friendly_percent')

    assert_no_difference 'Article.unscoped.count'  do
      click_button I18n.t('article.labels.continue_to_preview')
    end
  end

  scenario 'get article from template' do
    template = FactoryGirl.create :article_template, seller: @user
    visit new_article_path template: { article_id: template.id }
    page.must_have_content I18n.t('template.notices.applied', name: template.article_template_name)
  end

  scenario 'new private user wants to use bank_transfer for article that costs more than 100Euro' do
    @user = FactoryGirl.create :private_user, created_at: Time.now
    login_as @user
    visit new_article_path
    fill_form_with_valid_article
    fill_in 'article_price', with: '150'
    check 'article_payment_bank_transfer'
    click_button I18n.t('article.labels.continue_to_preview')
    page.must_have_content I18n.t('article.form.errors.bank_transfer_not_allowed')
  end
end

feature 'Article activation for private users' do
  scenario 'private user adds goods for more than 500000' do
    user = FactoryGirl.create :private_user
    FactoryGirl.create :article, seller: user, price_cents: 600000
    article = FactoryGirl.create :preview_article, user_id: user.id
    login_as user
    visit article_path(article)
    click_button I18n.t('article.labels.submit_free')
    page.must_have_content I18n.t('article.notices.max_limit')
    article.active?.must_equal false
  end

  scenario 'private user with a bonus if 200000 adds goods for more than 500000' do
    user = FactoryGirl.create :private_user, max_value_of_goods_cents_bonus: 200000
    FactoryGirl.create :article, seller: user, price_cents: 600000
    article = FactoryGirl.create :preview_article, seller: user
    login_as user
    visit article_path(article)
    click_button I18n.t('article.labels.submit_free')
    page.wont_have_content I18n.t('article.notices.max_limit')
    current_path.must_equal article_path article
    article.reload.active?.must_equal true
  end
end

feature 'Article activation for legal entities' do
  let(:user) { FactoryGirl.create :legal_entity }
  let(:article) { FactoryGirl.create :preview_article, seller: user }

  scenario 'legal entity adds goods for more than 5000000' do
    6.times { FactoryGirl.create :article, seller: user, price_cents: 1000000 }
    login_as user
    visit article_path(article)
    click_button I18n.t('article.labels.submit')
    page.must_have_content I18n.t('article.notices.max_limit')
    article.active?.must_equal false
  end

  scenario "user doesn't accept TOS" do
    login_as user
    visit article_path(article)
    click_button I18n.t('article.labels.submit')
    page.must_have_content I18n.t('article.notices.activation_failed')
    current_path.must_equal article_path article
    article.reload.active?.must_equal false
  end
end

feature 'Article search' do
  scenario 'should show the page with search results' do
    ArticlesIndex.reset!
    visit root_path
    fill_in 'search_input', with: 'chunky bacon'
    FactoryGirl.create :article, :index_article, title: 'chunky bacon'

    click_button 'Suche'
    page.must_have_link 'chunky bacon'
  end

  scenario 'elastic search server disconnects' do
    Chewy::Query.any_instance.stubs(:to_a).raises(Faraday::ConnectionFailed.new('test')) # simulate connection error so that we dont have to use elastic
    visit root_path
    click_button 'Suche'
  end
end

feature 'Update Articles' do
  before do
    user = FactoryGirl.create :user
    @article = FactoryGirl.create :preview_article, seller: user
    login_as user
    visit edit_article_path @article
  end

  scenario 'user edits title' do
    fill_in 'article_title', with: 'foobar'
    click_button I18n.t 'article.labels.continue_to_preview'

    @article.reload.title.must_equal 'foobar'
    current_path.must_equal article_path @article
  end

  scenario 'refills the stock' do
    @article.update_attribute(:quantity_available, 0)
    fill_in 'article_quantity', with: 20
    click_button I18n.t 'article.labels.continue_to_preview'

    @article.reload.quantity.must_equal 20
    @article.quantity_available_without_article_state.must_equal 20
    current_path.must_equal article_path @article
  end
end

feature 'report Articles' do
  before do
    user = FactoryGirl.create :user
    login_as user
    visit article_path FactoryGirl.create :article
  end

  scenario 'user reports feedback' do
    fill_in 'feedback_text', with: 'foobar'
    click_button I18n.t 'article.actions.report'

    page.must_have_content I18n.t 'article.actions.reported'
  end

  scenario 'user reports blank feedback'  do
    fill_in 'feedback_text', with: ''
    click_button I18n.t 'article.actions.report'
    page.must_have_content I18n.t 'activerecord.errors.models.feedback.attributes.text.blank'
  end
end

feature 'contacting sellers' do
  before do
    user = FactoryGirl.create :user
    login_as user
    visit article_path FactoryGirl.create :article, :with_private_user
  end

  scenario 'user contacts seller' do
    fill_in 'contact_form[text]', with: 'foobar'
    click_button I18n.t('article.show.contact.action')

    page.must_have_content I18n.t 'users.profile.contact.success_notice'
  end
end

feature 'Article buyer actions' do
  setup do
    @article = FactoryGirl.create :article
  end
  scenario 'user clicks buy button' do
    user = FactoryGirl.create :user
    login_as user

    visit article_path @article
    click_button I18n.t 'common.actions.to_cart'
    current_path.must_equal article_path @article
  end

  scenario 'guest clicks buy button' do
    visit article_path @article
    click_button I18n.t 'common.actions.to_cart'
    current_path.must_equal article_path @article
  end
  # add more
end

feature 'Article view for guest users' do
  before do
    @seller = FactoryGirl.create :user, type: 'LegalEntity'
    @article_conventional = FactoryGirl.create :no_second_hand_article, seller: @seller
  end

  scenario 'user visits an article' do
    visit article_path @article_conventional
    page.must_have_link('Transparency International', href: 'http://www.transparency.de/')
  end

  scenario 'user visits article list' do
    visit articles_path
  end

  scenario 'user opens a conventional article from a user that is whitelisted' do
    EXCEPTIONS_ON_FAIRMONDO['no_fair_alternative']['user_ids'] = [@seller.id]
    visit article_path @article_conventional
    page.assert_no_selector('div.fair_alternative')
  end
end

feature 'other Articles of the same user' do
  setup do
    seller = FactoryGirl.create :user
    ArticlesIndex.reset!
    @article = FactoryGirl.create :article, :index_article, seller: seller
    @article_active = FactoryGirl.create :article, :index_article, seller: seller
    @article_locked = FactoryGirl.create :preview_article, :index_article, seller: seller
  end

  scenario 'user wants to see other articles of the same seller' do
    visit article_path @article
    page.must_have_link('', href: article_path(@article_active))
    page.wont_have_link('', href: article_path(@article_locked))
  end
end
