RSpec.describe Irix::Bitfinex do
  let(:upstream_bitfinex_config) do
    {
      "driver": "bitfinex",
      "source": "btcusd",
      "target": "btcusd",
      "rest": "http://api-pub.bitfinex.com/ws/2",
      "websocket": "wss://api-pub.bitfinex.com/ws/2"
    }.stringify_keys
  end

  let(:bitfinex) { Irix::Bitfinex.new(upstream_bitfinex_config) }

  let(:msg) { [17470,"tu",[401597395,1574694478808,0.005,7245.3]] }

  let(:trade) { 
    {
      tid: 401597395,
      market: 'btcusd',
      amount: 0.005.to_d,
      price: 7245.3,
      date: 1574694478808 / 1000,
      taker_type: 'buy'
    }
  }
  it do
    expect(bitfinex).to receive(:notify_public_trade).with(trade)
    bitfinex.detect_trade(msg)
  end
end
