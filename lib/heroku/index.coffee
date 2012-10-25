events = require("events")
qs     = require("querystring")
rest   = require("restler")

class Heroku

  constructor: (@key, @accept) ->
    @auth = new Buffer(":#{@key}").toString("base64")

  request: (method, path, params) ->

    options =
      method: method
      headers:
        Accept: @accept
        Authorization: @auth

    switch method
      when "GET"
        options.query = params
      when "POST"
        if params.indexOf("=") > -1
          options.data = qs.parse(params)
        else
          data = this.full_uri_decode(params)
          options.data = data
          options.headers["Content-Length"] = data.length.toString()
      when "PUT"
        if params.indexOf("=") > -1
          options.data = qs.parse(params)
        else
          data = this.full_uri_decode(params)
          options.data = data
          options.headers["Content-Length"] = data.length.toString()
      when "DELETE"
        options.headers["Content-Length"] = "0"

    emitter = new events.EventEmitter()
    request = rest.request('https://api.heroku.com' + path, options)

    request.on "success", (data, response) ->
      switch response.headers["content-type"].split(";")[0]
        when "application/json"
          try
            data = JSON.stringify(JSON.parse(data), null, "  ")
          catch error
            console.log "error parsing json: " + error
      emitter.emit "success", data, response

    request.on "error", (data, response) ->
      emitter.emit "error", data, response

    emitter

  full_uri_decode: (string) ->
    string = decodeURIComponent(string)
    string = string.replace(/\%2E/g, ".")
    string

exports.api = (key, accept="application/json") ->
  new Heroku(key, accept)
