# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sharder do
  describe "using the default database" do
    it "creates, updates, and destroys a model" do
      club_index = ClubIndex.create!(name: "Test")
      club_index.reload
      expect(club_index.name).to eq "Test"

      club_index.update_attributes(name: "New Test")
      club_index.reload
      expect(club_index.name).to eq "New Test"

      club_index.destroy
      expect { club_index.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
