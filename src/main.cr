require "dotenv"
Dotenv.load ".env"
require "oauth2"
require "json"
require "base64"
require "uri"
require "kemal"
require "http/web_socket"
require "./bot"

HOST = URI.parse(ENV["JOYSTICKTV_HOST"])
CLIENT_ID = ENV["JOYSTICKTV_CLIENT_ID"]
CLIENT_SECRET = ENV["JOYSTICKTV_CLIENT_SECRET"]
WS_HOST = ENV["JOYSTICKTV_API_HOST"]
ACCESS_TOKEN = Base64.urlsafe_encode(CLIENT_ID + ":" + CLIENT_SECRET)
GATEWAY_IDENTIFIER = %({"channel": "GatewayChannel"})

URL = "#{WS_HOST}?token=#{ACCESS_TOKEN}"

ws = HTTP::WebSocket.new(URL, headers: HTTP::Headers{"Sec-WebSocket-Protocol" => "actioncable-v1-json"})
if !ws.closed?
  puts "connection has opened"
end

ws.send({
  command: "subscribe",
  identifier: GATEWAY_IDENTIFIER,
}.to_json)

ws.on_close do |_|
  puts "connection has closed"
end

connected = false

ws.on_message do |data|
  received_message = JSON.parse(data)

  case received_message["type"]?.try(&.as_s?)
  when "reject_subscription"
    puts "nope... no connection for you"
  when "confirm_subscription"
    connected = true
  else
    # ignore
  end

  if connected
    Bot.handle_message(ws, received_message)
  end
end

OAUTH_CLIENT = OAuth2::Client.new(
    HOST.host.to_s,
    CLIENT_ID,
    CLIENT_SECRET,
    port: HOST.port,
    scheme: HOST.scheme.to_s,
    redirect_uri: "/unused",
    authorize_uri: "/api/oauth/authorize",
    token_uri: "/api/oauth/token"
  )

get "/" do
  "Visit <a href='/install'>INSTALL</a> to install Bot"
end

get "/install" do |env|
  state = "abckemal123"

  authorize_uri = OAUTH_CLIENT.get_authorize_uri(scope: "bot", state: state)
  env.redirect(authorize_uri)
end


get "/callback" do |env|
  # STATE should equal `abckemal123`
  puts "STATE: #{env.params.query["state"]?}"
  puts "CODE: #{env.params.query["code"]?}"
  
  data = OAUTH_CLIENT.get_access_token_using_authorization_code(env.params.query["code"])

  # Save to your DB if you need to request user data
  puts data.access_token
  "Bot has been activated"
end

puts "listening..."
spawn { ws.run }
Kemal.run(8080)
