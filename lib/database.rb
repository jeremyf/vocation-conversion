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
      table.column :title, :string
      table.column :thr_total, :integer
      table.column :from_url, :text
      table.column :thr_in_reply_to, :string
      table.column :conductor_admin_path, :string
    end

    create_table :categories, :force => force do |table|
      table.column :name, :string
      table.column :conductor_admin_path, :string
    end
    add_index :categories, :name

    create_table :assets, :force => force do |table|
      table.column :post_id, :integer
      table.column :source_url, :text
      table.column :conductor_asset_id, :integer
      table.column :local_filename, :text
    end
    add_index :assets, :post_id

  end
end


class Post < ActiveRecord::Base
  serialize :categories
  has_many :assets
  scope :not_comments, where("#{quoted_table_name}.thr_in_reply_to IS NULL")

  def news_attributes
    {
      :published_at => published,
      :title => title,
      :content => content,
      :custom_author_name => "Holy Cross Vocations Indiana Province",
      :category_ids => category_ids
    }
  end

  def public_conductor_path
    conductor_admin_path.sub("admin/",'')
  end

  def to_url
    File.join("http://vocation.nd.edu",public_conductor_path)
  end

  def category_ids
    Category.where("#{Category.quoted_table_name}.name IN (?)", categories).collect(&:conductor_id)
  end

  after_save {|obj| obj.categories.each {|cat| Category.find_or_create_by_name(cat)}}
end

class Asset < ActiveRecord::Base
  belongs_to :post

  def conductor_path
    "/assets/#{conductor_asset_id}/#{File.basename(local_filename)}"
  end
end

class Category < ActiveRecord::Base
  def conductor_attributes
    {:name => name}
  end

  def conductor_id
    conductor_admin_path.gsub(/^\/admin\/categories\//,'').to_i
  end
end