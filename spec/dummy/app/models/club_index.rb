# frozen_string_literal: true

class ClubIndex < ApplicationRecord
  self.table_name = "club_index"

  def shard_name
    "sharder_dummy_#{Rails.env}_club_#{id}"
  end

  def shard
    Sharder::Shard.new(shard_name, :clubs)
  end
end
