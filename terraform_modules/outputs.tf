output "master-node-ip" {
  value       = aws_instance.master_node.private_ip
  description = "The private IP of the master node"
}

output "worker-node-ip" {
  value       = aws_instance.worker_node.private_ip
  description = "The private IP of the worker node"
}

output "haproxy-server-ip" {
  value       = aws_instance.haproxy_server.public_ip
  description = "The public IP of the HAProxy server"
}
