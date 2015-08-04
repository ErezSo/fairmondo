require 'test_helper'

describe StatisticsMailer do
  include EmailSpec::Matchers

  it '#last_months_numbers_email' do
    mail = StatisticsMailer.last_months_numbers_email(Statistic.new).deliver

    assert_not ActionMailer::Base.deliveries.empty?

    mail.must have_subject "#{I18n.l 1.month.ago, format: '%B'}-Statistiken für den Fairmondo-Marktplatz"

    mail.must have_body_text 'Umsatz'
    mail.must have_body_text 'Artikel eingestellt'
  end
end
