# frozen_string_literal: true

RSpec.describe Irix::Huobi do
  let(:upstream_huobi_config) do
    {
      "driver": 'huobi',
      "source": 'btcusdt',
      "target": 'btcusdt',
      "rest": 'https://api.huobi.pro/',
      "websocket": 'wss://api.huobi.pro/ws/'
    }.stringify_keys
  end

  let(:huobi) { Irix::Huobi.new(upstream_huobi_config) }

  let(:msg) { [{ 'id' => 10_546_668_650_576_828_480_136, 'ts' => 1_585_058_508_268, 'tradeId' => 102_103_734_360, 'amount' => 0.03817, 'price' => 6674.92, 'direction' => 'buy' }] }

  let(:trade) do
    {
      tid: 102_103_734_360,
      amount: 0.03817.to_d,
      price: 6674.92.to_d,
      date: 1_585_058_508_268 / 1000,
      taker_type: 'buy'
    }.stringify_keys
  end
  it do
    expect(huobi).to receive(:notify_public_trade).with(trade)
    huobi.detect_trade(msg)
  end
end
