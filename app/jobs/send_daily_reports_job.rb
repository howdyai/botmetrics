class SendDailyReportsJob < Job
  def perform
    DailyReportsService.new.send_now
  end
end
