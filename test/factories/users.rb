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
require 'ffaker'

FactoryGirl.define do
  factory :user, aliases: [:seller, :buyer, :sender, :rated_user], class: %w(PrivateUser LegalEntity).sample do
    email       { Faker::Internet.email }
    password 'password'
    sequence(:nickname) { |n| "#{Faker::Internet.user_name}#{n}" }
    legal '1'

    about_me    { Faker::Lorem.paragraph(rand(7) + 1) }
    terms    { Faker::Lorem.paragraph(rand(7) + 1) }
    cancellation    { Faker::Lorem.paragraph(rand(7) + 1) }
    about    { Faker::Lorem.paragraph(rand(7) + 1) }

    confirmed_at Time.now

    bank_code { rand(99999999).to_s.center(8, rand(9).to_s) }
    bank_account_number { rand(99999999).to_s.center(8, rand(9).to_s) }
    bank_account_owner Faker::Name.name
    bank_name Faker::Name.name

    iban { %w(DE AT CH).sample + rand(99999999999999999999).to_s.center(20, rand(9).to_s) }
    bic { %w(ABCDEF ZJFBLO TNAPIT EMLOAB).sample + rand(99).to_s.center(2, rand(9).to_s) }

    direct_debit true
    uses_vouchers false
    created_at { 2.month.ago }

    seller_state 'standard_seller'
    buyer_state 'standard_buyer'

    unified_transport_provider 'DHL'
    unified_transport_price_cents 2000
    unified_transport_maximum_articles 12

    transient do
      create_standard_address true
    end

    after(:create) do |user, evaluator|
      if evaluator.create_standard_address
        address = FactoryGirl.create(:address, user: user)
        user.update_attribute(:standard_address_id, address.id)
      end
    end

    trait :missing_bank_data do
      bank_code ''
      bank_account_number ''
      bank_account_owner ''
      bank_name ''
      iban ''
      bic ''
    end

    factory :admin_user do
      admin true
    end

    factory :non_german_user do
      country Faker::Address.country
    end

    factory :private_user, class: 'PrivateUser' do
      factory :incomplete_user do
        transient do
          create_standard_address false
        end
      end
    end

    factory :legal_entity, class: 'LegalEntity' do
      factory :legal_entity_with_fixture_address do
        create_standard_address false
        standard_address { FactoryGirl.create :fixture_address }
      end

      factory :fixture_legal_entity do
        email 'test@test.com'
        password 'password'
        nickname 'testuser'
        create_standard_address false
        standard_address { FactoryGirl.create :fixture_address }
        bank_code '50010517'
        bank_account_number '0648489890'
        bank_account_owner 'Max Mustermann'
        bank_name 'GLS-Bank'
        iban 'DE12500105170648489890'
        bic 'GENODEM1GLS'
      end
    end

    trait :no_bank_data do
      bank_code ''
      bank_account_number ''
      iban ''
      bic ''
    end

    trait :paypal_data do
      paypal_account Faker::Internet.email
    end

    trait :fastbill do
      fastbill_id '1223'
      fastbill_subscription_id '76543'
    end

    trait :ngo do
      ngo true
    end

    trait :with_unified_transport_information do
      unified_transport_provider 'DHL'
      unified_transport_price_cents 300
      unified_transport_maximum_articles 10
    end

    trait :with_free_transport_at_5 do
      free_transport_at_price_cents 500
      free_transport_available true
    end
  end
end
