<!-- markdownlint-disable-file MD013 -->

# Dependency Upgrade Issues and Solutions

## cannot load such file -- arel/visitors/bind_visitor

Solution: [rubygems activerecord5-redshift-adapter](https://rubygems.org/gems/activerecord5-redshift-adapter)

## Paritioned

### Problem summary

Latest version of Paritioned only supports activerecord v4.

- [rubygems partiioned](https://rubygems.org/gems/partitioned)
- [github fiksu/partitioned](https://github.com/fiksu/partitioned/)

```sh
$ bundle install
Warning: the running version of Bundler (2.1.4) is older than the version that created the lockfile (2.2.22). We suggest you to upgrade to the version that created the lockfile by running `gem install bundler:2.2.22`.
Fetching https://github.com/dkhofer/partitioned
Fetching gem metadata from https://rubygems.org/..........
Fetching gem metadata from https://rubygems.org/.
Resolving dependencies...
Bundler could not find compatible versions for gem "activerecord":
  In snapshot (Gemfile.lock):
    activerecord (= 5.2.6)

  In Gemfile:
    partitioned was resolved to 2.1.0, which depends on
      activerecord (~> 4.2.1)

    rails (= 5.2.6) was resolved to 5.2.6, which depends on
      activerecord (= 5.2.6)

Running `bundle update` will rebuild your snapshot from scratch, using only
the gems in your Gemfile, which may resolve the conflict.
```

### Where is it used?

```sh
$ ag partitioned --ignore-dir inspections
lib/gateway_reader.rb
1:# patch for /gems/partitioned-1.3.4/lib/partitioned/multi_level/configurator/reader.rb
3:module Partitioned
8:      # centralized source from multi level partitioned models
9:      class Reader < Partitioned::PartitionedBase::Configurator::Reader
18:                break if ancestor == Partitioned::PartitionedBase

lib/gateway_monkey_patch_postgres.rb
1:# Patch for /gems/partitioned-1.3.4/lib/monkey_patch_postgres.rb

lib/tasks/gateway.rake
98:    puts 'Speed Facts Partitioned.'

Gemfile
46:# https://github.com/fiksu/partitioned/issues/70#issuecomment-233443202

db/tasks/create_speed_fact_partitions.rb
1:# 1.3.4 version of Partitioned appears to be slightly incompatible

config/initializers/_gateway.rb
21:# Patch for /gems/partitioned-1.3.4/lib/monkey_patch_activerecord.rb

app/models/by_year.rb
1:class ByYear < Partitioned::ByIntegerField
8:  partitioned do |partition|

app/models/by_month.rb
1:class ByMonth < Partitioned::ByIntegerField
8:  partitioned do |partition|

app/models/speed_fact.rb
1:class SpeedFact < Partitioned::MultiLevel
22:  partitioned do |partition|
329:    # Assumes filters contains :year and :month for partitioned data

app/models/link_speed_fact.rb
1:class LinkSpeedFact < Partitioned::MultiLevel
16:  partitioned do |partition|
275:    # Assumes filters contains :year and :month for partitioned data
```

### Temporary solution

Removed the dependency.
This will cause all the above usages to break.

### Potential Remedies

- [Forked version?](https://github.com/fiksu/partitioned/issues/70)
- [rkrage/pg_party](https://github.com/rkrage/pg_party)
  - [working with partitioned tables in rails](https://lcx.wien/blog/working-with-partitioned-tables-in-rails/)

## NoMethodError: undefined method `whitelist_attributes=' for ActiveRecord::Base:Class

### Solution

See: [Rails issue 13740](https://github.com/rails/rails/issues/13740#issuecomment-121092380)

Commented out line in `config/application.rb`.

## NoMethodError: undefined method `mass_assignment_sanitizer=' for ActiveRecord::Base:Class

### Temporary Solution

Commented out the following lines:

```sh
$ ag mass_assignment_sanitizer
config/environments/test.rb
35:  config.active_record.mass_assignment_sanitizer = :strict

config/environments/development.rb
35:  config.active_record.mass_assignment_sanitizer = :strict
```

## Sprockets::Railtie::ManifestNeededError: Expected to find a manifest file in `app/assets/config/manifest.js`

### Sprockets Solution

Create the manifest file.

See [link](https://stackoverflow.com/a/58370129/3970755)

## NoMethodError: undefined method `attr_accessible' for User (call 'User.connection' to establish a connection):Class

Found [SO answer](https://stackoverflow.com/a/25499471/3970755)

Found [upgrading-from-rails-3-2-to-rails-4-0-active-record](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#upgrading-from-rails-3-2-to-rails-4-0-active-record)

> Rails 4.0 has removed attr_accessible and attr_protected feature in favor of
> Strong Parameters. You can use the Protected Attributes gem for a smooth
> upgrade path.

Encountered this:

```sh
$ bundle install
Fetching gem metadata from https://rubygems.org/..........
Resolving dependencies...
Bundler could not find compatible versions for gem "activemodel":
  In snapshot (Gemfile.lock):
    activemodel (= 5.2.6)

  In Gemfile:
    protected_attributes was resolved to 1.0.2, which depends on
      activemodel (< 5.0, >= 4.0.0.beta)

    rails (= 5.2.6) was resolved to 5.2.6, which depends on
      activemodel (= 5.2.6)

Running `bundle update` will rebuild your snapshot from scratch, using only
the gems in your Gemfile, which may resolve the conflict.
```

Found [https://rubygems.org/gems/protected_attributes_continued](https://rubygems.org/gems/protected_attributes_continued)

Install successful.

---

## 🎉🎉🎉🎉 `bundle exec rake assets:precompile` ran without errors

Whoot.

## config/puma.rb:7:in \`\_load_from': undefined method \`daemonize' for #\<Puma::DSL:0x0000556b302a4f18\> (NoMethodError)

- [Puma undefined local variable or method daemonize](https://stackoverflow.com/questions/67735620/puma-undefined-local-variable-or-method-daemonize-error)

### undefined method `daemonize' Temporary Solution

```diff
diff --git a/config/puma.rb b/config/puma.rb
index 4bdbaec..9a46671 100644
--- a/config/puma.rb
+++ b/config/puma.rb
@@ -4,7 +4,7 @@ bind  "unix://#{root}/tmp/sockets/puma.sock"
 pidfile "#{root}/tmp/pids/puma.pid"
 state_path "#{root}/tmp/sockets/puma.state"
 directory "#{root}"
-daemonize true
+# daemonize true
```

Possible option: [kigster/puma-daemon](https://github.com/kigster/puma-daemon)

See [Remove daemonization #2170](https://github.com/puma/puma/pull/2170#issuecomment-766405111)

> Please take a look - this functionality has been extracted into puma-daemon
> ruby gem. I would love some additional testing if you'd like to use
> daemonization with 5+ Puma

---

## 🎉🎉🎉🎉 `bundle exec puma -C config/puma.rb` ran

Whoot.

## undefined method `before_filter' for ApplicationController:Class

```sh
Routing Error

undefined method `before_filter' for ApplicationController:Class
Did you mean?  before_action

Rails.root: /home/paul/AVAIL/tig-docker/mount_dirs/gateway

Application Trace
app/controllers/application_controller.rb:3:in `<class:ApplicationController>'
app/controllers/application_controller.rb:1:in `<top (required)>'
app/controllers/views_controller.rb:1:in `<top (required)>'
```

- [Undefined method for 'before_filter'](https://stackoverflow.com/a/45015788/3970755)

```sh
$ ag before_filter
spec/controllers/views_controller_spec.rb
84:      controller.class.skip_before_filter :enforce_access_controls_show
97:      controller.class.skip_before_filter :enforce_access_controls_show

app/controllers/comments_controller.rb
2:  before_filter :enforce_ownership, only: [:show, :edit]
3:  before_filter :set_comment, only: [:show, :edit, :update, :block, :unblock, :destroy]

app/controllers/users_controller.rb
2:  before_filter :authenticate_user!

app/controllers/views_controller.rb
6:  before_filter :enforce_access_controls_show, only: [:chart, :map, :table, :show, :export_shp]
7:  before_filter :enforce_access_controls_update, only: [:edit]
8:  before_filter :enforce_ownership, only: [:chart, :map, :table]

app/controllers/registrations_controller.rb
2:  skip_before_filter :require_no_authentication, only: [:new, :create]

app/controllers/sources_controller.rb
2:  before_filter :enforce_access_controls, only: [:show, :edit]

app/controllers/passwords_controller.rb
2:  before_filter :validate_reset_password_token, only: :edit

app/controllers/application_controller.rb
3:  before_filter :configure_permitted_parameters, if: :devise_controller?
4:  before_filter :set_action_and_controller

app/controllers/snapshots_controller.rb
3:  before_filter :enforce_ownership, only: [:edit, :destroy]
```

### undefined method 'before_filter' Solution

```sh
ag before_filter -l | while read f; do sed -i 's/before_filter/before_action/g' "$f"; d
one
```

## A class was passed to `:class_name` but we are expecting a string.

### A class was passed to `:class_name` Solution

```diff
diff --git a/app/models/source.rb b/app/models/source.rb
index 4c327b1..d770db3 100644
--- a/app/models/source.rb
+++ b/app/models/source.rb
@@ -3,7 +3,7 @@ class Source < ActiveRecord::Base
   belongs_to :agency
   has_many :views
   has_many :uploads
-  belongs_to :rows_updated_by, class_name: User
+  belongs_to :rows_updated_by, class_name: "User"
```

## uninitialized constant Partitioned

### uninitialized constant Partitioned Solution

- See [Upgrade to Rails 5.1.7 and get ArgumentException on save #75](https://github.com/fiksu/partitioned/issues/75#issue-546246268)

```diff
diff --git a/Gemfile b/Gemfile
index 45f0045..cb616c3 100644
--- a/Gemfile
+++ b/Gemfile
@@ -44,6 +44,7 @@ gem 'momentjs-rails', '>= 2.8.1'
 gem 'bootstrap3-datetimepicker-rails', '~> 4.0.0'
 #gem 'whacamole'
 # https://github.com/fiksu/partitioned/issues/70#issuecomment-233443202
+gem 'partitioned', git: 'https://github.com/AirHelp/partitioned.git', branch: 'rails-5-2'
```

## Passing string to be evaluated in :if and :unless conditional options is not supported. Pass a symbol for an instance method, or a lambda, proc or block, instead.

### Passing string to be evaluated in :if and :unless Solution

See: [Rails: How to replace :if and :unless option for rails 5.2](https://stackoverflow.com/a/46720365/3970755)

```diff
diff --git a/app/models/comment.rb b/app/models/comment.rb
index c772440..3a4745f 100644
--- a/app/models/comment.rb
+++ b/app/models/comment.rb
@@ -6,7 +6,7 @@ class Comment < ActiveRecord::Base
   validates :user, presence: true
   validates :subject, presence: true
   validates :source, presence: true
-  validates :view, presence: true, unless: "app.nil?"
+  validates :view, presence: true, unless: -> { app.nil? }
```

## You tried to define an enum named "app" on the model "Comment", but this will generate a class method "table", which is already defined by ActiveRecord::Relation.

### Temporary You tried to define an enum named "app" Solution

- See [How to Migrate from Paperclip to Rails ActiveStorage Discussion](https://gorails.com/forum/how-to-migrate-from-paperclip-to-rails-activestorage-discussion#forum_post_11290)

```diff
diff --git a/app/models/comment.rb b/app/models/comment.rb
index 3a4745f..fb98bd7 100644
--- a/app/models/comment.rb
+++ b/app/models/comment.rb
@@ -8,7 +8,7 @@ class Comment < ActiveRecord::Base
   validates :source, presence: true
   validates :view, presence: true, unless: -> { app.nil? }

-  enum app: [ :table, :map, :chart, :metadata ]
+  # enum app: [ :table, :map, :chart, :metadata ]
```

---

## 🎉🎉🎉🎉 App renders

Whoot.

## undefined method `count' for #<ActionController

```sh
NoMethodError in ViewsController#table

undefined method `count' for #<ActionController::Parameters:0x00007fc8ec256478>
Extracted source (around line #6):

#4   def initialize(params, options={})
#5     puts params
*6     @col_count = params[:columns].count
#7     super
#8   end
#9
```

### undefined method `count' for #<ActionController Solution

See: [ActionController::Parameters deprecation warning: Method size is deprecated and will be removed in Rails 5.1](https://stackoverflow.com/questions/40256292/actioncontrollerparameters-deprecation-warning-method-size-is-deprecated-and)

## ActionView::Template::Error (uninitialized constant BootstrapBreadcrumbsBuilder (production only)

See: [ActionView::Template::Error "uninitialized constant `LibObject`](https://stackoverflow.com/a/51165512/3970755)

### uninitialized constant BootstrapBreadcrumbsBuilder Solution

```diff
diff --git a/config/application.rb b/config/application.rb
index b01f52c..79ab6b5 100644
--- a/config/application.rb
+++ b/config/application.rb
@@ -77,7 +77,8 @@ module NymtcGateway

     # Custom directories with classes and modules you want to be autoloadable.
     # config.autoload_paths += %W(#{config.root}/extras)
-    config.autoload_paths += %W(#{config.root}/lib)
+    # config.autoload_paths += %W(#{config.root}/lib)
+    config.eager_load_paths << Rails.root.join('lib')
```

## Client Uncaught TypeError: getUrlParam is not a function

Solution:

```diff
diff --git a/app/views/views/table.html.slim b/app/views/views/table.html.slim
index 472f9ef..3f812ee 100644
--- a/app/views/views/table.html.slim
+++ b/app/views/views/table.html.slim
@@ -136,7 +136,7 @@
 javascript:
-  var snapshot = getUrlParam('snapshot');
+  var snapshot = window.getUrlParam('snapshot');
```

## Leaflet

Solution: Lock the gem versions

```gemfile
# ========== Front-End::Leaflet ==========
# axyjo/leaflet-rails: This gem provides the leaflet.js map display library for your Rails 5 application.
gem 'leaflet-rails', '= 0.7.4'
# NOTE: The following two leaflet gems currently (2021-10-24) have zero stars on GitHub.
# https://rubygems.org/gems/leaflet-draw-rails
# igor-drozdov/leaflet-draw-rails: Leaflet.draw plugin for your Rails application.
gem 'leaflet-draw-rails', '= 0.1.0'
# zentrification/leaflet-providers-rails: leaflet-providers plugin packaged for the rails 3 asset pipeline
gem 'leaflet-providers-rails', github: 'zentrification/leaflet-providers-rails'
```

## NoMethodError - undefined method `simple_search' for #<UnpivotedDatatable

```log
NoMethodError - undefined method `simple_search' for #<UnpivotedDatatable:0x000056318b12f148>:
  app/datatables/unpivoted_datatable.rb:106:in `filter_records'
```

The server logs this error when the client requests data tables.
The error prevents the tables from populating and rendering.

The _'ajax-datatables-rails'_ gem adds the `AjaxDatatablesRails` module to the application.
This module is extended in the following classes:

```ruby
# app/datatables/pivoted_datatable.rb
class PivotedDatatable < AjaxDatatablesRails::Base
```

```ruby
# app/datatables/unpivoted_datatable.rb
class UnpivotedDatatable < AjaxDatatablesRails::Base
```

The `PivotedDatatable` and `UnpivotedDatatable` classes are used in _app/controllers/views_controller.rb_.

```sh
$ git rev-parse HEAD
a743db03882034dc28c8aae3ff11e6979f15fbc8
$ ag 'ivoted_table'
controllers/views_controller.rb
262:          pivoted_table = PivotedDatatable.new(params,
263:          # pivoted_table = PivotedDatatable.new(view_context,
273:          render text: (params[:filtered] ? pivoted_table.to_csv(@view) : @view.data_model.to_csv(@view))
287:        unpivoted_table = UnpivotedDatatable.new(view_context,
296:        format.json { render json: unpivoted_table }
300:          render text: (params[:filtered] ? unpivoted_table.to_csv(@view) : @view.data_model.to_csv(@view))
```

### Root cause of NoMethodError - undefined method `simple_search'

Prior to the application dependency upgrades, the application used
_ajax-datatables-rails (0.3.0)_ which was released January 30, 2015. The
current version, as of 2021-10-25, is \_(1.3.1) which was released February 09, 2021.

In version _ajax-datatables-rails (0.3.0)_, `simple_search` was [defined
](https://github.com/jbox-web/ajax-datatables-rails/blob/v0.3.0/lib/ajax-datatables-rails/base.rb#L95-L100)
as an instance method on `AjaxDatatablesRails::Base`.

```ruby
def simple_search(records)
  return records unless (params[:search].present? && params[:search][:value].present?)
  conditions = build_conditions_for(params[:search][:value])
  records = records.where(conditions) if conditions
  records
end
```

In version _ajax-datatables-rails (1.3.1)_, [`AjaxDatatablesRails:Datatable::SimpleSearch`](https://github.com/jbox-web/ajax-datatables-rails/blob/b79f3bfc78142516583616e66a37004c7d98fdd4/lib/ajax-datatables-rails/datatable/simple_search.rb#L5)
is a class that must be instantiated. See
[code](https://github.com/jbox-web/ajax-datatables-rails/blob/b79f3bfc78142516583616e66a37004c7d98fdd4/spec/ajax-datatables-rails/datatable/simple_search_spec.rb#L8).

NOTE: We could not rollback the version to _ajax-datatables-rails (0.3.0)_
because is is incompatible with the current `ActionController::Parameters` version:

```log
NoMethodError - undefined method `each_value' for #<ActionController::Parameters:0x0000555b426fc2a8>
Did you mean?  each_pair:
  ajax-datatables-rails (0.3.0) lib/ajax-datatables-rails/base.rb:76:in `sort_records'
```

Additionally, the `ajax-datatables-rails` gem is [no help](https://github.com/Shipstr/ajax-datatables-rails-alt-api/search?q=simple_search).

### undefined method `apps' for Comment

Stepping through the pre-upgrade code, we reach the following method in Rails' ActiveRecord Enum module.

```Ruby
klass.singleton_class.send(:define_method, name.to_s.pluralize) { enum_values }
```

See [rails/rails/blob/v4.1.6/activerecord/lib/active_record/enum.rb](https://github.com/rails/rails/blob/24027162dbe226acfbf3a91872237a9557764d72/activerecord/lib/active_record/enum.rb#L89)

In Rails v5.2.6, a very similar define_method line exists:

```Ruby
singleton_class.send(:define_method, name.pluralize) { enum_values }
```

Note: name is pluralized. The Enum name would be "app".

See [rails/rails/blob/v5.2.6/activerecord/lib/active_record/enum.rb](https://github.com/rails/rails/blob/48661542a2607d55f436438fe21001d262e61fec/activerecord/lib/active_record/enum.rb#L162)

Question: How is that Enum::enum method getting called?
By internal TIG code or an external Gem?

Answer: Internal TIG code.

Root of the problem: as a temporary fix to the "You tried to define an enum..." bug,
we commented out the `enum app` line from the Comment and Snapshot models.

```sh
git --no-pager show 2029849ac56c04dd14754f3ecbd57e1353a42946 app/models/comment.rb
```

```diff
commit 2029849ac56c04dd14754f3ecbd57e1353a42946
Author: Paul Tomchik <pauljtomchik@gmail.com>
Date:   Thu Oct 14 09:50:56 2021 -0400

    You tried to define an enum... but this will generate a...

diff --git a/app/models/comment.rb b/app/models/comment.rb
index 3a4745f..fb98bd7 100644
--- a/app/models/comment.rb
+++ b/app/models/comment.rb
@@ -8,7 +8,7 @@ class Comment < ActiveRecord::Base
   validates :source, presence: true
   validates :view, presence: true, unless: -> { app.nil? }

-  enum app: [ :table, :map, :chart, :metadata ]
+  # enum app: [ :table, :map, :chart, :metadata ]

   scope :first_n, ->(n) { order("created_at desc").limit(n)}
   scope :query_by, ->(source, view, app) {
```

Which means we are back to the following bug:

> You tried to define an enum named "app" on the model "Comment", but this will
> generate a class method "table", which is already defined by ActiveRecord::Relation.

Fix:

```diff
diff --git a/app/models/comment.rb b/app/models/comment.rb
index fb98bd7..762fb2f 100644
--- a/app/models/comment.rb
+++ b/app/models/comment.rb
@@ -9,6 +9,7 @@ class Comment < ActiveRecord::Base
   validates :view, presence: true, unless: -> { app.nil? }

   # enum app: [ :table, :map, :chart, :metadata ]
+  enum app: [ :chart, :metadata ]

   scope :first_n, ->(n) { order("created_at desc").limit(n)}
   scope :query_by, ->(source, view, app) {
```

## undefined method `<<' for #<StudyArea::ActiveRecord_Relation

Fix: See [Rails 5.0.1 issue-- undefined method `push'](https://github.com/rails/rails/issues/27998#issuecomment-279723414)

```diff
diff --git a/app/models/study_area.rb b/app/models/study_area.rb
index 58f4801..75a3473 100644
--- a/app/models/study_area.rb
+++ b/app/models/study_area.rb
@@ -15,7 +15,7 @@ class StudyArea < Area
     if user
       shared_study_areas = joins(:viewers).where(viewers_study_areas: {user_id: user.id})
       published_or_owned = where("areas.user_id = ? OR published = ?", user.id, true)
-      (published_or_owned << shared_study_areas).flatten.uniq
+      (published_or_owned.to_a << shared_study_areas).flatten.uniq
     else
       where(published: true)
     end
```

## NoMethodError - undefined method 'map' for #<ActionController

When trying to edit the TIP Project Data metadata, encountered the following error:

```sh
NoMethodError - undefined method `map' for #<ActionController::Parameters:0x00007fdfd09acbf0>
Did you mean?  tap:
  app/controllers/views_controller.rb:462:in `update'
```

The line of code:

```Ruby
updated_view[:columns] = updated_view[:columns].map(&:last) if updated_view[:columns]
```

Fix:

```diff
diff --git a/app/controllers/views_controller.rb b/app/controllers/views_controller.rb
index 0880187..3908985 100644
--- a/app/controllers/views_controller.rb
+++ b/app/controllers/views_controller.rb
@@ -1,3 +1,5 @@
 class ViewsController < ApplicationController

   before_action :get_view, only: [:show, :edit, :update, :destroy, :chart, :table, :map, :data_overlay, :export_shp, :demo_statistics, :feature_geometry, :layer_ui, :symbology, :update_year, :tmc_roadname, :link_roadname, :watch, :unwatch]
@@ -456,7 +458,8 @@ class ViewsController < ApplicationController
   # PUT /views/1
   # PUT /views/1.json`
   def update
-    updated_view = params[:view]
+    updated_view = params[:view].to_unsafe_h
```

## JSON::ParserError in ViewsController#update

Encountered the following error while trying to edit TIP Project data metadata name:

```log
From: /home/paul/AVAIL/tig-docker/mount_dirs/gateway/app/controllers/views_controller.rb:472 ViewsController#update:

    467:     updated_view[:column_types] = updated_view[:column_types].map(&:last) if updated_view[:column_types]
    468:     if updated_view[:value_columns]
    469:       updated_view[:value_columns] = updated_view[:value_columns].each_with_index.map{ |val_col, idx| updat
ed_view[:columns][idx] if val_col[1] == "true" }.compact
    470:     end
    471:     updated_view[:data_model] = updated_view[:data_model].constantize unless updated_view[:data_model].blan
k?
 => 472:     updated_view[:data_levels] = JSON.parse(updated_view[:data_levels]) if updated_view[:data_levels]
    473:     updated_view[:data_hierarchy] = JSON.parse(updated_view[:data_hierarchy]) if (updated_view[:data_hierar
chy] && !updated_view[:data_hierarchy].empty?)
    474:
    475:     respond_to do |format|
    476:       if @view.update_attributes(updated_view)
    477:         if @view.columns.reject(&:empty?).empty? && @view.data_model.present?

[1] pry(#<ViewsController>)> updated_view[:data_levels]
=> " "
[2] pry(#<ViewsController>)> JSON.parse(updated_view[:data_levels])
JSON::ParserError: 783: unexpected token at ''
from /home/paul/.rvm/rubies/ruby-2.7.4/lib/ruby/2.7.0/json/common.rb:156:in `parse'
[3] pry(#<ViewsController>)> updated_view
=> {"current_version"=>"1",
 "rows_updated_by_id"=>"194",
 "user_id"=>"194",
 "source_id"=>"47",
 "name"=>"2020-2024 TIP Mappable Projects (edited)",
 "description"=>"",
 "data_starts_at"=>"",
 "data_ends_at"=>"",
 "origin_url"=>"",
 "topic_area"=>"",
 "role_ids"=>["", "1", "2", "11", "12", "6", "9"],
 "data_levels"=>" ",
 "data_hierarchy"=>"",
 "spatial_level"=>"",
 "data_model"=>
  TipProject(id: integer, geography: text, view_id: integer, tip_id: string, ptype_id: integer, cost: float, mpo_id:
 integer, county_id: integer, sponsor_id: integer, description: text, created_at: datetime, updated_at: datetime),
 "columns"=>["tip_id", "ptype", "cost", "mpo", "county", "sponsor", "description"],
 "column_labels"=>["TIP ID", "Project Type", "Cost", "", "", "", ""],
 "column_types"=>["", "", "Millions", "", "", "", ""],
 "value_columns"=>[],
 "value_name"=>"value",
 "row_name"=>"",
 "column_name"=>"",
 "download_instructions"=>"",
 "contributor_ids"=>["194"],
 "librarian_ids"=>["194"]}
```

Note: Everything worked fine prior to dependency upgrades.

```log
From: /home/paul/AVAIL/tig-docker/mount_dirs/tigtest2/app/controllers/views_controller.rb @ line 471 ViewsController#update:

    466:     updated_view[:column_types] = updated_view[:column_types].map(&:last) if updated_view[:column_types]
    467:     if updated_view[:value_columns]
    468:       updated_view[:value_columns] = updated_view[:value_columns].each_with_index.map{ |val_col, idx| updated_view[:columns][idx] if val_col[1] == "true" }.compact
    469:     end
    470:     updated_view[:data_model] = updated_view[:data_model].constantize unless updated_view[:data_model].blank?
 => 471:     updated_view[:data_levels] = JSON.parse(updated_view[:data_levels]) if updated_view[:data_levels]
    472:     updated_view[:data_hierarchy] = JSON.parse(updated_view[:data_hierarchy]) if (updated_view[:data_hierarchy] && !updated_view[:data_hierarchy].empty?)
    473:
    474:     respond_to do |format|
    475:       if @view.update_attributes(updated_view)
    476:         if @view.columns.reject(&:empty?).empty? && @view.data_model.present?

[1] pry(#<ViewsController>)> updated_view[:data_levels]
=> "[\"\", \"\"]"
[2] pry(#<ViewsController>)> JSON.parse(updated_view[:data_levels])
=> ["", ""]
[3] pry(#<ViewsController>)> updated_view
=> {"current_version"=>"1",
 "rows_updated_by_id"=>"194",
 "user_id"=>"194",
 "source_id"=>"47",
 "name"=>"2020-2024 TIP Mappable Projects",
 "description"=>"",
 "data_starts_at"=>"",
 "data_ends_at"=>"",
 "origin_url"=>"",
 "topic_area"=>"",
 "role_ids"=>["1", "2", "11", "12", "", "6", "9"],
 "data_levels"=>"[\"\", \"\"]",
 "data_hierarchy"=>"",
 "spatial_level"=>"",
 "data_model"=>
  TipProject(id: integer, geography: text, view_id: integer, tip_id: string, ptype_id: integer, cost: float, mpo_id: integer, county_id: integer, sponsor_id: integer, description: text, created_at: datetime, updated_at: datetime),
 "columns"=>["tip_id", "ptype", "cost", "mpo", "county", "sponsor", "description"],
 "column_labels"=>["TIP ID", "Project Type", "Cost", "", "", "", ""],
 "column_types"=>["", "", "Millions", "", "", "", ""],
 "value_columns"=>[],
 "value_name"=>"value",
 "row_name"=>"",
 "column_name"=>"",
 "download_instructions"=>"",
 "contributor_ids"=>["194"],
 "librarian_ids"=>["194"]}
```

Diff of the updated_views ("<" is master branch, ">" is rrupgrade branch).

```diff
11,12c11,12
<  "role_ids"=>["1", "2", "11", "12", "", "6", "9"],
<  "data_levels"=>"[\"\", \"\"]",
---
>  "role_ids"=>["", "1", "2", "11", "12", "6", "9"],
>  "data_levels"=>" ",
16,17c16
<   TipProject(id: integer, geography: text, view_id: integer, tip_id: string, ptype_id: integer, cost: float, mpo_id: integer, county_id: integer, sponsor_id: integer, description: text,
< created_at: datetime, updated_at: datetime),
---
>   TipProject(id: integer, geography: text, view_id: integer, tip_id: string, ptype_id: integer, cost: float, mpo_id: integer, county_id: integer, sponsor_id: integer, description: text, created_at: datetime, updated_at: datetime),
28d26
<
```

Why are the role_ids & data_levels different?

Fix for data_levels JSON Parse problem:

```diff
diff --git a/app/controllers/views_controller.rb b/app/controllers/views_controller.rb
index 0880187..f70dba2 100644
--- a/app/controllers/views_controller.rb
+++ b/app/controllers/views_controller.rb
@@ -456,7 +456,7 @@ class ViewsController < ApplicationController
   # PUT /views/1
   # PUT /views/1.json`
   def update
-    updated_view = params[:view]
+    updated_view = params[:view].to_unsafe_h
     updated_view[:contributor_ids] = updated_view[:contributor_ids].reject(&:blank?) if updated_view[:contributor_ids]
     updated_view[:librarian_ids] = updated_view[:librarian_ids].reject(&:blank?) if updated_view[:librarian_ids]
     updated_view[:columns] = updated_view[:columns].map(&:last) if updated_view[:columns]
diff --git a/app/views/views/_form.html.slim b/app/views/views/_form.html.slim
index a601818..ad9a362 100644
--- a/app/views/views/_form.html.slim
+++ b/app/views/views/_form.html.slim
@@ -37,7 +37,7 @@
               = f.association :roles, collection: Action.all_actions_filtered, as: :check_boxes, label: "Actions", label_method: lambda {|r| r.name.titleize }, value_method: :id, item_wrapper_class: "col-md-4", checked: (@view.role_ids.empty? ? [Action.find_by(name: "view_metadata").id, Action.find_by(name: "edit_metadata").id] : @view.role_ids)
               = f.hidden_field('role_ids][', value: Action.where(name: 'edit_metadata').pluck(:id).first)
               = f.hidden_field('role_ids][', value: Action.where(name: 'view_metadata').pluck(:id).first)
-              = f.hidden_field :data_levels, value: @view.data_levels
+              = f.hidden_field :data_levels, value: @view.data_levels.to_s
               = f.hidden_field :data_hierarchy, value: @view.data_hierarchy
               = f.hidden_field :spatial_level, value: @view.spatial_level
             - selected_model = @view.data_model.present? ? @view.data_model : source.default_data_model
```
