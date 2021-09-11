
class SmsGateway
  def initialize
  end

  def deliver(phone, msg)
  end
end

def main
  zigo = Provider.new(
    method: :get,
    url: "http://example.com/url1/%{number}"
  )
  kpn = Provider.new(
    method: :get,
    url: "http://example2.com/url2?number=%{number}"
  )
  lebara = Provider.new(
    method: :post,
    url: "http://example2.com/url3",
    payload: { number: "%{number}"}
  )

  test_strategy = ProvidersStrategy.new
  test_strategy.add(prefix: 61, provider: zigo, retries: 1)
  test_strategy.add(prefix: 61, provider: kpn retries: 2)
  test_strategy.add(prefix: 51, provider: lebara, retries: 2)
  test_strategy.add(prefix: 51, provider: zigo, retries: 1)
  test_strategy.add(prefix: :default, provider: zigo, retries: 2)

  sms_gateway = SmsGateway.new(providers_strategy: test_strategy)
  sms_gateway.deliver('616876687', 'msg')
end
