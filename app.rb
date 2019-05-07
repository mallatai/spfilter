#!/usr/bin/env ruby

require 'redis'
require_relative 'lib/spam_filter'
require_relative 'lib/message_content_filter'
require_relative 'lib/senderid_filter'

MESSAGE_QUEUES = ["processing:filter:spam:0",
                  "processing:filter:spam:1",
                  "processing:filter:spam:2",
                  "processing:filter:spam:3"]

DEFAULT_REDIS_IP = "127.0.0.1"
DEFAULT_REDIS_PORT = 6379

def main
  if ARGV.length < 1
    puts "Specify IP address and port for Redis server"
    exit
  end

  redis = nil
  redis_ip = DEFAULT_REDIS_IP
  redis_port = DEFAULT_REDIS_PORT

  if ARGV.length == 1
    redis_ip = ARGV[0]
  end

  if ARGV.length > 1
    redis_ip = ARGV[0]
    redis_port = ARGV[1]
  end

  begin
    puts "Working..."
    redis = Redis.new(:host => redis_ip,
                      :port => redis_port)

    filters = [MessageContentFilter.new(redis),
               SenderIdFilter.new(redis)]

    spf = SpamFilter.new(redis, MESSAGE_QUEUES, filters)
    spf.start

  rescue Interrupt
    puts "\nClosing Redis connection..."
    puts redis.quit
  rescue Exception => e
    puts "Couldn't connect to Redis server: #{e.inspect}"
  ensure
    redis.quit
  end
end

main

