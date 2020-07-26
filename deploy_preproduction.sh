#!/bin/sh
bundle exec cap preproduction deploy:config_files
bundle exec cap preproduction deploy:vendor_files
bundle exec cap preproduction deploy:public_files
bundle exec cap preproduction deploy:database_files
bundle exec cap preproduction deploy:app_assets
scp -r -p node_modules 192.168.1.22:/webapps/spin/secret_files/shared/