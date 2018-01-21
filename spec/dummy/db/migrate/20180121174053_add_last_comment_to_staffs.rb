class AddLastCommentToStaffs < ActiveRecord::Migration[5.1]
  self.shard_group = :clubs

  def change
    add_column :staffs, :last_comment, :datetime
  end
end
