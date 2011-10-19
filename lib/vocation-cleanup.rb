#!/usr/bin/env /Users/jeremyf/Sites/conductor/script/rails runner

site = Site.find_by_domain('vocation.conductor.nd.edu')
site.news.each { |news|
  doc = Hpricot(news.content)
  doc.search("*[@style]']").each { |ele|
    ele.remove_attribute('style') if ele.respond_to?(:remove_attribute)
  }
  news.content = doc.to_html
  news.save!
}
