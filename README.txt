# Blogger generates a massive XML file that doesn't have carriage returns.
# Apply those carriage returns for each entry
$ cat exported.blog.xml | sed "s/\<entry\>/\\`echo -e '\n\r'`<entry>/g" > blog.xml
