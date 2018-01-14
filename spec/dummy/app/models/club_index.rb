# frozen_string_literal: true

class ClubIndex < ApplicationRecord
  self.table_name = "club_index"

  def database_name
    "sharder_dummy_#{Rails.env}_club_#{id}"
  end

  def database
    Sharder::Database.new(database_name, :clubs)
  end
end
