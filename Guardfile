# Guard configuration aligned with easy_biz_host_app.

guard :bundler do
  require "guard/bundler"
  require "guard/bundler/verify"
  helper = Guard::Bundler::Verify.new

  files = ["Gemfile"]
  files += Dir["*.gemspec"] if files.any? { |f| helper.uses_gemspec?(f) }

  files.each { |file| watch(helper.real_path(file)) }
end

guard :rake, task: "bundle:audit:check" do
  watch("Gemfile")
  watch("Gemfile.lock")
end

guard :rubocop, cli: ["--parallel", "--format", "progress"], cmd: "./bin/rubocop" do
  watch(/.+\.rb$/)
  watch(%r{^app/views/(.+)/.+})
  watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
end

guard :minitest do
  watch(%r{^app/(.+)\.rb$}) { |m| "test/#{m[1]}_test.rb" }
  watch(%r{^app/views/(.+)/.+}) { |m| "test/controllers/#{m[1]}_controller_test.rb" }
  watch(%r{^test/(.*)/?(.*)_test\.rb$})
  watch(%r{^lib/(.*/)?([^/]+)\.rb$}) { |m| "test/#{m[1]}#{m[2]}_test.rb" }
  watch(%r{^test/test_helper\.rb$}) { "test" }
end
