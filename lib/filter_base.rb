require 'redis'
require 'json'

class FilterBase

  def initialize(redis)
    @redis = redis
    @msg_hash = nil
    @dlr_err_code = "999"
    @name = "default"
  end

  protected

  def move_message_to_next_queue
    next_queue = @msg_hash["meta_data"]["to_queue"]
    @redis.rpush next_queue, JSON.dump(@msg_hash)
  end

  def modify_spam_message
    time = Time.now.strftime("%Y-%m-%d %H:%M:%S.%L")
    dlr = [{dlr_time: time,
            stat: "REJECTED",
            err: @dlr_err_code,
            error: "Rejected by Spam filter '#{@name}'"}]
    @msg_hash.delete "dlr"
    @msg_hash[:dlr] = dlr
  end

end

