if defined?(RuCaptcha)
  RuCaptcha.configure do
    self.skip_cache_store_check = true
    self.cache_store = [:file_store, Rails.root.join("tmp/cache/rucaptcha/session")]
  end
end
