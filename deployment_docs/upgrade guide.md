Gateway Server Upgrade
======================

**This guide is track upgrading the NYMTIC Transportation Information Gateway from 
	- ruby v2.2.0 to ruby v3.0.2
	- rails v4.**

## 1 - Update Ruby versions

	1 - update the file /.rubyversion from
	````
		ruby-2.2.0
	
	```
	to 
	```
		ruby-3.0.2
	
	```
	2 -
	Run the command
	 ```rvm install 3.0.2```

## 2 - Update the Gemfile 

1. Delete or rename ./Gemfile.lock
2. Upade lines 2 and 3 of Gemfile 
from
```
ruby '2.2.0'
gem 'rails', '4.1.6'

```
to 
```
ruby '3.0.2'
gem 'rails', '< 6'

```
3. Remove version specifications from any gems with version specifications

4. run `bundle install`





