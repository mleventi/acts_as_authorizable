class Role < ActiveRecord::Base
  def allows?(permission)
    d = self.permissions.split(',').detect { |p| p.strip == permission }
    return !d.nil?
  end  
end
