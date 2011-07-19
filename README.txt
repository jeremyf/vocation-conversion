# Blogger generates a massive XML file that doesn't have carriage returns.
# Apply those carriage returns for each entry so as not to overwhelm the
# parser
$ cat exported.blog.xml | sed "s/\<entry\>/\\`echo -e '\n\r'`<entry>/g" > blog.xml

# Sequence
bundle exec lib/parse_blog_posts.rb
bundle exec lib/copy_assets.rb