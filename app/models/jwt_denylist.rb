class JwtDenylist < ApplicationRecord

  self.table_name = 'jwt_denylist'

  validates :jti, presence: true, uniqueness: true

end
