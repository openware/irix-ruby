# frozen_string_literal: true

module Irix
  class Huobi < Peatio::Upstream::Base
    # WS huobi global
    # websocket: "wss://api.huobi.pro/ws/"
    # WS for krw markets
    # websocket: "wss://api-cloud.huobi.co.kr/ws/"

    def initialize(config)
      super
      @connection = Faraday.new(url: (config['rest']).to_s) do |builder|
        builder.response :json
        builder.response :logger if config['debug']
        builder.adapter(@adapter)
        unless config['verify_ssl'].nil?
          builder.ssl[:verify] = config['verify_ssl']
        end
      end
      @ping_set = false
      @rest = (config['rest']).to_s
      @ws_url = (config['websocket']).to_s
    end

    def ws_read_message(msg)
      data = Zlib::GzipReader.new(StringIO.new(msg.data.map(&:chr).join)).read
      Rails.logger.debug { "received websocket message: #{data}" }

      object = JSON.parse(data)
      ws_read_public_message(object)
    end

    def ws_read_public_message(msg)
      if msg['ping'].present?
        @ws.send(JSON.dump('pong': msg['ping']))
        return
      end

      case msg['ch']
      when /market\.([^.]+)\.trade\.detail/
        detect_trade(msg.dig('tick', 'data'))
      end
    end

    def detect_trade(msg)
      msg.map do |t|
        trade =
          {
            'tid' => t['tradeId'],
            'amount' => t['amount'].to_d,
            'price' => t['price'].to_d,
            'date' => t['ts'] / 1000,
            'taker_type' => t['direction']
          }
        notify_public_trade(trade)
      end
    end

    def ws_connect
      super
      return if @ping_set

      Fiber.new do
        EM::Synchrony.add_periodic_timer(80) do
          @ws.send(JSON.dump('ping' => Time.now.to_i))
        end
      end.resume
      @ping_set = true
    end

    def subscribe_trades(market, ws)
      sub = {
        'sub' => "market.#{market}.trade.detail"
      }

      Rails.logger.info 'Open event' + sub.to_s
      EM.next_tick do
        ws.send(JSON.generate(sub))
      end
    end
  end
end
