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

  describe "using another database" do
    it "creates, updates, and destroys a model" do
      club_index = ClubIndex.create!(name: "Test")
      club_index.database.create

      club_index.database.switch do
        staff = Staff.create!(name: "Staff")
        staff.reload
        expect(staff.name).to eq "Staff"

        staff.update_attributes(name: "New Staff")
        staff.reload
        expect(staff.name).to eq "New Staff"

        staff.destroy
        expect { staff.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      club_index.database.destroy
      club_index.destroy
    end
  end
end
