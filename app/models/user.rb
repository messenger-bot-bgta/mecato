class User < ApplicationRecord
  belongs_to :shop, optional: true
end
