class DefaultSitesToActive < ActiveRecord::Migration[7.0]
  def change
    change_column_default :sites, :active, true
  end
end
