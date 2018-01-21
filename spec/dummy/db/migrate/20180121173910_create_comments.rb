class CreateComments < ActiveRecord::Migration[5.1]
  self.shard_group = :clubs

  def change
    create_table :comments do |t|
      t.text :value
      t.references :staff, foreign_key: true

      t.timestamps
    end
  end
end
