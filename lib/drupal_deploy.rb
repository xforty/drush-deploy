require 'railsless-deploy'

Capistrano::Configuration.instance(:must_exist).load 'recipes/all'
