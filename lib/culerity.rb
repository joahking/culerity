require File.dirname(__FILE__) + '/culerity/remote_object_proxy'
require File.dirname(__FILE__) + '/culerity/remote_browser_proxy'

module Culerity

  def self.run_server
    pipe = IO.popen("jruby #{__FILE__}", 'r+')
    `echo #{pipe.pid} > tmp/pids/celerity_jruby.pid`
    pipe
  end

end

if __FILE__ == $0
  require File.dirname(__FILE__) + '/culerity/celerity_server'
  Culerity::CelerityServer.new STDIN, STDOUT
end
