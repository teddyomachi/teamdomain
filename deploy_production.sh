#!/bin/sh
bundle exec cap production deploy:config_files
bundle exec cap production deploy:vendor_files
bundle exec cap production deploy:public_files
bundle exec cap production deploy:database_files
bundle exec cap production deploy:app_assets
scp -r -p node_modules 117.102.186.81:/webapps/spin/secret_files/shared/
