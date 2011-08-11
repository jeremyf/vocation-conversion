require 'active_record'

ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.colorize_logging = false

ActiveRecord::Base.establish_connection(
:adapter => "sqlite3",
:database => 'blog_posts.sqlite'

)


# ["category", "author", "title", "published", "id", "content", "link", "updated", "thr:total"],
# ["category", "author", "title", "published", "id", "content", "link", "updated", "thr:total"],
# ["category", "author", "title", "published", "id", "content", "link", "updated", "thr:in-reply-to"],
# ["category", "author", "title", "published", "id", "content", "link", "updated"]
def init_db(force = false)
  ActiveRecord::Schema.define do
    create_table :posts, :force => force do |table|
      table.column :categories, :text
      table.column :author_name, :string
      table.column :author_email, :string
      table.column :blogger_id, :string
      table.column :content, :text
      table.column :published, :datetime
      table.column :updated, :datetime
      table.column :thr_total, :integer
      table.column :thr_in_reply_to, :string
    end
  end

  ActiveRecord::Schema.define do
    create_table :assets, :force => force do |table|
      table.column :post_id, :integer
      table.column :source_url, :text
      table.column :conductor_asset_id, :integer
      table.column :local_filename, :text
    end
  end
end


class Post < ActiveRecord::Base
  serialize :categories
  has_many :assets
end

class Asset < ActiveRecord::Base
  belongs_to :post

  def path
    "/assets/#{conductor_asset_id}/#{File.basename(local_filename)}"
  end
end