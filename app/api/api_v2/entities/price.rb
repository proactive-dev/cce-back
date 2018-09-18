module APIv2
  module Entities
    class Price < Base
      expose :market_id, documentation: "Unique market id. It's always in the form of xxxyyy, where xxx is the base currency code, yyy is the quote currency code, e.g. 'btccny'. All available markets can be found at /api/v2/markets."
      expose :market_name

      expose :price_type
      expose :price

      private
      def market_name
        @market_name ||= ::Market.find(@object.market_id).name
      end

      def price
        @price ||= if @object.price_type == 'normal'
                     Global[@object.market_id].ticker[:last].to_f
                   else
                     @object.price.to_f
                   end
      end
    end
  end
end
