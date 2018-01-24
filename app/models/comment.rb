class Comment < ApplicationRecord
  belongs_to :review
  belongs_to :user
  validates :content, length: { minimum: 1 }

  def as_json(options = {})
    super(options.merge(include: :user))
  end
end
