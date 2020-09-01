# Comparing Ruby environments on Vercel and Render.com

This README is for an example project that compares Ruby environments on [Vercel](https://vercel.com/) and [Render.com](https://render.com/). The goal is to compare the capability to deploy Ruby functions as API endpoints on the Vercel and Render.com platforms.

This project is a work in progress and currently details some unresolved issues with Vercel. The code runs successfully on Render.com so I’m hoping to resolve the issues on Vercel.

## Example project

Code for the example is on GitHub at [https://github.com/DanielKehoe/ruby-trial](https://github.com/DanielKehoe/ruby-trial). You can fork the project and deploy on either Vercel or Render.com.

Here’s the project structure:

```bash
$ tree
.
├── Gemfile
├── Gemfile.lock
├── api
│   ├── Gemfile
│   ├── Gemfile.lock
│   └── try-vercel.rb
├── render.yaml
└── try-render.rb
```

The top level folder contains code for Render.com.
- `render.yaml` provides settings for Render.com deployment
- `try-render.rb` is a trial Ruby function implemented for Render.com
- `Gemfile` and `Gemfile.lock` specify required gems

The `api` folder contains code for Vercel.
- Vercel doesn’t require a file for build settings
- `try-vercel.rb` is a trial Ruby function implemented for Vercel
- `Gemfile` and `Gemfile.lock` specify required gems

## Installing gems

Before testing locally or deploying on Vercel or Render.com, you must install the needed gems. Remove `Gemfile.lock` to create a pristine environment. Then run `bundle install` in both the top level (Render.com) and `api` (Vercel) folders to create a `Gemfile.lock` for both hosting environments.

```bash
$ rm Gemfile.lock
$ rm ./api/Gemfile.lock
$ bundle install
$ cd api
$ bundle install
$ cd ../
```

## Running locally

The `try-render.rb` program can be run locally as it provides a complete web server implementation.

```bash
$ ruby ./try-render.rb
```

Open a browser and visit [http://localhost:8000/](http://localhost:8000/). You’ll see:

```bash
 _____________
| Hello World |
 -------------
      \   ^__^
       \  (oo)\_______
          (__)\       )\/\
              ||----w |
              ||     ||
```

The console shows the gem versions and load path:

```bash
Cowsay gem version: 0.3.0
WEBrick gem version: 1.6.0
Fauna gem version: 3.0.0
Nokogiri gem version: 1.10.10
$LOAD_PATH: ["/Users/danielkehoe/.gem/ruby/2.7.0/gems/cowsay-0.3.0/lib”,]
…
```

After verifying the program runs successfully locally, deploy and test on Vercel and Render.com.

## Deploying on Vercel

## Deploying on Render.com

## Gemfile

The Gemfile is designed to test three aspects of Ruby support that can be problematic:
- installing an ordinary gem from [rubygems.org](rubygems.org)
- installing a gem from a GitHub repository and branch
- installing a gem that has to be built with native extensions

** Gemfile**

```ruby
source "https://rubygems.org"
gem 'cowsay'
gem 'fauna', github: 'igas/faunadb-ruby', branch: 'patch-1'
gem 'nokogiri'
```

The [cowsay](https://github.com/johnnyt/cowsay) gem is an ordinary gem and installs successfully on either Vercel or Render.com.

The [fauna](https://github.com/igas/faunadb-ruby/tree/patch-1) gem is a fork of a gem that is not currently maintained. It is an example of a common situation in the Ruby world. In this case, a developer has forked a gem and patched it with an update. The update has not been published on the rubygems server so it must be installed from GitHub. [Bundler documentation](https://bundler.io/guides/git.html) shows several formats for specifying a gem to be installed from GitHub. The gem installs successfully on Render.com but **fails to install on Vercel.**

The [nokogiri](https://nokogiri.org/) gem requires native extensions. Nokogiri is a dependency for many other Ruby gems so it is important that it can be installed successfully. It installs successfully on either Vercel or Render.com.

## Vercel trial function

**try-vercelrb**

```ruby
require 'rubygems'
require 'cowsay'
require 'fauna'
require 'nokogiri'

puts("Cowsay gem version: " + Cowsay::VERSION)
puts("WEBrick gem version: " + WEBrick::VERSION)
puts("Fauna gem version: " + Fauna::VERSION)
puts("Nokogiri gem version: " + Nokogiri::VERSION)
puts("$LOAD_PATH: " + $LOAD_PATH.to_s)

Handler = Proc.new do |req, res|
  name = req.query['name'] || 'World'
  res.status = 200
  res['Content-Type'] = 'text/text; charset=utf-8'
  res.body = Cowsay.say("Hello #{name}", 'cow')
end
```

In the Ruby environment, Vercel provides a default WEBrick server with routing to handle any request to the `api` directory.

The program loads the required gems and writes the gem version information to the standard output (it will appear in the function log files). Then it writes the `$LOAD_PATH` which shows where the gems are installed.

In response to an HTTP request, the function responds with a “Hello World” message.

## Render.com trial function

**try-render.rb**

```ruby
require 'rubygems'
require 'cowsay'
require 'fauna'
require 'nokogiri'
require 'webrick'

puts("Cowsay gem version: " + Cowsay::VERSION)
puts("WEBrick gem version: " + WEBrick::VERSION)
puts("Fauna gem version: " + Fauna::VERSION)
puts("Nokogiri gem version: " + Nokogiri::VERSION)
puts("$LOAD_PATH: " + $LOAD_PATH.to_s)

class Handler < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    name = req.query['name'] || 'World'
    res.status = 200
    res['Content-Type'] = 'text/text; charset=utf-8'
    res.body = Cowsay.say("Hello #{name}", 'cow')
  end
end

server = WEBrick::HTTPServer.new(:Port => 8000)
server.mount("/", Handler)

['INT', 'TERM'].each {|signal|
  trap(signal) {server.shutdown}
}

server.start()
```

Unlike Vercel, Render.com does not provide a default web server so the Ruby function must require the WEBrick gem and implement code to initialize a server and respond to a GET request..

The program loads the required gems and writes the gem version information to the standard output (it will appear in the function log files). Then it writes the `$LOAD_PATH` which shows where the gems are installed.

In response to an HTTP request, the function responds with a “Hello World” message.
