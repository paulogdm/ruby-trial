# Comparing Ruby environments on Vercel and Render.com

_9/1/20_
_9/2/20_

This README is for an example project that compares Ruby environments on [Vercel](https://vercel.com/) and [Render.com](https://render.com/). The goal is to compare the capability to deploy Ruby functions as API endpoints on the Vercel and Render.com platforms.

This project is a work in progress and currently details some unresolved issues with Vercel. The code runs successfully on Render.com so I’m hoping to resolve the issues on Vercel.

## Questions for Vercel Support

Should the Gemfile be placed in the project root directory or in the  `api` directory?

What is the correct “Build Command” and “Output Directory” settings to run  `bundle update` (in order to install a gem from GitHub) and serve Ruby functions from an `api` directory?

When “Build Command” and “Output Directory” are not set, how are Ruby gems installed? Does `bundle install` run by default for a Ruby function? Why is there no logging of bundler output in the build logs during a default deploy?

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

## Gemfile

The Gemfile is designed to test three aspects of Ruby support that can be problematic:
- installing an ordinary gem from [rubygems.org](rubygems.org)
- installing a gem from a GitHub repository and branch
- installing a gem that has to be built with native extensions

*Gemfile*

```ruby
source "https://rubygems.org"
gem 'cowsay'
gem 'fauna', github: 'igas/faunadb-ruby', branch: 'patch-1'
gem 'nokogiri'
```

The [cowsay](https://github.com/johnnyt/cowsay) gem is an ordinary gem and installs successfully on either Vercel or Render.com.

The [fauna](https://github.com/igas/faunadb-ruby/tree/patch-1) gem is a fork of a gem that is not currently maintained. It is an example of a common situation in the Ruby world. In this case, a developer has forked a gem and patched it with an update. The update has not been published on the rubygems server so it must be installed from GitHub. [Bundler documentation](https://bundler.io/guides/git.html) shows several formats for specifying a gem to be installed from GitHub. The gem installs successfully on Render.com but *fails to install on Vercel.*

The [nokogiri](https://nokogiri.org/) gem requires native extensions. Nokogiri is a dependency for many other Ruby gems so it is important that it can be installed successfully. It installs successfully on either Vercel or Render.com.

## Vercel trial function

This is a simple Ruby function that requires the gems described above. It doesn’t run successfully on Vercel.

*try-vercelrb*

```ruby
require 'rubygems'
require 'cowsay'
require 'fauna'
require 'nokogiri'

puts("Cowsay gem version: " + Cowsay::VERSION)
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

I’ve tried a similar function on Render.com for comparison to Vercel. It can be deployed and run successfully on Render.com.

*try-render.rb*

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

Here is the local `Gemfile.lock`:

```bash
GIT
  remote: https://github.com/igas/faunadb-ruby.git
  revision: f09176e27edb4efbb2996a2c12197fb06b17d3ac
  branch: patch-1
  specs:
    fauna (3.0.1.pre.1)
      faraday (~> 1.0)
      json (~> 2.3)
      net-http-persistent (~> 2.9)

GEM
  remote: https://rubygems.org/
  specs:
    cowsay (0.3.0)
    faraday (1.0.1)
      multipart-post (>= 1.2, < 3)
    json (2.3.1)
    mini_portile2 (2.4.0)
    multipart-post (2.1.1)
    net-http-persistent (2.9.4)
    nokogiri (1.10.10)
      mini_portile2 (~> 2.4.0)

PLATFORMS
  ruby

DEPENDENCIES
  cowsay
  fauna!
  nokogiri

BUNDLED WITH
   2.1.2
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

I’m able to deploy and run the function with Vercel default build settings without the fauna gem. When I add the fauna gem, the function fails with an error

```bash
"cannot load such file -- fauna"
```

I’ve tried several scenarios to deploy on Vercel to try to determine what settings are needed to successfully deploy this project.

### Simple successful deploy

For the first trial, I removed the Fauna gem from the `try-vercel.rb` file.

*try-vercel.rb*

```ruby
require 'rubygems'
require 'cowsay'
# require 'fauna'
require 'nokogiri'

puts("Cowsay gem version: " + Cowsay::VERSION)
# puts("Fauna gem version: " + Fauna::VERSION)
puts("Nokogiri gem version: " + Nokogiri::VERSION)
puts("$LOAD_PATH: " + $LOAD_PATH.to_s)

Handler = Proc.new do |req, res|
  name = req.query['name'] || 'World'
  res.status = 200
  res['Content-Type'] = 'text/text; charset=utf-8'
  res.body = Cowsay.say("Hello #{name}", 'cow')
end
```

From the Vercel dashboard, import a project. Choose “Import Git Repository” and continue. Enter the URL of the Git repository [https://github.com/DanielKehoe/ruby-trial](https://github.com/DanielKehoe/ruby-trial) and click “Deploy.” Select the root folder as the source for the project’s code. Use “ruby-trial” as the project name. Use “Other” as the “Framework Preset.” I’m not setting “Build and Output Settings.” The Build Command is set to “Override” with no settings (blank) and the Output Directory is set to “Override” with no settings (blank). Choose “Deploy”.

The log files show the build progress.

```bash
11:54:17.181    Cloning github.com/DanielKehoe/ruby-trial (Branch: master, Commit: 2dccea2)
11:54:17.673    Cloning completed in 492ms
11:54:17.674    Analyzing source code...
11:54:18.341    Uploading build outputs...
11:54:19.400    Installing build runtime...
11:54:20.781    Build runtime installed: 1380.154ms
11:54:21.189    Looking up build cache...
11:54:21.229    Build cache not found
11:55:00.145    Uploading build outputs...
11:55:03.768    Done with "api/try-vercel.rb"
```

After “Congratulations! Your project has been successfully deployed” open the dashboard. Open the function log page before trying the website. Then go to
[https://ruby-trial.vercel.app/api/try-vercel](https://ruby-trial.vercel.app/api/try-vercel)

The function runs successfully and the page displays:

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

My questions:
- The build log does not show any gems being installed. How are the gems installed? Does `bundle install` run by default for a Ruby function? Why is there no logging of `bundle install` output?

### Deploy with GitHub-sourced gem fails

Next I will try restoring the Fauna gem to the `try-vercel.rb` file.

*try-vercel.rb*

```ruby
require 'rubygems'
require 'cowsay'
require 'fauna'
require 'nokogiri'

puts("Cowsay gem version: " + Cowsay::VERSION)
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

Push to GitHub for an automatic deployment.

The log files will show the build progress.

```bash
14:44:10.703    Cloning github.com/DanielKehoe/ruby-trial (Branch: master, Commit: a5696a2)
14:44:11.378    Cloning completed in 675ms
14:44:11.379    Analyzing source code...
14:44:12.073    Uploading build outputs...
14:44:13.124    Installing build runtime...
14:44:14.719    Build runtime installed: 1594.935ms
14:44:15.143    Looking up build cache...
14:44:15.181    Build cache not found
14:44:55.844    Uploading build outputs...
14:44:59.209    Done with "api/try-vercel.rb"
```

Again the log files do not show any gems getting installed.

Open the function log page before trying the website. Then go to
[https://ruby-trial.vercel.app/api/try-vercel](https://ruby-trial.vercel.app/api/try-vercel)

The browser will show an application error:

```bash
502: BAD_GATEWAY
Code: NO_RESPONSE_FROM_FUNCTION
ID: sin1::n7mqj-1599029156692-f8d6cfe17096
```

The function log will show an error:

```bash
[GET] /api/try-vercel
14:46:50:76
Critical exception from handler{
  "errorMessage": "cannot load such file -- fauna",
  "errorType": "Function<LoadError>",
  "stackTrace": [
    "/var/lang/lib/ruby/site_ruby/2.7.0/rubygems/core_ext/kernel_require.rb:92:in `require'",
    "/var/lang/lib/ruby/site_ruby/2.7.0/rubygems/core_ext/kernel_require.rb:92:in `require'",
    "/var/task/api/try-vercel.rb:3:in `<top (required)>'",
    "/var/task/now__handler__ruby.rb:29:in `require_relative'",
    "/var/task/now__handler__ruby.rb:29:in `webrick_handler'",
    "/var/task/now__handler__ruby.rb:96:in `now__handler'"
  ]
}
Unknown application error occurred
Function<LoadError>
```

This error originates from the code in *try-vercelrb* at line 3:

```ruby
require 'fauna'
```

Presumably the fauna gem was not loaded from GitHub during the default build process.

### Troubleshooting gem errors on Vercel

The [Vercel Ruby documentation](https://vercel.com/docs/runtimes#official-runtimes/ruby) is limited. All it says about gems is:


### Looked at Build Step documentation

I will try with the “Build Command” set to `bundle update`. Toggle “Override” and then enter

```ruby
bundle update
```

The example shows ``bundle update`` with backticks. I’m not sure backticks are required, so I will not enter backticks.

The documentation says, for “Output Directory”: “If you turn on the Override toggle and leave the field empty, the build step will be skipped.” That means  `bundle update` won’t run. So I won’t override the “Output Directory” setting.

“Contents in this output directory will be the only things that will be statically served by Vercel. By default, the output directory will be set as public if it exists, or . (current directory) otherwise. Therefore, as long as your project doesn’t have the public directory, it will serve the files in the root directory.”

I want files in the root directory to be served as static pages. And functions in the `api` folder to be run as Ruby functions. I think I have the correct settings, if I understand the documentation correctly.

Redeploy. The build process shows `bundle update` running. The build logs show output from bundler.

```bash
15:07:57.784    Cloning github.com/DanielKehoe/ruby-trial (Branch: master, Commit: 1d7ed70)
15:07:58.449    Cloning completed in 665ms
15:07:58.450    Analyzing source code...
15:07:58.987    Installing build runtime...
15:07:59.380    Build runtime installed: 392.074ms
15:07:59.786    Looking up build cache...
15:07:59.825    Build cache not found
15:08:00.384    [DEPRECATED] The `--no-prune` flag is deprecated because it relies on being remembered across bundler invocations, which bundler will no longer do in future versions. Instead please use `bundle config set no-prune 'true'`, and stop using this flag
15:08:01.629    Fetching gem metadata from https://rubygems.org/......
15:08:01.632    Fetching https://github.com/igas/faunadb-ruby.git
15:08:02.669    Using bundler 2.1.2
15:08:02.671    Fetching multipart-post 2.1.1
15:08:02.671    Fetching json 2.3.1
15:08:02.671    Fetching cowsay 0.3.0
15:08:02.730    Installing multipart-post 2.1.1
15:08:02.731    Installing cowsay 0.3.0
15:08:02.757    Installing json 2.3.1 with native extensions
15:08:02.771    Fetching net-http-persistent 2.9.4
15:08:02.792    Fetching mini_portile2 2.4.0
15:08:02.833    Installing net-http-persistent 2.9.4
15:08:02.842    Installing mini_portile2 2.4.0
15:08:03.886    Fetching faraday 1.0.1
15:08:03.886    Fetching nokogiri 1.10.10
15:08:03.964    Installing faraday 1.0.1
15:08:04.330    Installing nokogiri 1.10.10 with native extensions
15:08:37.280    Using fauna 3.0.1.pre.1 from https://github.com/igas/faunadb-ruby.git (at patch-1@f09176e)
15:08:37.285    Bundle complete! 3 Gemfile dependencies, 9 gems now installed.
15:08:37.285    Use `bundle info [gemname]` to see where a bundled gem is installed.
15:08:37.364    Installing dependencies...
15:08:37.596    yarn install v1.22.4
15:08:37.608    info No lockfile found.
15:08:37.611    [1/4] Resolving packages...
15:08:37.612    [2/4] Fetching packages...
15:08:37.613    [3/4] Linking dependencies...
15:08:37.617    [4/4] Building fresh packages...
15:08:37.620    success Saved lockfile.
15:08:37.621    Done in 0.03s.
15:08:37.907    Fetching https://github.com/igas/faunadb-ruby.git
15:08:38.929    Fetching gem metadata from https://rubygems.org/.......
15:08:38.961    Resolving dependencies...
15:08:38.972    Using bundler 2.1.2
15:08:38.973    Using cowsay 0.3.0
15:08:38.973    Using multipart-post 2.1.1
15:08:38.973    Using json 2.3.1
15:08:38.973    Using net-http-persistent 2.9.4
15:08:38.973    Using mini_portile2 2.4.0
15:08:38.973    Using faraday 1.0.1
15:08:38.973    Using nokogiri 1.10.10
15:08:38.974    Using fauna 3.0.1.pre.1 from https://github.com/igas/faunadb-ruby.git (at patch-1@f09176e)
15:08:38.976    Bundle updated!
15:08:38.991    Error: No Output Directory named "public" found after the Build completed. You can configure the Output Directory in your Project Settings. Learn More: https://vercel.link/missing-public-directory
15:08:40.015    Installing build runtime...
15:08:41.315    Build runtime installed: 1299.950ms
15:08:41.725    Looking up build cache...
15:08:41.798    Build cache not found
```

The build log shows that the Fauna gem is loaded from GitHub:

```bash
Using fauna 3.0.1.pre.1 from https://github.com/igas/faunadb-ruby.git (at patch-1@f09176e)
```

The build fails with this error:

```bash
15:08:38.991    Error: No Output Directory named "public" found after the Build completed. You can configure the Output Directory in your Project Settings. Learn More: https://vercel.link/missing-public-directory
```

This is confusing because the docs say, “By default, the output directory will be set as public if it exists, or . (current directory) otherwise. Therefore, as long as your project doesn’t have the public directory, it will serve the files in the root directory.”

If I understand the documentation correctly, there should be no need for a `public` directory. In this case, the root directory should serve as the output directory, providing static files.

Checked the link [https://vercel.link/missing-public-directory](https://vercel.link/missing-public-directory): “The build step will result in an error if the output directory is missing, empty, or invalid (if it’s actually not a directory).“ This statement seems to contradict the other statement , “By default, the output directory will be set as public if it exists, or . (current directory) otherwise.”

### Set an output directory to `.`

What happens if I explicitly set the output directory to `.` ?

I toggled “Override” and set the “Output Directory” to `.` (dot).

I didn’t use backticks though the example surrounds `.` in backticks.

Clicked “Save.” Then redeployed.

The build process showed output from bundler and completed successfully.

```bash
15:22:57.584    Cloning github.com/DanielKehoe/ruby-trial (Branch: master, Commit: 1d7ed70)
15:22:58.268    Cloning completed in 684ms
15:22:58.269    Analyzing source code...
15:22:58.882    Installing build runtime...
15:22:59.278    Build runtime installed: 395.054ms
15:23:00.227    [DEPRECATED] The `--no-prune` flag is deprecated because it relies on being remembered across bundler invocations, which bundler will no longer do in future versions. Instead please use `bundle config set no-prune 'true'`, and stop using this flag
15:23:01.413    Fetching gem metadata from https://rubygems.org/......
15:23:01.416    Fetching https://github.com/igas/faunadb-ruby.git
15:23:02.462    Using bundler 2.1.2
15:23:02.464    Fetching cowsay 0.3.0
15:23:02.465    Fetching multipart-post 2.1.1
15:23:02.465    Fetching json 2.3.1
15:23:02.521    Installing multipart-post 2.1.1
15:23:02.526    Installing cowsay 0.3.0
15:23:02.556    Installing json 2.3.1 with native extensions
15:23:02.560    Fetching net-http-persistent 2.9.4
15:23:02.584    Fetching mini_portile2 2.4.0
15:23:02.627    Installing net-http-persistent 2.9.4
15:23:02.650    Fetching faraday 1.0.1
15:23:02.650    Installing mini_portile2 2.4.0
15:23:02.694    Fetching nokogiri 1.10.10
15:23:02.726    Installing faraday 1.0.1
15:23:03.027    Installing nokogiri 1.10.10 with native extensions
15:23:36.637    Using fauna 3.0.1.pre.1 from https://github.com/igas/faunadb-ruby.git (at patch-1@f09176e)
15:23:36.642    Bundle complete! 3 Gemfile dependencies, 9 gems now installed.
15:23:36.642    Use `bundle info [gemname]` to see where a bundled gem is installed.
15:23:36.724    Installing dependencies...
15:23:36.953    yarn install v1.22.4
15:23:36.965    info No lockfile found.
15:23:36.968    [1/4] Resolving packages...
15:23:36.969    [2/4] Fetching packages...
15:23:36.970    [3/4] Linking dependencies...
15:23:36.974    [4/4] Building fresh packages...
15:23:36.976    success Saved lockfile.
15:23:36.977    Done in 0.03s.
15:23:37.256    Fetching https://github.com/igas/faunadb-ruby.git
15:23:38.288    Fetching gem metadata from https://rubygems.org/.......
15:23:38.324    Resolving dependencies...
15:23:38.336    Using bundler 2.1.2
15:23:38.337    Using cowsay 0.3.0
15:23:38.337    Using multipart-post 2.1.1
15:23:38.337    Using json 2.3.1
15:23:38.337    Using net-http-persistent 2.9.4
15:23:38.337    Using mini_portile2 2.4.0
15:23:38.337    Using faraday 1.0.1
15:23:38.338    Using nokogiri 1.10.10
15:23:38.338    Using fauna 3.0.1.pre.1 from https://github.com/igas/faunadb-ruby.git (at patch-1@f09176e)
15:23:38.340    Bundle updated!
15:23:38.521    Uploading build outputs...
15:23:40.055    Installing build runtime...
15:23:41.328    Build runtime installed: 1273.711ms
15:24:20.542    Uploading build outputs...
15:24:24.007    Build completed. Populating build cache...
15:24:24.018    Uploading build cache [207.00 B]...
15:24:24.086    Build cache uploaded: 68.546ms
15:24:24.092    Done with ".editorconfig"
15:24:24.501    Done with "api/try-vercel.rb"
```

Open the function log page before trying the website. Then go to
[https://ruby-trial.vercel.app/api/try-vercel](https://ruby-trial.vercel.app/api/try-vercel)

The request succeeds but returns a text file of the code itself (opening a window to download the file).

Tried [https://ruby-trial.vercel.app/api/try-vercel.rb ](https://ruby-trial.vercel.app/api/try-vercel.rb)
Same thing: a text file of the code itself.

I’ve set the “Build Command” to `bundle update`. I want the project root to serve static files (no build needed) and the `api` directory to serve Ruby functions. If I don’t override the “Output Directory” setting I get the error “No Output Directory named ‘public’ found after the Build completed” and the build fails. When I set the “Output Directory” setting to `.` the scripts in the `api` folder get served as static files not functions.

My question:
- What is the correct “Build Command” and “Output Directory” to run  `bundle update` (in order to install a gem from GitHub) and serve Ruby functions from an  `api` directory?

## Deploying on Render.com

To be certain a gem can be loaded from GitHub and the function runs successfully, I deployed the project to Render.com (a service similar to Vercel).

From the Render.com dashboard, create a new web service. Choose the GitHub repository [https://github.com/DanielKehoe/ruby-trial](https://github.com/DanielKehoe/ruby-trial). Specify a project name (“ruby-trial) and a start command `bundle exec ruby try-render.rb`.

Deployment will produce log output:

```bash
Sep 1 01:30:07 PM  ==> Cloning from https://github.com/DanielKehoe/ruby-trial...
Sep 1 01:30:07 PM  ==> Checking out commit 96f8c8dbd39cb192f59f7552de148212645580b4 in branch master
Sep 1 01:30:08 PM  ==> Downloading cache...
Sep 1 01:30:11 PM  ==> Running build command 'bundle install'...
Sep 1 01:30:13 PM  Fetching gem metadata from https://rubygems.org/......
Sep 1 01:30:13 PM  Fetching https://github.com/igas/faunadb-ruby.git
Sep 1 01:30:14 PM  Using bundler 2.1.2
Sep 1 01:30:14 PM  Fetching cowsay 0.3.0
Sep 1 01:30:14 PM  Installing cowsay 0.3.0
Sep 1 01:30:14 PM  Fetching multipart-post 2.1.1
Sep 1 01:30:14 PM  Installing multipart-post 2.1.1
Sep 1 01:30:14 PM  Fetching faraday 1.0.1
Sep 1 01:30:14 PM  Installing faraday 1.0.1
Sep 1 01:30:14 PM  Fetching json 2.3.1
Sep 1 01:30:14 PM  Installing json 2.3.1 with native extensions
Sep 1 01:30:16 PM  Fetching net-http-persistent 2.9.4
Sep 1 01:30:16 PM  Installing net-http-persistent 2.9.4
Sep 1 01:30:16 PM  Using fauna 3.0.1.pre.1 from https://github.com/igas/faunadb-ruby.git (at patch-1@f09176e)
Sep 1 01:30:16 PM  Fetching mini_portile2 2.4.0
Sep 1 01:30:16 PM  Installing mini_portile2 2.4.0
Sep 1 01:30:16 PM  Fetching nokogiri 1.10.10
Sep 1 01:30:17 PM  Installing nokogiri 1.10.10 with native extensions
Sep 1 01:30:54 PM  Bundle complete! 3 Gemfile dependencies, 9 gems now installed.
Sep 1 01:30:54 PM  Gems in the groups development and test were not installed.
Sep 1 01:30:54 PM  Bundled gems are installed into `/opt/render/project/.gems`
Sep 1 01:30:56 PM  ==> Uploading build...
Sep 1 01:30:59 PM  ==> Build successful 🎉
Sep 1 01:30:59 PM  ==> Deploying...
Sep 1 01:31:15 PM  ==> Starting service with 'bundle exec ruby try-render.rb'
Sep 1 01:31:16 PM  [2020-09-01 05:31:16] INFO  WEBrick 1.4.2
Sep 1 01:31:16 PM  [2020-09-01 05:31:16] INFO  ruby 2.6.5 (2019-10-01) [x86_64-linux]
Sep 1 01:31:16 PM  [2020-09-01 05:31:16] INFO  WEBrick::HTTPServer#start: pid=54 port=8000
Sep 1 01:31:39 PM  ==> Starting service with 'bundle exec ruby try-render.rb'
Sep 1 01:31:40 PM  [2020-09-01 05:31:40] INFO  WEBrick 1.4.2
Sep 1 01:31:40 PM  [2020-09-01 05:31:40] INFO  ruby 2.6.5 (2019-10-01) [x86_64-linux]
Sep 1 01:31:40 PM  [2020-09-01 05:31:40] INFO  WEBrick::HTTPServer#start: pid=54 port=8000
Sep 1 01:32:01 PM  [2020-09-01 05:32:01] INFO  going to shutdown ...
Sep 1 01:32:01 PM  [2020-09-01 05:32:01] INFO  WEBrick::HTTPServer#start done.
Sep 1 01:32:01 PM  Cowsay gem version: 0.3.0
Sep 1 01:32:01 PM  WEBrick gem version: 1.4.2
Sep 1 01:32:01 PM  Fauna gem version: 3.0.1.pre.1
Sep 1 01:32:01 PM  Nokogiri gem version: 1.10.10
Sep 1 01:32:01 PM  $LOAD_PATH: ["/opt/render/project/.gems/gems/bundler-2.1.2/lib", "/opt/render/project/.gems/ruby/2.6.0/gems/nokogiri-1.10.10/lib", "/opt/render/project/.gems/ruby/2.6.0/extensions/x86_64-linux/2.6.0/nokogiri-1.10.10", "/opt/render/project/.gems/ruby/2.6.0/gems/mini_portile2-2.4.0/lib", "/opt/render/project/.gems/ruby/2.6.0/bundler/gems/faunadb-ruby-f09176e27edb/lib", "/opt/render/project/.gems/ruby/2.6.0/gems/net-http-persistent-2.9.4/lib", "/opt/render/project/.gems/ruby/2.6.0/gems/json-2.3.1/lib", "/opt/render/project/.gems/ruby/2.6.0/extensions/x86_64-linux/2.6.0/json-2.3.1", "/opt/render/project/.gems/ruby/2.6.0/gems/faraday-1.0.1/lib", "/opt/render/project/.gems/ruby/2.6.0/gems/faraday-1.0.1/spec/external_adapters", "/opt/render/project/.gems/ruby/2.6.0/gems/multipart-post-2.1.1/lib", "/opt/render/project/.gems/ruby/2.6.0/gems/cowsay-0.3.0/lib", "/opt/render/project/.gems/gems/bundler-2.1.2/lib/gems/bundler-2.1.2/lib", "/usr/local/lib/ruby/site_ruby/2.6.0", "/usr/local/lib/ruby/site_ruby/2.6.0/x86_64-linux", "/usr/local/lib/ruby/site_ruby", "/usr/local/lib/ruby/vendor_ruby/2.6.0", "/usr/local/lib/ruby/vendor_ruby/2.6.0/x86_64-linux", "/usr/local/lib/ruby/vendor_ruby", "/usr/local/lib/ruby/2.6.0", "/usr/local/lib/ruby/2.6.0/x86_64-linux"]
```

The Render.com build process shows the output from the `bundle install` command. It’s easy to confirm that the FaunaDB gem was installed from GitHub:

```bash
Using fauna 3.0.1.pre.1 from https://github.com/igas/faunadb-ruby.git (at patch-1@f09176e)
```

Open a browser and visit [https://ruby-trial.onrender.com](https://ruby-trial.onrender.com) You’ll see:

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

The log file shows the result of the request:

```bash
Sep 1 01:35:34 PM  10.104.78.7 - - [01/Sep/2020:05:35:34 UTC] "GET / HTTP/1.1" 200 161
Sep 1 01:35:34 PM  - -> /
```

There is no problem on Render.com.
