# Docker Based Development Environment

This repository creates a complete development environment for Ruby, Python and Node on Apple-based computers (although it will probably run on any docker-capable machine with little to no changes).

It is compatible with both intel and 🍎 M1 machine.

The process takes 7 - 15 minutes, depending on your machine speed.

# What's included?
* Python Version 3.8.12 (with pyenv `~/.pyenv` so you can install any other version)
* pipenv for python (`~/venv`)
* Ruby version 2.7 (with rbenv `~/.rbenv`, so you can install any other version)
* Node version 14.8.0 (Through NVM `~/nvm`, so you can install any other version)
* A fully functioning visual studio code in the browser thanks to [gitpod](https://github.com/gitpod-io/openvscode-server/)
* A Serverless client [serverless framework](https://www.serverless.com/)
* Docker (Docker available inside the docker container)
* SSH client
* [AWS Cli](https://aws.amazon.com/cli/)
* [AWS Vault](https://github.com/99designs/aws-vault)
* [aws-creds](https://github.com/sabi-ai/aws-creds) -> Works with AWS Vault
* GIT client configured with your private key to access private repositories.

> Note: The container uses docker volumes to store the data persistently. We use volumes because the disk performance of volumes is much better than mapping the host drive (on Docker for apple). The volumes as `venv_volume_<container name>` and `dev_volume_<container name>`. Backing up and restoring docker volumes is a bit of a pain. I recommend committing your code regularly to git (which is good practice anyway).

# Install on localhost

To run the dev environment to it's full potnential, you would want to run it with proper https, otherwise the browser clipboard will not work as expected.

To run on localhost with https, install [caddy](https://caddyserver.com/docs/install).

The easiest way to do so on the mac is by using [homebrew](https://brew.sh), and running `brew install caddy`

### Follow these steps:<br/>
[Follow the Prep Install Section](#Prep-Install)<br/>
Run `./local_init.sh`

Once the script is completed, access [https://localhost](https://localhost) on your browser.

After the initial creation, use `./local_start.sh` and `./local_stop.sh` to start and stop the environment.

# Install on a remote server

When installing on a remote server, you will need the following:
- A domain name that will provide access to vs code (example: dev.mydomain.com), this domain should point to your server.
- A domain name that will provide access to the authentication interface (example: auth.mydomain.com), this domain should point to your server.
- Your server should have ports 80 and 443 opened. Port 80 is used just to create an SSL certificate. Access to the vs code will be using 443.
- Install docker on your server.

### Follow these steps:<br/>
- [Follow the Prep Install Section](#Prep-Install)
- Run `./remote_init.sh`

The script will show you a password to access the webadmin, use it to login and change the password (use the AUTH_DOMAIN url), or simply record it. If you loose your password, you can delete the `cadddy/root_caddy/users.json` file, and re-run `./remote_init.sh`. Note that this will reset your container (you will not lose the code, but installed extensions in VS code will need to be re-installed).

If you want to change the user, you can edit the `cadddy/root_caddy/users.json` file (users->username).

I recommend that once you login, add MFA for better security. Caddy secure supports both MFA authenticator apps as well as U2F like [Yubikey](https://www.yubico.com/).



# Prep Install

You will need [docker](https://www.docker.com/get-started/) installed.

* Clone this repo on the development server `git clone https://github.com/asabi/docker_dev_environment.git`
* cd into the repo `cd docker_dev_environment` <br/>
* Copy .env.tmp into .env
    * Populate the .env fields. 
      * GIT_SSH_KEY --> This needs to be the location of your ssh key you usually would use to clone private repositories. The key is copied to the root folder of this repository as `git.pem`, which is in the `gitignore` file to make sure you don't commit it somewhere by mistake. 

      > ⚠️ Note: You can safely remove the git.pem from the root folder once the process is complete (the init script does it for you)
      
      * VSCODE_PORT Port to Run VsCode.    
      * DOMAIN the name of the domain you want to use to access the development environment (example: dev.mydomain.com). Make sure the domain is pointing to the server. NOTE: This variable is needed only when not running on localhost.
      * AUTH_DOMAIN the name of the domain you want to use to login to the environment (example: auth.mydomain.com). NOTE: This variable is needed only when not running on localhost.
      * CONTAINER_NAME what docker container name to use. Also affects the name of the docker volumes created.

      > ⚠️ Note: for example, `docker start dev`


      * GIT_NAME git name for commits --> Whatever you want your git name to be. It is used in the Dockerfile to set up your git name `git config --global user.name "$name"`

      * GIT_EMAIL git email for commits --> Whatever you want your git email to be. It is used in the Dockerfile to set up your git email `git config --global user.email "$email"`

      * JWT_SHARED_KEY used by caddy to authenticate JWT, needed only when using non localhost

      * SERVERLESS_KEY Serverless Framework Key --> This is optional. If you use [serverless framework](https://www.serverless.com/), this key is your serverless API token. 
    
      * Client IDs / Client Secrets --> See the caddy/Caddyfile for setup information






## Extra items:

This repo has some extra useful scripts and templates:

* aws_config --> A sample configuration file for AWS (Needs to be adjusted to your needs and copied to `~/.aws/config`)
* clone --> A simple script to clone repositories from a particular git account (`clone <repo name>`)
* setup --> A simple script to install some vs code extensions that I find useful.
* tunnel.on --> A script to open an SSH tunnel (adjust to your needs)
* tunnel.off --> A script to close an SSH tunnel (adjust to your needs)
* vscode_settings.json --> Extra vscode settings.

## Debug Ruby with VSCode:

gem install ruby-debug-ide
gem install debase
rdebug-ide <file name>

`.vscode/launch.json`

```
{
  "version": "0.2.0",
  "configurations": [
  {
    "name": "Listen for rdebug-ide",
    "type": "Ruby",
    "request": "attach",
    "remoteHost": "127.0.0.1",
    "remotePort": "1234",
    "remoteWorkspaceRoot": "${workspaceRoot}"
  }
  ]
}
```

## Other ruby related things
When starting a new ruby project, follow these steps:
mkdir project 
cd project
bundle init
Add a file named lefthook.yml with the following content:
```
pre-commit:
  parallel: true
  commands:
    tests:
      run: bundle exec rake test
    audit:
      run: bundle exec brakeman --no-pager --force
    rubocop:
      files: git diff --name-only --staged
      glob: "*.rb"
      run: bundle exec rubocop --force-exclusion {files}
```
Run lefthook install

In your Gemfile, add:
```
group :development do
  gem 'debase'
  gem 'dotenv'
  gem 'minitest'
  gem 'pry'
  gem 'ruby-debug-ide'
  gem 'solargraph'
end
```
Run:<br/>
`bundle install --standalone --path vendor/bundle`<br/>
`bundle exec yard gems`


