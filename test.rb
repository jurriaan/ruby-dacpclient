require './lib/dacpclient'
client = DACPClient.new 'Test client', 'localhost', 3689
p client.serverinfo
#client.pair [1,2,3,4]

#sleep 2
#client.content_codes
client.login
client.play
#client.login
#client.play
#client.pause
#client.status
#client.play
p client.ctrl_int
#puts client.set_volume 100
#
