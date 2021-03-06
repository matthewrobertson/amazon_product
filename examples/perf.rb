require File.expand_path('../helper.rb', __FILE__)

@lock, @store = Mutex.new, Hash.new

def timestamp
  Time.now.strftime('%m-%d %H:00')
end

Thread.new do
  req = AmazonProduct['us']

  req.configure do |c|
    c.key    = YOUR_AMAZON_KEY
    c.secret = YOUR_AMAZON_SECRET
    c.tag    = YOUR_AMAZON_ASSOCIATE_TAG
  end

  count = 0
  loop do
    Asin.each_slice(10) do |batch|
      started_at = Time.now.to_f
      resp = req.find(batch, :version        => '2010-11-01',
                             :merchant_id    => 'All',
                             :condition      => 'All',
                             :response_group => 'OfferFull')

      @lock.synchronize do
        ts = timestamp
        @store[ts] ||= { error: 0, ok: 0 }
        if resp.valid?
          @store[ts][:ok] += 1
        else
          @store[ts][:error] += 1
        end
      end

      time_elapsed = Time.now.to_f - started_at
      sleep time_elapsed if time_elapsed < 1.0
    end
  end
end

in_your_shell
