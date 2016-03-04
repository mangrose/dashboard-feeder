web: bundle exec puma -t 5:5 -p ${PORT:-3000}
resque: env TERM_CHILD=1 QUEUE='aggregate' bundle exec rake resque:work
