#
# Farinopoly - Fairnopoly is an open-source online marketplace.
# Copyright (C) 2013 Fairnopoly eG
#
# This file is part of Farinopoly.
#
# Farinopoly is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Farinopoly is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Farinopoly.  If not, see <http://www.gnu.org/licenses/>.
#
require 'spec_helper'
include Warden::Test::Helpers

describe 'Transaction' do

  let(:transaction) { FactoryGirl.create :transaction }
  let(:article) { transaction.article }
  let(:seller) { transaction.article.seller }
  let(:user) { FactoryGirl.create :user }

  describe "#edit" do

    context "for a logged-in user" do
      before { login_as user }

      it "should do show the correct data and fields" do
        visit edit_transaction_path transaction

        page.should have_content I18n.t 'transaction.edit.heading'

        # Should display article data
        page.should have_content article.title
        page.should have_content seller.fullname

        # Should display shipping selection
        page.should have_content I18n.t 'transaction.edit.transport'

        # Should display payment selection
        page.should have_content I18n.t 'transaction.edit.payment'

        # Should display Impressum
        page.should have_content I18n.t 'transaction.edit.terms', name: seller.fullname

        # Should display declaration of revocation
        page.should have_content I18n.t 'transaction.edit.cancellation', name: seller.fullname

        # Should display buyer's address
        page.should have_content I18n.t 'transaction.edit.address'
        page.should have_content user.fullname
        page.should have_content user.street
        page.should have_content user.zip
        page.should have_content user.city
        page.should have_content user.country

        # Should display 'conitnue' button
        page.should have_button I18n.t 'common.actions.continue'
      end
    end

    context "for a logged-out user" do
      it "should not yet be accessible" do
        visit edit_transaction_path transaction
        page.should have_content "Login"
      end
    end
  end
end