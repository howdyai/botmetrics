class Stopwatch
  def self.record
    start = Time.current
    yield
    Time.current - start
  end
end
