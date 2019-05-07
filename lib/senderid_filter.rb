FILTER_SENDERID_MAX_COUNT = 20
SENDER_ID_TIMEOUT = 60 * 60

class SenderIdFilter < FilterBase

  def initialize(redis)
    @redis = redis
    @msg_hash = nil
    @dlr_err_code = "007"
    @name = "SenderIdFilter"
  end

  def check(msg_hash)
    @msg_hash = msg_hash

    is_spam = false
    recipient = @msg_hash["mt_sms"]["to"]
    senderID = @msg_hash["mt_sms"]["from"]
    key = "#{recipient}:#{senderID}"

    if @redis.exists key
      @redis.incr key
    else
      @redis.incr key
      @redis.expire key, SENDER_ID_TIMEOUT
    end

    from_same_sender_count = @redis.get("#{recipient}:#{senderID}").to_i
    if from_same_sender_count > FILTER_SENDERID_MAX_COUNT
      puts "Spam: SenderIdFilter"
      is_spam = true
      modify_spam_message
    end

    move_message_to_next_queue

    is_spam
  end

end

