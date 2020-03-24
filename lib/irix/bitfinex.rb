# frozen_string_literal: true

module Irix
  class Bitfinex < Peatio::Upstream::Base
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
      @ws_url = "#{config['websocket']}"
    end

    def ws_connect
      super
      return if @ping_set

      Fiber.new do
        EM::Synchrony.add_periodic_timer(80) do
          @ws.send('{"event":"ping"}')
        end
      end.resume
      @ping_set = true
    end

    def subscribe_trades(market, ws)
      sub = {
        event: 'subscribe',
        channel: 'trades',
        symbol: market.upcase
      }

      Rails.logger.info 'Open event' + sub.to_s
      EM.next_tick do
        ws.send(JSON.generate(sub))
      end
    end

    def ws_read_public_message(msg)
      if msg.is_a?(Array)
        detect_trade(msg)
      elsif msg.is_a?(Hash)
        message_event(msg)
      end
    end

    def detect_trade(msg)
      if msg[1] == 'tu'
        data = msg[2]
        trade =
          {
            'tid' => data[0],
            'amount' => data[2].to_d.abs,
            'price' => data[3],
            'date' => data[1] / 1000,
            'taker_type' => data[2].to_d.positive? ? 'buy' : 'sell'
          }
        notify_public_trade(trade)
      end
    end

    def message_event(msg)
      case msg['event']
      when 'subscribed'
        Rails.logger.info "Event: #{msg}"
      when 'error'
        Rails.logger.info "Event: #{msg} ignored"
      end
    end

    def info(msg)
      Rails.logger.info "Bitfinex: #{msg}"
    end
  end
end
