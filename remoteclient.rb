$LOAD_PATH.unshift __dir__
require File.expand_path('lib/dacpclient.rb', __dir__)
require 'english'
require 'socket'
include DACPClient
class CLIClient
  def initialize
    @client = DACPClient::Client.new("CLIClient (#{Socket.gethostname})", 'localhost', 3689)
    @login = false
  end

  def parse_arguments(arguments)
    if arguments.length > 0 && !([:parse_arguments].include?(arguments.first.to_sym)) && self.class.instance_methods(false).include?(arguments.first.to_sym)
      method = arguments.first.to_sym
      send method
      status unless %i{help usage}.include?(method)
    else
      usage
    end
  end

  def status
    login
    status = @client.status
    if status.caps == 2
      puts '[STOPPED]'
    else
      name = status.cann
      artist = status.cana
      album = status.canl
      playstatus = status.caps != 4 ? 'paused' : 'playing'
      remaining = status.cant
      total = status.cast
      current = total - remaining
      puts "[#{playstatus.upcase} (#{format_time(current)}/#{format_time(total)})] #{name} - #{artist} (#{album})"
    end
  end

  def play
    login
    @client.play
  end

  def pause
    login
    @client.pause
  end

  def playpause
    login
    @client.playpause
  end

  def next
    login
    @client.next
  end

  def prev
    login
    @client.prev
  end

  def databases
    login
    puts @client.databases
  end

  def playqueue
    login
    puts @client.list_queue
  end

  def upnext
    login
    items = @client.list_queue.mlcl.select { |item| item.type.tag == 'mlit' }
    puts 'Up next:'
    puts '--------'
    puts
    items.each do |item|
      name = item.ceQn
      artist = item.ceQr
      album = item.ceQa
      puts "#{name} - #{artist} (#{album})"
    end
    puts
  end

  def debug
    login
    require 'pry'
    binding.pry
  end

  def usage
    puts "Usage: #{$PROGRAM_NAME} [command]"
    puts
    puts 'Where command is one of the following:'

    puts CLIClient.instance_methods(false).reject { |m| [:parse_arguments].include?(m)  }
  end

  alias_method :previous, :prev
  alias_method :help, :usage

  private

  def login
    @client.login unless @login
    @login = true
  end

  def format_time(millis)
    seconds, millis = millis.divmod(1000)
    minutes, seconds = seconds.divmod(60)
    hours, minutes = minutes.divmod(60)
    if hours == 0
      sprintf('%02d:%02d', minutes, seconds)
    else
      sprintf('%02d:%02d:%02d', hours, minutes, seconds)
    end
  end
end

cli = CLIClient.new
cli.parse_arguments(Array(ARGV))