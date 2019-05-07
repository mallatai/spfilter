require_relative 'filter_base'

FILTER_CONTENT_MAX_COUNT = 5
CONTENT_FILTER_TIMEOUT = 60 * 60

class MessageContentFilter < FilterBase

  def initialize(redis)
    @redis = redis
    @msg_hash = nil
    @dlr_err_code = "006"
    @name = "MessageContentFilter"
  end

  def check(msg_hash)
    @msg_hash = msg_hash

    is_spam = false
    recipient = @msg_hash["mt_sms"]["to"]
    msg_text = @msg_hash["mt_sms"]["text"]

    if @redis.exists recipient
      prev_text = @redis.hget recipient, "text"
      if msg_text == prev_text   
        @redis.hincrby recipient, "count", 1
        count = @redis.hget(recipient, "count").to_i
        if count > FILTER_CONTENT_MAX_COUNT
          puts "Spam: MessageContentFilter"
          is_spam = true
          modify_spam_message
        end
      end
    
    else
      @redis.hset recipient, "text", msg_text
      @redis.hincrby recipient, "count", 1
      @redis.expire recipient, CONTENT_FILTER_TIMEOUT
    end

    move_message_to_next_queue
    
    is_spam
  end

end

