class FastbillAPI
  require 'fastbill-automatic'

  def initialize bt = nil
    if @bt = bt
      @seller  = bt.seller
      @article = bt.article
    end
  end

  # Here be FastBill stuff
  #
  # The fastbill_chain takes control of all the necessary steps to handle
  # fastbill customer creation and adding business_transactions fees to a user's
  # fastbill account
  def fastbill_chain
    @seller.with_lock do
      unless @seller.is_a?(PrivateUser) || @seller.ngo?
        unless @seller.has_fastbill_profile?
          fastbill_create_customer
          fastbill_create_subscription
        end

        [:fair, :fee].each do |type|
          send "fastbill_#{ type }"
        end

        fastbill_discount if @bt.discount
      end
    end
  end

  def has_profile?
    @seller.fastbill_id != nil
  end

  def has_subscription?
    @seller.fastbill_subscription_id != nil
  end

  def update_profile user
    customer = Fastbill::Automatic::Customer.get(customer_id: user.fastbill_id).first
    if customer
      attributes = attributes_for(user)
      attributes[:customer_id] = user.fastbill_id
      customer.update_attributes(attributes)
    end
  end

  def fastbill_create_customer
    unless @seller.fastbill_id
      User.observers.disable :user_observer do
        attributes = attributes_for(@seller)
        attributes[:customer_number] = @seller.id
        customer = Fastbill::Automatic::Customer.create(attributes)
        @seller.update_attribute :fastbill_id, customer.customer_id
      end
    end
  end

  def fastbill_delete_customer
    if @seller.fastbill_id
      User.observers.disable :user_observer do
        Fastbill::Automatic::Customer.delete(@seller.fastbill_id.to_s)
        @seller.update_attribute :fastbill_id, nil
        @seller.update_attribute :fastbill_subscription_id, nil
      end
    end
  end

  # Why on earth does this do something with the user? It should not update
  # the user at all, just return something.
  def fastbill_create_subscription
    unless @seller.fastbill_subscription_id
      User.observers.disable :user_observer do
        subscription = Fastbill::Automatic::Subscription.create(
          article_number: '10',
          customer_id: @seller.fastbill_id,
          next_event: Time.now.end_of_month.strftime('%Y-%m-%d %H:%M:%S')
        )
        @seller.update_column :fastbill_subscription_id, subscription.subscription_id
      end
    end
  end

  def fastbill_cancel_subscription
    if @seller.fastbill_subscription_id
      User.observers.disable :user_observer do
        Fastbill::Automatic::Subscription.cancel(@seller.fastbill_subscription_id.to_s)
        @seller.update_column :fastbill_subscription_id, nil
      end
    end
  end

  private

  def attributes_for(user)
    {
      customer_type: user.is_a?(LegalEntity) ? 'business' : 'consumer',
      organization: (user.is_a?(LegalEntity) &&
                     user.standard_address_company_name.present?) ?
                     user.standard_address_company_name : user.nickname,
      salutation: user.standard_address_title,
      first_name: user.standard_address_first_name,
      last_name: user.standard_address_last_name,
      address: user.standard_address_address_line_1,
      address_2: user.standard_address_address_line_2 ? user.standard_address_address_line_2 : nil,
      zipcode: user.standard_address_zip,
      city: user.standard_address_city,
      country_code: 'DE',
      language_code: 'DE',
      email: user.email,
      currency_code: 'EUR',
      payment_type: '1', # Ueberweisung
      # payment_type: '2', # Bankeinzug # Bitte aktivieren, wenn Genehmigung der Bank vorliegt
      show_payment_notice: '1',
      bank_name: user.bank_name,
      bank_code: user.bank_code,
      bank_account_number: user.bank_account_number,
      bank_account_owner: user.bank_account_owner
    }
  end

  [:fee, :fair, :discount, :refund_fee, :refund_fair].each do |type|
    define_method "fastbill_#{ type }" do
      unless @bt.send("billed_for_#{ type }")
        Fastbill::Automatic::Subscription.setusagedata(
          subscription_id: @seller.fastbill_subscription_id,
          article_number: article_number_for(type),
          quantity: quantity_for(type),
          unit_price: unit_price_for(type),
          description: description_for(type),
          usage_date: @bt.sold_at.strftime('%Y-%m-%d %H:%M:%S')
        )
        @bt.send("billed_for_#{ type }=", true)
        @bt.save
      end
    end
  end

  def description_for type
    if type == :discount
      "#{ @bt.id } #{ @article.title } (#{ @bt.discount_title })"
    else
      "#{ @bt.id } #{ @article.title } (#{ I18n.t('invoice.' + type.to_s) })"
    end
  end

  def quantity_for type
    if type == :discount
      '1'
    else
      @bt.quantity_bought
    end
  end

  def article_number_for type
    if type == :fair || type == :refund_fair
      11
    elsif type == :fee || type == :refund_fee
      12
    else
      nil
    end
  end

  def unit_price_for type
    case type
    when :fee
      fee_wo_vat
    when :fair
      fair_wo_vat
    when :discount
      discount_wo_vat
    when :refund_fee
      0 - actual_fee_wo_vat
    when :refund_fair
      0 - fair_wo_vat
    end
  end

  # This method calculates the fair percent fee without vat
  def fair_wo_vat
    (@article.calculated_fair_cents.to_f / 100 / 1.19).round(2)
  end

  # This method calculates the fee without vat
  def fee_wo_vat
    (@article.calculated_fee_cents.to_f / 100 / 1.19).round(2)
  end

  # This method calculates the discount without vat
  def discount_wo_vat
    0 - (@bt.discount_value_cents.to_f / 100 / 1.19).round(2)
  end

  # This method calculates the fee without the discount (without vat)
  def actual_fee_wo_vat
    fee = fee_wo_vat
    fee -= discount_wo_vat if @bt.discount
    fee
  end
end
