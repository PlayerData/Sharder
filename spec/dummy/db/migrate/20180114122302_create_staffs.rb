# frozen_string_literal: true

class CreateStaffs < ActiveRecord::Migration[5.1]
  self.shard_group = :clubs

  def change
    create_table :staffs do |t|
      t.string :name

      t.timestamps
    end
  end
end
