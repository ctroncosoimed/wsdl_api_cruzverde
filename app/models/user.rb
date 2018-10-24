class User < ActiveRecord::Base
  has_secure_token
  self.table_name = 'users'
end