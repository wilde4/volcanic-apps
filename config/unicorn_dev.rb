worker_processes 3
listen 3001, tcp_nopush: true
timeout 60
#increase timeout when debugging
if ENV['IDE_PROCESS_DISPATCHER']
  timeout 30 * 60 * 60 * 24
end