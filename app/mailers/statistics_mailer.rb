class StatisticsMailer < ActionMailer::Base
  default from: EMAIL_ADDRESSES['StatisticsMailer']['mailer_sender']

  def last_months_numbers_email(statistics)
    @revenue_hash = statistics.revenue_last_month
    @new_users = statistics.new_users_last_month
    @legal_entities_count = statistics.legal_entities_count
    @private_users_count = statistics.private_users_count
    @legal_entity_articles_count = statistics.legal_entity_articles_count
    @private_user_articles_count = statistics.private_user_articles_count
    @sum_article_prices = statistics.sum_article_prices
    @sum_article_prices_with_quantity = statistics.sum_article_prices_with_quantity

    @month = 1.month.ago
    @date = Date.today

    mail(to: EMAIL_ADDRESSES['StatisticsMailer']['mailer_recipient'],
         subject: "Statistiken für den Fairmondo-Marktplatz vom #{I18n.l @month, format: '%B'}")
  end

end
