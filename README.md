# [Deploy Bot](http://abhishekmunie.com/projects/deploybot)

A [Node.js](http://nodejs.org) server which deploys heroku apps from a git repo 
when a request is recieved at `/:your-heroku-app` and emails the result to all collaborators.

## Using pre-deployed verion of deploybot
To allow Deploy Bot to access your heroku app add bot@abhishekmunie.com
as a collaborator at https://dashboard.heroku.com/apps/:your-heroku-app/collaborators

For use with private GitHub repo add botx(bot@abhishekmunie.com) to collaborators.

Add the following [config-vars](https://devcenter.heroku.com/articles/config-vars) to your app:

    SOURCE_REPO   : URL of git repo to deploy
    SOURCE_BRANCH : Branch to deploy (default: master)

Additional configs:

    SEND_DEPLOY_SUCCESS : set false if you dont want e-mail for successful deployments.
                          If you want reports to be sent to only some collaborators
                          set an array of their e-mail id.
    SEND_DEPLOY_ERROR   : set false if you dont want e-mail for deployment errors.
                          If you want reports to be sent to only some collaborators
                          set an array of their e-mail id.

Now send a request at `deploybot.abhishekmunie.com/:your-heroku-app` to initiate deploy.

To automate deploy add a github service hook for 
[http://deploybot.abhishekmunie.com/:your-heroku-app](http://deploybot.abhishekmunie.com/:your-heroku-app)
at [https://github.com/:github-user/:your-github-app/admin/hooks](https://github.com/:github-user/:your-github-app/admin/hooks)

## Useage
To use your own deloybot, deploy it to [Heroku](https://www.heroku.com) and add the following
[config-vars](https://devcenter.heroku.com/articles/config-vars) to your app

    HEROKU_API_KEY : your heroku api key
    RSA_KEY        : a rsa private key
    RSA_PUBLIC_KEY : its rsa public key. upload the same to heroku.
    EMAIL_USER     : e-mail id to be used for sending e-mail
    EMAIL_NAME     : sender's name
    EMAIL_PASS     : e-mail account password

See [Managing Your SSH Keys](https://devcenter.heroku.com/articles/keys) to generate and upload your SSH key.
It is recommended to enable [Google 2-step verification](http://support.google.com/accounts/bin/answer.py?hl=en&answer=180744)
on your gmail account and use
[application-specific passwords](http://support.google.com/accounts/bin/static.py?hl=en&page=guide.cs&guide=1056283).

Happy coding!