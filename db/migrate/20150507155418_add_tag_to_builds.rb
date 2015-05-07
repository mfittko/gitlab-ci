class AddTagToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :tag, :string
  end
end
