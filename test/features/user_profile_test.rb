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

feature 'User profile page' do
  scenario 'user visits his profile' do
    @user = FactoryGirl.create :user
    login_as @user
    visit user_path(@user)
    page.must_have_content('Profil bearbeiten')
    page.must_have_content('Sammlungen')
    page.wont_have_content('Admin')
  end

  scenario 'user looks at his profile' do
    @user = FactoryGirl.create :user
    login_as @user
    visit user_path(@user)
    page.must_have_content @user.nickname
  end

  scenario 'guest visits another users profile through an article' do
    article = FactoryGirl.create :article
    visit article_path article
    find('.User-image a').click
    current_path.must_equal user_path article.seller
  end

  scenario "guests visits a legal entity's profile page" do
    user = FactoryGirl.create :legal_entity
    visit user_path user
    click_link I18n.t 'users.headers.legal_info'
    current_path.must_equal user_path(user)
    page.must_have_content('Impressum und Kontakt')
  end
end

feature 'contacting users' do
  before do
    receiver = FactoryGirl.create :legal_entity
    sender   = FactoryGirl.create :user
    login_as sender
    visit user_path receiver

    within('.user-type') do
      click_link I18n.t 'users.actions.contact'
    end
  end

  scenario 'user contacts seller' do
    within('#contact_form') do
      fill_in 'contact_form[text]', with: 'foobar'
      click_button I18n.t('article.show.contact.action')
    end
    page.must_have_content I18n.t 'users.profile.contact.success_notice'
  end
end
