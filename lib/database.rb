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
end


class Post < ActiveRecord::Base
  serialize :categories
end