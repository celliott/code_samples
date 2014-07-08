class Date
  def self.today_in_zone(zone = ::Time.zone)
    ::Time.find_zone!(zone).today
  end
end