require_relative 'models'

require 'roda'
require 'tilt/sass'
require 'tilt/opal'
require 'opal/builder_processors'
require 'opal/browser'
require 'opal/erubi'

require_relative 'lib/rack_env'
require_relative 'lib/opal_builder'

class App < Roda
  opts[:check_dynamic_arity] = false
  opts[:check_arity] = :warn

  plugin :rack_env # lib/rack_env
  
  plugin :default_headers,
    'Content-Type'=>'text/html',
    #'Strict-Transport-Security'=>'max-age=16070400;', # Uncomment if only allowing https:// access
    'X-Frame-Options'=>'deny',
    'X-Content-Type-Options'=>'nosniff',
    'X-XSS-Protection'=>'1; mode=block'
  
  plugin :caching

  plugin :content_security_policy do |csp|
    csp.default_src :none
    csp.style_src :self, 'https://maxcdn.bootstrapcdn.com'
    csp.form_action :self
    csp.script_src :self
    csp.connect_src :self
    csp.base_uri :none
    csp.frame_ancestors :none
  end

  js_builder = OpalBuilder.new(stubs: []) #'opal'
  js_builder.build_source_map = dev?
  ['opal', 'common', *Dir['parts/**/opal'], *Dir['parts/**/common'], *Dir['parts/**/views']].each do |i|
    js_builder.append_paths(i)
  end

  plugin :route_csrf
  plugin :flash
  plugin :assets, css: ['css/app.scss', *Dir['parts/**/css/**']], css_opts: {style: :compressed, cache: false}, 
                  js: prod? ? ['opal/entry-production.rb', *Dir['parts/**/opal/entry.rb']] :
                      ['opal/entry-corelib.rb',
                       'opal/entry-browser.rb', 
                       'opal/entry-devel.rb',
                       'opal/entry-app.rb', *Dir['parts/**/opal/entry.rb']],
                  js_opts: { builder: js_builder },
                  path: '.', js_dir: '', css_dir: '',
                  timestamp_paths: true,
                  css_compressor: :yui, js_compressor: :uglifier,
                  gzip: true, precompiled: prod? ? 'public/assets/assets-precompiled.json' : nil,
                  dependencies: dev? ? {'opal/entry-corelib.rb' => Dir['../opal/**'],
                                        'opal/entry-devel.rb'   => Dir['../opal/**'],
                                        'opal/entry-browser.rb' => Dir['../opal-browser/**'],
                                        'opal/entry-app.rb'     => Dir['opal/**'] + Dir['common/**'] } : {}
  plugin :render, escape: true, engine: "erubi", layout: "./layout",
                  allowed_paths: ['common', 'views', *Dir['parts/**/common'], *Dir['parts/**/views']]
  plugin :view_options
  plugin :public
  plugin :multi_route
  
  #logger = if ENV['RACK_ENV'] == 'test'
  #  Class.new{def write(_) end}.new
  #else
  #  $stderr
  #end
  #plugin :common_logger, logger

  plugin :not_found do
    @page_title = "File Not Found"
    view(:content=>"")
  end

  plugin :exception_page if dev?

  plugin :error_handler do |e|
    case e
    when Roda::RodaPlugins::RouteCsrf::InvalidToken
      @page_title = "Invalid Security Token"
      response.status = 400
      view(:content=>"<p>An invalid security token was submitted with this request, and this request could not be processed.</p>")
    else
      $stderr.print "#{e.class}: #{e.message}\n"
      $stderr.puts e.backtrace
      next exception_page(e, :assets=>true) if dev?
      @page_title = "Internal Server Error"
      view(:content=>"")
    end
  end

  plugin :sessions,
    key: '_App.session',
    #cookie_options: {secure: ENV['RACK_ENV'] != 'test'}, # Uncomment if only allowing https:// access
    secret: ENV.send((ENV['RACK_ENV'] == 'development' ? :[] : :delete), 'APP_SESSION_SECRET')

  ['routes',                'helpers',                'config', 
   *Dir['parts/**/routes'], *Dir['parts/**/helpers'], *Dir['parts/**/config']].each do |i|

    Unreloader.require(i){}
  end

  route do |r|
    #response.cache_control public: true

    r.public
    r.exception_page_assets if dev?
    r.assets  
    check_csrf!
    r.multi_route

    if dev?
      require 'pry'
      r.is 'pry' do
        binding.pry
      end
    end

    r.root do
      view 'index'
    end
  end
end
