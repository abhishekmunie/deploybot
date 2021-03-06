http        = require 'http'
run_process = require 'child_process'
heroku      = require 'heroku'
nodemailer  = require 'nodemailer'
ansi_up     = require 'ansi_up'

error_msg =
  "200": "OK - Request succeeded, response contains requested data.",
  "401": "Unauthorized - You are attempting to access the API with invalid credentials.",
  "402": "Payment Required - You must confirm your billing info to use this API.",
  "403": "Forbidden - Your access level does not permit this API call.",
  "404": "Not Found - The API endpoint or resource you are attempting to fetch does not exist.",
  "412": "Precondition Failed - This API has been deprecated.",
  "422": "Unprocessable Entity - An error has occurred, see response body for details.",
  "423": "Locked - This API command requires confirmation. Pass the app name as a 'confirm' parameter."

console.time 'Server Started in'

smtpTransport = nodemailer.createTransport "SMTP",
    service: "Gmail"
    auth:
      user: process.env.EMAIL_USER
      pass: process.env.EMAIL_PASS

sendEmail = (vars, code, output) ->
  if output.indexOf("Everything up-to-date") isnt -1
    if (send_to = vars.config_vars["SEND_DEPLOY_ALREADYUPDATE"])
      subject = "UP-TO-DATE: " + vars.commit
      body = "<h1>#{vars.app} was already up-to-date :</h1>\n" + output
    else
      return
  else if code is 0
    send_to = vars.config_vars["SEND_DEPLOY_SUCCESS"]
    subject = "SUCCESS: " + vars.commit
    body = "<h1>Successfully deployed #{vars.app} :)</h1>\n" + output
  else
    send_to = vars.config_vars["SEND_DEPLOY_ERROR"]
    subject = "ERROR: " + vars.commit
    body = "<h1>Sorry I couldn't deploy #{vars.app} :(</h1>\n" + output

  send_to = true if send_to is undefined or send_to is "true"
  return if send_to is false or send_to is "false"

  deploy_colab = heroku.api(process.env.HEROKU_API_KEY, "application/json").request("GET", "/apps/" + vars.app + "/collaborators")

  deploy_colab.on "success", (data, response) ->
    collaborators = data
    try
      collaborators = JSON.parse collaborators
    catch err
      console.error "JSON prase error: " + err

    collab_to = []
    for colab in collaborators
      if send_to is true or send_to.indexOf(colab["email"]) isnt -1
        collab_to.push if colab["name"] then "#{colab["name"]} <#{colab["email"]}>" else colab["email"]

    smtpTransport.sendMail
        from: "#{process.env.EMAIL_NAME} <#{process.env.EMAIL_USER}>"
        to: collab_to.toString()
        subject: subject
        html: ansi_up.ansi_to_html body
      ,(error, response) ->
        console.error error if error

  deploy_colab.on "error", (data, response) ->
    console.error "ERROR:\n\tDATA: " + data + "\n\tRESPONSE: " + response

http.createServer (req, res) ->
  app = req.url.slice(1)
  res.writeHead 302, {'Location': 'https://deploybot-dashboard.herokuapp.com'} if app is ''
  res.end()
  return if app is "favicon.ico" or app is ''

  deploy_config = heroku.api(process.env.HEROKU_API_KEY, "application/json").request("GET", "/apps/" + app + "/config_vars")

  deploy_config.on "success", (data, response) ->
    config_vars = data
    try
      config_vars = JSON.parse config_vars
    catch err
      console.error "JSON prase error: " + err

    vars = [
      config_vars["SOURCE_REPO"],
      config_vars["SOURCE_BRANCH"] || "master",
      "git@heroku.com:" + app + ".git",
      "master"
    ]
    output = commit = ""

    deploySh = run_process.spawn 'sh', ['./deploy.sh', 'run'].concat vars
    deploySh.stdout.on 'data', (data) ->
      output += data
    deploySh.stderr.on 'data', (data) ->
      output += data
      commit = data.toString()
    deploySh.on 'close', (code) ->
      sendEmail
        "config_vars" : config_vars
        "app"         : app
        "commit"      : commit
      , code, '<h2>SHELL OUTPUT:</h2><code style="white-space: pre-wrap;">' + output + '</code><hr/><em>child process exited with code ' + code + '</em>'

  deploy_config.on "error", (data, response) ->
    console.error "ERROR: " + app + " => " + (error_msg[response.statusCode] || "Some error occured.")

.listen process.env.PORT or process.env.C9_PORT or process.env.VCAP_APP_PORT or process.env.VMC_APP_PORT or 1337, ->
  console.timeEnd 'Server Started in'
  console.log "Listening ..."