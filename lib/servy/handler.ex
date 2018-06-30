require Logger

defmodule Servy.Handler do
  
  alias Servy.Conv
  alias Servy.BearController
  
  @moduledoc "Handles HTTP requests."

  @pages_path Path.expand("pages", File.cwd!)
  
  import Servy.Plugins, only: [rewrite_path: 1, log: 1, track: 1]
  import Servy.Parser, only: [parse: 1]
  import Servy.FileHandler, only: [handle_file: 2]
  
  @doc "Transforms the request into a response."
  def handle(request) do
    request 
    |> parse
    |> rewrite_path
    # |> log 
    |> route 
    |> track
    |> format_response 
  end
  
  def route(%Conv{method: "GET", path: "/hiberate/" <> time} = conv) do
    time |> String.to_integer |> :timer.sleep
    
    %{ conv | status: 200, resp_body: "Awake!"}
  end
  
  def route(%Conv{method: "GET", path: "/wildthings"} = conv) do
    %{ conv | status: 200, resp_body: "Bears, Lions, Tigers"}
  end
  
  def route(%Conv{method: "GET", path: "/api/bears"} = conv) do
    Servy.Api.BearController.index(conv)
  end
  
  def route(%Conv{method: "GET", path: "/bears"} = conv) do
    BearController.index(conv)
  end
  
  def route(%Conv{method: "GET", path: "/bears/" <> id} = conv) do
    params = Map.put(conv.params, "id", id)
    BearController.show(conv, params)
  end
  
  def route(%Conv{method: "DELETE" = method, path: "/bears/" <> id} = conv) do
    %{ conv | status: 401, resp_body: "Cannot #{method} Bear #{id}"}
  end
  
  def route(%Conv{method: "POST" = _method, path: "/bears"} = conv) do
    BearController.create(conv, conv.params)
  end
  
  def route(%Conv{method: "GET", path: "/about"} = conv) do
    @pages_path
    |> Path.join("about.html")
    |> File.read
    |> handle_file(conv)
  end
  
  def route(%Conv{method: "GET", path: "/bears/new"} = conv) do
    @pages_path  
    |> Path.join("form.html")
    |> File.read
    |> handle_file(conv)
  end

  def route(%Conv{method: _, path: path} = conv) do
    %{conv | status: 404, resp_body: "No #{path} here!"}
  end

  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}\r
    Content-Type: #{conv.resp_content_type}\r
    Content-Length: #{String.length(conv.resp_body)}\r
    \r
    #{conv.resp_body}
    """
  end
end
