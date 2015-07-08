require_relative '../test_helper'
include FastBillStubber

describe FastbillAPI do
  describe 'methods' do
    let(:business_transaction) { BusinessTransaction.new }

    let(:seller) { FactoryGirl.create :legal_entity, :paypal_data }
    let(:db_business_transaction) do
      FactoryGirl.create :business_transaction, seller: seller
    end

    let(:private_seller) { FactoryGirl.create :private_user, :paypal_data, :fastbill }
    let(:private_business_transaction) do
      FactoryGirl.create :business_transaction, seller: private_seller
    end

    describe '::fastbill_chain' do
      it 'should find seller of transaction' do
        api = FastbillAPI.new db_business_transaction
        api.instance_eval('@seller').must_equal seller
      end

      describe 'when seller is an NGO' do
        it 'should not contact Fastbill' do
          User.any_instance.stubs(:ngo).returns(:true)
          api = FastbillAPI.new db_business_transaction
          Fastbill::Automatic::Base.expects(:perform).never
          api.fastbill_chain
        end
      end

      describe 'when seller is a private user' do
        it 'should not contact Fastbill' do
          api = FastbillAPI.new private_business_transaction
          Fastbill::Automatic::Base.expects(:perform).once
          api.fastbill_chain
        end
      end

      describe 'when seller is not an NGO' do
        describe 'and has Fastbill profile' do
          it 'should not create new Fastbill profile' do
            db_business_transaction # to trigger observers before
            seller.update_attributes(fastbill_id: '1234',
                                     fastbill_subscription_id: '4321')
            api = FastbillAPI.new db_business_transaction
            api.expects(:fastbill_create_customer).never
            api.expects(:fastbill_create_subscription).never
            api.fastbill_chain
          end
        end

        describe 'and has no Fastbill profile' do
          it 'should create new Fastbill profile' do
            db_business_transaction # to trigger observers before
            api = FastbillAPI.new db_business_transaction
            api.expects(:fastbill_create_customer)
            api.expects(:fastbill_create_subscription)
            api.fastbill_chain
          end
        end

        it 'should set usage data for subscription' do
          db_business_transaction # to trigger observers before
          api = FastbillAPI.new db_business_transaction
          Fastbill::Automatic::Subscription.expects(:setusagedata).twice
          api.fastbill_chain
        end
      end

      describe 'article price is 0 Euro' do
        let(:article) { FactoryGirl.create :article, price: Money.new(0) }
        it 'should not call FastbillAPI' do
          api = FastbillAPI.new
          api.expects(:fastbill_chain).never
          FactoryGirl.create :business_transaction, article: article
        end
      end
    end

    describe '::fastbill_discount' do
      it 'should call setusagedata' do
        db_business_transaction # to trigger observers before
        Fastbill::Automatic::Subscription.expects(:setusagedata)
        db_business_transaction.discount = FactoryGirl.create :discount
        api = FastbillAPI.new db_business_transaction
        api.send :fastbill_discount
      end
    end

    describe '::fastbill_refund' do
      it 'should call setusagedata' do
        db_business_transaction # to trigger observers before
        Fastbill::Automatic::Subscription.expects(:setusagedata).twice
        api = FastbillAPI.new db_business_transaction
        api.send :fastbill_refund_fair
        api.send :fastbill_refund_fee
      end
    end

    # describe '::update_profile' do
    #   it 'should call setusagedata' do
    #     Fastbill::Automatic::Customer.expects( :get )
    #     FastbillAPI.update_profile( seller )
    #   end
    # end

    describe '::discount_wo_vat' do
      it 'should receive call' do
        db_business_transaction.discount = FactoryGirl.create :discount
        api = FastbillAPI.new db_business_transaction
        api.expects(:discount_wo_vat)
        api.fastbill_chain
      end
    end

    describe 'refund' do
      it 'should receive call' do
        FastbillAPI.any_instance.expects(:fastbill_refund_fair)
        FastbillAPI.any_instance.expects(:fastbill_refund_fee)
        FastbillRefundWorker.perform_async(db_business_transaction.id)
      end
    end
  end
end
