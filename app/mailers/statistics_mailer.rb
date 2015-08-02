class StatisticsMailer < ActionMailer::Base
  default from: '@fairmondo.de'

  def last_months_numbers_email(revenue_hash)
    @revenue_hash = revenue_hash
    @month = I18n.l(1.month.ago, format: '%B')
    mail(to: '@fairmondo.de',
         subject: "Statistiken für den Fairmondo-Marktplatz vom #{@month}")
  end

end
