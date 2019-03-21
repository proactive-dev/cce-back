module APIv2
  class Tools < Grape::API
    desc 'Get server current time, in miliseconds since Unix epoch.'
    get "/timestamp" do
      { timestamp: (Time.now.to_f * 1000.0).to_i}
    end
  end
end
