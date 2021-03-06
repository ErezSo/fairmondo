#   Copyright (c) 2012-2015, Fairmondo eG.  This file is
#   licensed under the GNU Affero General Public License version 3 or later.
#   See the COPYRIGHT file for details.

class FastbillRefundWorker
  include Sidekiq::Worker

  sidekiq_options queue: :fastbill,
                  retry: 20,
                  backtrace: true

  def perform id
    BusinessTransaction.transaction do
      bt = BusinessTransaction.lock.find(id)
      fastbill = FastbillAPI.new bt

      [:fair, :fee].each do |type|
        fastbill.send("fastbill_refund_#{ type }")
      end
    end
  end
end
