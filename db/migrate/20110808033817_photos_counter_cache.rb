class PhotosCounterCache < ActiveRecord::Migration
  class Post < ActiveRecord::Base; end
  def self.up
    add_column :posts, :photos_count, :integer, :null => :false, :default => 0
    if Post.count > 0
      counts = execute <<SQL
        SELECT posts.status_message_guid, COUNT(*) from posts GROUP BY posts.status_message_guid;
SQL
      counts.each do |count|
        Post.where(:guid => count[0]).update_all(:photos_count => count[1])
      end
    end
  end

  def self.down
    remove_column :posts, :photos_count
  end
end
