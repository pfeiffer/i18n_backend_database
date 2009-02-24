class Translation < ActiveRecord::Base
  belongs_to :locale
  validates_presence_of :key
  before_create :generate_hash_key
  after_update  :update_cache

  named_scope :untranslated, :conditions => {:value => nil}
  named_scope :translated,   :conditions => "value IS NOT NULL"

  def default_locale_value(rescue_value='No default locale value')
    begin
      Locale.default_locale.translations.find_by_key_and_pluralization_index(self.key, self.pluralization_index).value
    rescue
      rescue_value
    end
  end

  def value_or_default(key)
    self.value || self.default_locale_value(key)
  end

  # create hash key
  def self.hk(key)
    Base64.encode64(Digest::MD5.hexdigest(key))
  end

  # create cache key
  def self.ck(locale, key, pluralization_index, hash=true)
    key = self.hk(key) if hash
    "#{locale.code}:#{key}:#{pluralization_index}"
  end

  def self.find_image_tags(dir="app/views", search_string="translated_image_tag")
    images = []
    Dir.glob("#{dir}/*").each { |item|
puts item, search_string      
      if File.directory?(item)
        images += find_image_tags(item)
      else
        File.readlines(item).each { |l|
          l.grep(/#{search_string}/) { |r|
            images.push(r[/\('(.*?)'\)/, 1] || r[/\("(.*?)"\)/, 1])
          }
      }
    end
    }
    images
  end


  protected
    def generate_hash_key
      self.key = Translation.hk(key)
    end

    def update_cache
      new_cache_key = Translation.ck(self.locale, self.key, self.pluralization_index, false)
      I18n.backend.cache_store.write(new_cache_key, self.value)
    end
end
