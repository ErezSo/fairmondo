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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairmondo. If not, see <http://www.gnu.org/licenses/>.
#

class UserObserver < ActiveRecord::Observer
  def before_save user

    if ( user.bank_account_number_changed? ||  user.bank_code_changed? )
      check_bank_details( user.id, user.bank_account_number, user.bank_code )
    end
    if ( user.iban_changed? || user.bic_changed? )
      check_iban_bic( user.id, user.iban, user.bic )
    end
  end

  def after_update user
    # this should update the users data with fastbill after the user edits his data
    if user.fastbill_profile_update && user.has_fastbill_profile?
      FastbillUpdateUserWorker.perform_async user.id
    end

    if user.newsletter_changed?
      cr = CleverreachAPI
      user.newsletter? ? cr.add(user) : cr.remove(user)
    end

    # deactivates and closes all active articles of banned user
    if user.banned_changed? && user.banned && user.articles.active.limit(1).any?
      user.articles.active.find_each do |article|
        article.deactivate
        article.close
      end
    end
  end

  def after_create user
    CleverreachAPI.add(user) if user.newsletter?
  end

  def check_bank_details id, bank_account_number, bank_code
    begin
      user = User.find(id)
      user.update_column( :bankaccount_warning, !KontoAPI::valid?( :ktn => bank_account_number, :blz => bank_code ) )
    rescue
    end
  end

  def check_iban_bic id, iban, bic
    begin
      user = User.find(id)
      user.update_column( :bankaccount_warning, !KontoAPI::valid?( :iban => iban, :bic => bic ) )
    rescue
    end
  end
end
