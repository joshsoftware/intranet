class EventServiceProxy < Rack::Proxy
  def initialize(app)
    @app = app
  end

  def call(env)
    original_host = env["HTTP_HOST"]
    rewrite_env(env)
    if env["HTTP_HOST"] != original_host
      perform_request(env)
    else
      @app.call(env)
    end
  end

  def rewrite_env(env)
    request = Rack::Request.new(env)
    if request.path.match('/events')
      if env['warden'].authenticated?
        @backend = URI("http://localhost:8000")
        env['rack.backend'] = @backend
        env["HTTP_HOST"] = "localhost:8000"
        env['HTTP_AUTHORIZATION'] = env['rack.session']['warden.user.user.key'][0]
      else
        env['REQUEST_PATH'] = '/'
      end
      env
    end
  end
end
