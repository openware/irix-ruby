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

  context "#ws_read_public_message" do
    context "hb message" do
      let(:msg) { [37,"hb"] }

      xit do
        allow_any_instance_of(Faye::WebSocket::Client).to receive(:new)
        bitfinex.ws_read_public_message(msg)
      end
    end

    context 'trade message' do
      let(:msg) { [17470,"tu",[401597395,1574694478808,0.005,7245.3]] }

      it do
        bitfinex.open_channels = { 17470 => 'trades' }
        expect(bitfinex).to receive(:detect_trade).with(msg)
        bitfinex.ws_read_public_message(msg)
      end
    end

    context 'book message' do
      let(:msg) { [75153,[170.16,2,-28.67834216]] }

      it do
        bitfinex.open_channels = { 75153 => 'book' }
        expect(bitfinex).to receive(:detect_order).with(msg)
        bitfinex.ws_read_public_message(msg)
      end
    end
  end

  context "Public trades" do
    let(:msg) { [17470,"tu",[401597395,1574694478808,0.005,7245.3]] }

    let(:trade) { 
      {
        tid: 401597395,
        amount: 0.005.to_d,
        price: 7245.3,
        date: 1574694478808 / 1000,
        taker_type: 'buy'
      }.stringify_keys
    }

    it do
      expect(bitfinex).to receive(:notify_public_trade).with(trade)
      bitfinex.detect_trade(msg)
    end
  end

  context "OrderBook proxy" do
    let(:order_msg) { [75153,[170.16,2,-28.67834216]] }
    let(:snapshot_msg) { [34728,[[7088.2,1,0.005167],[7088.3,11,-17.97282213]]] }

    it do
      bitfinex.snap = { 'asks' => [], 'bids' => [] }
      expect(bitfinex).to receive(:publish_snapshot)
      bitfinex.detect_order(snapshot_msg)
    end

    it do
      bitfinex.snap = { 'asks' => [], 'bids' => [] }
      bitfinex.increment_count = 0
      bitfinex.snapshot_time = Time.now
      expect(bitfinex).to receive(:fill_increment)
      bitfinex.detect_order(order_msg)
    end

    it do
      bitfinex.snap = { 'asks' => [], 'bids' => [] }
      bitfinex.increment_count = 101
      bitfinex.snapshot_time = Time.now - 60
      expect(bitfinex).to receive(:publish_snapshot)
      expect(bitfinex).to receive(:fill_increment)
      bitfinex.detect_order(order_msg)
    end
  end
end
