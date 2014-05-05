class HealthCheck 

  def initialize(app)  
    @app = app  
  end  
    
  def call(env)
    if env['ORIGINAL_FULLPATH'] == '/health'
      [200, {'Content-Type' => 'text/plain'}, ["ALL OK"]]
    else
      @app.call env
    end
  end
  
end 