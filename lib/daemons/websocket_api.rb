#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require 'socket'
require File.join(root, "config", "environment")

Rails.logger = logger = Logger.new STDOUT

EM.error_handler do |e|
  logger.error "Error: #{e}"
  logger.error e.backtrace[0,20].join("\n")
end

EM.run do
  conn = AMQP.connect AMQPConfig.connect
  logger.info "Connected to AMQP broker."

  ch = AMQP::Channel.new conn
  ch.prefetch(1)

  config = {host: ENV['WEBSOCKET_HOST'], port: ENV['WEBSOCKET_PORT']}
  if ENV['WEBSOCKET_SSL_KEY'] && ENV['WEBSOCKET_SSL_CERT']
    config[:secure] = true
    config[:tls_options] = {
      private_key_file: Rails.root.join(ENV['WEBSOCKET_SSL_KEY']).to_s,
      cert_chain_file: Rails.root.join(ENV['WEBSOCKET_SSL_CERT']).to_s
    }
  end

  EM::WebSocket.run(config) do |ws|
    logger.debug "New WebSocket connection: #{ws.inspect}"

    protocol = ::APIv2::WebSocketProtocol.new(ws, ch, logger)

    ws.onopen do |handshake|
      protocol.broadcast(handshake.path[1..-1])
    end

    ws.onmessage do |message|
      logger.info "Received message: #{message}"
    end

    ws.onerror do |error|
      case error
      when EM::WebSocket::WebSocketError
        logger.info "WebSocket error: #{$!}"
        logger.info $!.backtrace[0,20].join("\n")
        logger.info $!.inspect
      else
        logger.info $!
      end
    end

    ws.onclose do
      logger.info "WebSocket closed"
    end
  end
end
