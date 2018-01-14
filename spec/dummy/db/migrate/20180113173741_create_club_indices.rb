# frozen_string_literal: true

class CreateClubIndices < ActiveRecord::Migration[5.1]
  def change
    create_table :club_index do |t|
      t.string :name

      t.timestamps
    end
  end
end
