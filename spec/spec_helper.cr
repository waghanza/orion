require "../src/orion"
require "spec"

def mock_context(verb, path, host = "example.org", *, headers = {} of String => String, io = IO::Memory.new, body = nil)
  http_headers = HTTP::Headers.new
  headers.each { |k, v| http_headers[k] = v }
  http_headers["HOST"] = host
  request = HTTP::Request.new(verb.to_s.upcase, path, http_headers)
  request.body = body
  response = HTTP::Server::Response.new io
  HTTP::Server::Context.new(request, response)
end

def Orion::Router.test_route(method, path, *, headers = {} of String => String, body = nil)
  io = IO::Memory.new
  context = mock_context(method, path, headers: headers, io: io, body: body)
  router = new
  router.call(context)
  HTTP::Client::Response.from_io io.tap(&.rewind)
end

def Orion::Router.test_ws(path, host = "example.org")
  io = IO::Memory.new
  context = mock_context("GET", path, host, headers: {
    "Upgrade"               => "websocket",
    "Connection"            => "Upgrade",
    "Sec-WebSocket-Key"     => "dGhlIHNhbXBsZSBub25jZQ==",
    "Sec-WebSocket-Version" => "13",
  }, io: io)
  router = new
  begin
    router.call context
  rescue IO::Error
    # Raises because the IO:: Memory is empty
  end
  io.rewind
  {io, context}
end
