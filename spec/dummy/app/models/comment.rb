class Comment < ApplicationRecord
  belongs_to :staff, touch: :last_comment
end
