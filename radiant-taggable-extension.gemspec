# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{radiant-taggable-extension}
  s.version = "1.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["spanner"]
  s.date = %q{2011-03-13}
  s.description = %q{General purpose tagging extension: more versatile but less focused than the tags extension}
  s.email = %q{will@spanner.org}
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    ".gitignore",
     "README.md",
     "Rakefile",
     "VERSION",
     "app/controllers/admin/taggings_controller.rb",
     "app/controllers/admin/tags_controller.rb",
     "app/models/tag.rb",
     "app/models/tagging.rb",
     "app/views/admin/pages/_edit_title.html.haml",
     "app/views/admin/tags/_form.html.haml",
     "app/views/admin/tags/_search_results.html.haml",
     "app/views/admin/tags/cloud.html.haml",
     "app/views/admin/tags/edit.html.haml",
     "app/views/admin/tags/index.html.haml",
     "app/views/admin/tags/new.html.haml",
     "app/views/admin/tags/show.html.haml",
     "config/routes.rb",
     "db/migrate/001_create_tags.rb",
     "db/migrate/002_import_keywords.rb",
     "lib/natcmp.rb",
     "lib/radiant-taggable-extension.rb",
     "lib/taggable_admin_page_controller.rb",
     "lib/taggable_admin_ui.rb",
     "lib/taggable_model.rb",
     "lib/taggable_page.rb",
     "lib/taggable_tags.rb",
     "lib/tasks/taggable_extension_tasks.rake",
     "public/images/admin/new-tag.png",
     "public/images/admin/tag.png",
     "public/stylesheets/admin/tags.css",
     "public/stylesheets/sass/tagcloud.sass",
     "radiant-taggable-extension.gemspec",
     "spec/datasets/tag_sites_dataset.rb",
     "spec/datasets/tags_dataset.rb",
     "spec/lib/taggable_page_spec.rb",
     "spec/models/tag_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "taggable_extension.rb"
  ]
  s.homepage = %q{http://github.com/spanner/radiant-taggable-extension}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Taggable Extension for Radiant CMS}
  s.test_files = [
    "spec/datasets/tag_sites_dataset.rb",
     "spec/datasets/tags_dataset.rb",
     "spec/lib/taggable_page_spec.rb",
     "spec/models/tag_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<radiant>, [">= 0.9.0"])
    else
      s.add_dependency(%q<radiant>, [">= 0.9.0"])
    end
  else
    s.add_dependency(%q<radiant>, [">= 0.9.0"])
  end
end

