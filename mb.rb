# To run:
# gem install rspec
# rspec mb.rb

class Provider
  def initialize(name:, method:, url:, http_client:, payload: {})
    @name = name
    @method = method.to_sym
    @url = url
    @http_client = http_client
    @payload = payload
  end

  def deliver(phone:, message:)
    values = { phone: phone, message: message }

    if @method == :get
      @http_client.send(@method, @url % values)
    else
      payload_rendered = {}

      @payload.each do |key, value|
        payload_rendered[key] = values.fetch(value)
      end

      @http_client.send(@method, @url % values, payload_rendered)
    end
  end
end

class DeliveryStrategy
  NoProvidersToPick = Class.new(StandardError)

  def initialize(default_provider: nil, default_provider_retries: 1)
    @providers_by_prefix = {}
    @default_provider = default_provider
    @default_provider_retries = default_provider_retries
  end

  def add(prefix:, provider:, retries: 1)
    @providers_by_prefix[prefix] ||= []

    retries.times do
      @providers_by_prefix[prefix] << provider
    end
  end

  # Providers are added to @providers_by_prefix[prefix] according to their number
  # of retries. As an example for the following case:
  # - 1st provider for prefix 61 is KPN, with 1 retry only
  # - 2nd provider for prefix 61 is ZIGO, with 2 retries
  # - the default provider is XYZ with 2 retries
  #
  # @providers_by_prefix will be:
  #
  # @providers_by_prefix = {
  #   '61': [ kpn, zigo, zigo, xyz, xyz]
  # }
  def select_provider(phone:, attempt: 1)
    prefix = phone[0..1]
    return @default_provider unless @providers_by_prefix.has_key?(prefix)

    # non default providers
    return @providers_by_prefix[prefix][attempt - 1] if attempt <= @providers_by_prefix[prefix].size

    # default provider
    return @default_provider if attempt - @providers_by_prefix[prefix].size <= @default_provider_retries

    raise NoProvidersToPick
  end
end

class SmsGateway
  def initialize(http_client:, deliver_strategy: nil)
    @deliver_strategy = deliver_strategy || default_strategy(http_client: http_client)
  end

  def deliver(phone:, message:, provider: nil, attempt: 1)
    provider ||= @deliver_strategy.select_provider(phone: phone)
    provider.deliver(phone: phone, message: message)
  rescue StandardError => e
    next_attempt = attempt + 1
    next_provider = @deliver_strategy.select_provider(phone: phone, attempt: next_attempt)

    raise e unless next_provider

    deliver(phone: phone, message: message, provider: next_provider, attempt: next_attempt)
  end

  def default_strategy(http_client:)
    zigo = Provider.new(
      name: 'zigo',
      method: :get,
      url: 'http://url1/?phone=%{phone}&message=%{message}',
      http_client: http_client
    )

    kpn = Provider.new(
      name: 'kpn',
      method: :get,
      url: 'http://url2/%{phone}?message=%{message}',
      http_client: http_client
    )

    post_provider = Provider.new(
      name: 'post provider',
      method: :post,
      url: 'http://url3',
      payload: { msg: :message, phone: :phone },
      http_client: http_client
    )

    deliver_strategy = DeliveryStrategy.new(default_provider: post_provider)
    deliver_strategy.add(prefix: '61', provider: zigo, retries: 1)
    deliver_strategy.add(prefix: '61', provider: kpn, retries: 2)

    deliver_strategy.add(prefix: '51', provider: zigo, retries: 1)
    deliver_strategy.add(prefix: '51', provider: post_provider, retries: 2)

    deliver_strategy
  end
end

#### --------------- unit tests ----------------------------------- #########################

require 'rspec'

describe SmsGateway do
  let(:fake_http_client) { double(get: '', post: '') }

  it 'sends a message using the correct provider' do
    # setup
    zigo = Provider.new(
      name: 'zigo',
      method: :get,
      url: 'http://example.com/url1/%{number}',
      http_client: fake_http_client
    )

    deliver_strategy = DeliveryStrategy.new
    deliver_strategy.add(prefix: '61', provider: zigo, retries: 1)

    msg = 'aa'
    phone = '61534543'

    # verify
    expect(zigo).to receive(:deliver).with(message: msg, phone: phone)

    # exercise
    gateway = SmsGateway.new(deliver_strategy: deliver_strategy, http_client: fake_http_client)
    gateway.deliver(message: msg, phone: phone)
  end
end

describe DeliveryStrategy do
  let(:fake_http_client) { double(get: '', post: '') }

  let(:zigo) do
    Provider.new(
      name: 'zigo',
      method: :get,
      url: 'http://example.com/url1/%{number}',
      http_client: fake_http_client
    )
  end

  let(:kpn) do
    Provider.new(
      name: 'kpn',
      method: :get,
      url: 'http://example.com/url1/%{number}',
      http_client: fake_http_client
    )
  end

  it 'returns the correct provider for the number' do
    # setup
    deliver_strategy = DeliveryStrategy.new
    deliver_strategy.add(prefix: '61', provider: zigo, retries: 1)
    deliver_strategy.add(prefix: '51', provider: kpn, retries: 1)

    # exercise
    provider1 = deliver_strategy.select_provider(phone: '51232')
    expect(provider1).to eq(kpn)

    provider2 = deliver_strategy.select_provider(phone: '61232')
    expect(provider2).to eq(zigo)
  end

  it 'returns the default provider when there is no specific provider for the number' do
    # setup
    deliver_strategy = DeliveryStrategy.new(default_provider: zigo)

    # exercise
    provider1 = deliver_strategy.select_provider(phone: '51232')
    expect(provider1).to eq(zigo)

    provider2 = deliver_strategy.select_provider(phone: '61232')
    expect(provider2).to eq(zigo)
  end

  it 'uses the next providers if the first ones fail' do
    # setup
    deliver_strategy = DeliveryStrategy.new
    deliver_strategy.add(prefix: '61', provider: zigo, retries: 1)
    deliver_strategy.add(prefix: '61', provider: kpn, retries: 1)

    # exercise
    provider1 = deliver_strategy.select_provider(phone: '6133232')
    expect(provider1).to eq(zigo)

    provider2 = deliver_strategy.select_provider(phone: '6133232', attempt: 2)
    expect(provider2).to eq(kpn)
  end

  it 'uses the default provider if there is no provider set for the current number of attempts' do
    # setup
    deliver_strategy = DeliveryStrategy.new(default_provider: kpn)
    deliver_strategy.add(prefix: '61', provider: zigo, retries: 1)

    # exercise
    provider1 = deliver_strategy.select_provider(phone: '6133232')
    expect(provider1).to eq(zigo)

    provider2 = deliver_strategy.select_provider(phone: '6133232', attempt: 2)
    expect(provider2).to eq(kpn)
  end

  it 'respect default_provider_retries when the default provider is used' do
    # setup
    deliver_strategy = DeliveryStrategy.new(default_provider: kpn, default_provider_retries: 2)
    deliver_strategy.add(prefix: '61', provider: zigo, retries: 1)

    # exercise
    provider1 = deliver_strategy.select_provider(phone: '6133232')
    expect(provider1).to eq(zigo)

    provider2 = deliver_strategy.select_provider(phone: '6133232', attempt: 2)
    expect(provider2).to eq(kpn)

    provider3 = deliver_strategy.select_provider(phone: '6133232', attempt: 3)
    expect(provider3).to eq(kpn)

    expect do
      deliver_strategy.select_provider(phone: '6133232', attempt: 4)
    end.to raise_error(DeliveryStrategy::NoProvidersToPick)
  end
end

describe Provider do
  let(:fake_http_client) { double(get: '', post: '') }

  context 'when the provider uses the GET HTTP method' do
    it 'makes the correct HTTP request to deliver a message' do
      http_client = spy

      fake_provider = Provider.new(
        name: 'fake',
        method: 'get',
        url: 'http://example.com/send?phone=%{phone}&msg=%{message}',
        http_client: http_client
      )

      # exercise
      fake_provider.deliver(phone: '212', message: 'aaa')

      # verify
      expect(http_client)
        .to have_received(:get)
        .with('http://example.com/send?phone=212&msg=aaa')
    end
  end

  context 'when the provider uses the POST HTTP method' do
    it 'makes the correct HTTP request to deliver a message' do
      fake_provider = Provider.new(
        name: 'fake',
        method: 'post',
        url: 'http://example.com/deliver',
        payload: {
          phone_number: :phone,
          msg: :message
        },
        http_client: fake_http_client
      )

      # exercise
      fake_provider.deliver(phone: '212', message: 'aaa')

      # verify
      expect(fake_http_client)
        .to have_received(:post)
        .with('http://example.com/deliver', { phone_number: '212', msg: 'aaa' })
    end
  end
end

describe 'Integration tests' do
  let(:fake_http_client) { double(get: '', post: '') }

  it 'uses the correct strategy for 61 prefix when all provides fail' do
    gateway = SmsGateway.new(http_client: fake_http_client)

    expect(fake_http_client)
      .to receive(:get)
      .with('http://url1/?phone=61123&message=aaa')
      .and_raise('any error')

    expect(fake_http_client)
      .to receive(:get)
      .with('http://url2/61123?message=aaa')
      .and_raise('any error')

    expect(fake_http_client)
      .to receive(:get)
      .with('http://url2/61123?message=aaa')
      .and_raise('other error')

    expect(fake_http_client)
      .to receive(:post)
      .with('http://url3', { msg: 'aaa', phone: '61123' })
      .and_raise('last error')

    # exercise
    expect do
      gateway.deliver(message: 'aaa', phone: '61123')
    end.to raise_error(DeliveryStrategy::NoProvidersToPick)
  end

  it 'uses the correct strategy for 51 prefix when all provides fail' do
    gateway = SmsGateway.new(http_client: fake_http_client)

    expect(fake_http_client)
      .to receive(:get)
      .with('http://url1/?phone=51123&message=aaa')
      .and_raise('any error')

    # 1st attempt
    expect(fake_http_client)
      .to receive(:post)
      .with('http://url3', { msg: 'aaa', phone: '51123' })
      .and_raise('other error')

    # 2nd attempt
    expect(fake_http_client)
      .to receive(:post)
      .with('http://url3', { msg: 'aaa', phone: '51123' })
      .and_raise('other error')

    # default provider
    expect(fake_http_client)
      .to receive(:post)
      .with('http://url3', { msg: 'aaa', phone: '51123' })
      .and_raise('last error')

    # exercise
    expect do
      gateway.deliver(message: 'aaa', phone: '51123')
    end.to raise_error(DeliveryStrategy::NoProvidersToPick)
  end

  it 'uses the default provider for other prefixes' do
    gateway = SmsGateway.new(http_client: fake_http_client)

    expect(fake_http_client)
      .to receive(:post)
      .with('http://url3', { msg: 'aaa', phone: '91123' })
      .and_return(:ok)

    # exercise
    result = gateway.deliver(message: 'aaa', phone: '91123')
    expect(result).to eq(:ok)
  end
end
