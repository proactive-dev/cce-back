module APIv2
  class Markets < Grape::API
    helpers ::APIv2::NamedParams

    desc 'Get all available markets.'
    get "/markets" do
      present Market.all, with: APIv2::Entities::Market
    end

    desc 'Get price option of all markets'
    get "/markets/prices" do
      present Price.all, with: APIv2::Entities::Price
    end

    desc 'Get price option of specific market.'
    params do
      use :market
    end
    get "/markets/price" do
      present Price.find_by_market_id(params[:market]), with: APIv2::Entities::Price
    end

  end
end
