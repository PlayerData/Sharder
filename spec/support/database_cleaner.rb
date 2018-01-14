# frozen_string_literal: true

RSpec.configure do |config|
  config.after(:each) do
    ClubIndex.find_each do |club_index|
      club_index.database.destroy if club_index.database.exists?
    end

    ClubIndex.destroy_all
  end
end
