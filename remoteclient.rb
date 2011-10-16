require './lib/dacpclient'
require 'socket'

class CLIClient
  def initialize
    @client = DACPClient.new "CLIClient (#{Socket.gethostname})", 'localhost', 3689
    @login = false
  end
  
  def parse_arguments arguments
    if !arguments.nil? and arguments.length > 0 and !([:parse_arguments].include?(arguments.first.to_sym)) and CLIClient.instance_methods(false).include? arguments.first.to_sym
      send arguments.first.to_sym
    else
      usage
    end
  end
  
  def status
    login
    status = @client.status
    if status.caps == 2
      puts "[STOPPED]"
    else
      name = status.cann
      artist = status.cana
      album = status.canl
      playstatus = status.caps != 4? "paused":"playing"
      puts "[#{playstatus.upcase}] #{name} - #{artist} (#{album})"
    end
  end
  
  def play
    login
    @client.play
    status
  end
  
  def pause
    login
    @client.pause
    status
  end
  
  def playpause
    login
    @client.playpause
    status
  end
  
  def next
    login
    @client.next
    status
  end
  
  def prev
    login
    @client.prev
    status
  end
  
  def usage
    puts "Usage: #{$0} [command]"
    puts
    puts "Where command is one of the following:"
  
    puts CLIClient.instance_methods(false).reject {|m| [:parse_arguments].include?(m)}
  end
  alias :help :usage
  
  private
  
  def login
    @client.login if !@login
    @login = true
  end
end

cli = CLIClient.new
cli.parse_arguments ARGV