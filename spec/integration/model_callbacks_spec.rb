# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Model Callbacks" do
  it "touches associations correctly" do
    club_index = ClubIndex.create!(name: "Test")
    club_index.database.create

    club_index.database.switch do
      staff = Staff.create!(name: "Test Staff")

      travel 1.hour

      Comment.create!(staff: staff, value: "Some Comment")

      staff.reload
      expect(staff.updated_at).to eq Time.now
      expect(staff.last_comment).to eq Time.now
    end
  end
end
