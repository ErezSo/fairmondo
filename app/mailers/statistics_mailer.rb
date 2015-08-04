class StatisticsMailer < ActionMailer::Base
  default from: EMAIL_ADDRESSES['StatisticsMailer']['mailer_sender']

  def last_months_numbers_email(statistics)
    revenue_hash = statistics.revenue_last_month
    @revenue = Money.new(revenue_hash[:revenue])
    @fee     = Money.new(revenue_hash[:fee])
    @fair    = Money.new(revenue_hash[:fair])

    @new_users                   = statistics.new_users_last_month
    @legal_entities_count        = statistics.legal_entities_count
    @private_users_count         = statistics.private_users_count
    @legal_entity_articles_count = statistics.legal_entity_articles_count
    @private_user_articles_count = statistics.private_user_articles_count

    @month = 1.month.ago
    @date = Date.today

    mail(to: EMAIL_ADDRESSES['StatisticsMailer']['mailer_recipient'],
         subject: "#{I18n.l @month, format: '%B'}-Statistiken für den Fairmondo-Marktplatz")
  end
end
