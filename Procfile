web: bundle exec puma -p $PORT
resque: env TERM_CHILD=1 QUEUE='aggregate' bundle exec rake resque:work
console: bundle exec ruby util/console.rb
