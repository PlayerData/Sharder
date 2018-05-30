# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Database Switching" do
  describe "using the default shard" do
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

  describe "using another shard" do
    it "creates, updates, and destroys a model" do
      club_index = ClubIndex.create!(name: "Test")
      club_index.shard.create

      club_index.shard.switch do
        staff = Staff.create!(name: "Staff")
        staff.reload
        expect(staff.name).to eq "Staff"

        staff.update_attributes(name: "New Staff")
        staff.reload
        expect(staff.name).to eq "New Staff"

        staff.destroy
        expect { staff.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    it "correctly handles nested shard switch calls" do
      club_index = ClubIndex.create!(name: "Test")
      club_index.shard.create

      club_index2 = ClubIndex.create!(name: "Test 2")
      club_index2.shard.create

      club_index.shard.switch do
        club_index2.shard.switch do
          club2_staff = Staff.create!(name: "Club 2 Staff")
          club2_staff.reload
          expect(club2_staff.name).to eq "Club 2 Staff"
        end

        expect(Staff.count).to eq 0
        club1_staff = Staff.create!(name: "Club 1 Staff")
        club1_staff.reload
        expect(club1_staff.name).to eq "Club 1 Staff"
      end
    end
  end
end
