# frozen_string_literal: true

RSpec.configure do |config|
  config.after(:each) do
    ClubIndex.find_each do |club_index|
      club_index.shard.destroy if club_index.shard.exists?
    end

    ClubIndex.destroy_all
  end
end
