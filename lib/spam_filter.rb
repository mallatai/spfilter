require_relative 'message_content_filter'
require_relative 'senderid_filter'

PROCESSING_TIMEOUT = 1

class SpamFilter
  
  def initialize(redis, msg_queues, filter_list)
    @redis = redis
    @message_queues = msg_queues
    @filters = filter_list
  end

  def start
    while true do
      @message_queues.each do |queue|
        if @redis.llen(queue) > 0
          puts "Processing queue '#{queue}'" 
          process_queue(queue)
        end
      end
      sleep PROCESSING_TIMEOUT
    end
  end

  def process_queue(queue)
    msg = @redis.rpop queue
    while msg do
      spam_filter(msg)
      msg = @redis.rpop queue
    end
  end

  private

  def spam_filter(msg)
    msg_hash = JSON.parse msg
    
    @filters.each do |f|
      spam = f.check msg_hash
      break if spam
    end
  end

end

