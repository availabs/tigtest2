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
