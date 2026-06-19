resource "null_resource" "vpc_sg_cleanup" {
  triggers = {
    region   = var.region
    vpc_cidr = var.vpc_cidr
  }

  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      echo "=== Regional Security Group Cleanup Started ==="
      
      echo "Cleaning all security groups starting with 'k8s-' in region: ${self.triggers.region}"
      
      for attempt in {1..5}; do
        sgs=$(aws ec2 describe-security-groups --region ${self.triggers.region} \
          --filters "Name=group-name,Values=k8s-*" \
          --query "SecurityGroups[].GroupId" --output text 2>/dev/null || true)
        
        if [ -z "$sgs" ]; then
          echo "No k8s security groups found"
          break
        fi
        
        for sg in $sgs; do
          echo "Deleting security group: $sg"
          
          # Clear all rules
          aws ec2 describe-security-groups --group-ids $sg --region ${self.triggers.region} \
            --query "SecurityGroups[0].IpPermissions[]" --output json 2>/dev/null | \
            aws ec2 revoke-security-group-ingress --group-id $sg --region ${self.triggers.region} \
            --ip-permissions file:///dev/stdin 2>/dev/null || true
          
          aws ec2 describe-security-groups --group-ids $sg --region ${self.triggers.region} \
            --query "SecurityGroups[0].IpPermissionsEgress[]" --output json 2>/dev/null | \
            aws ec2 revoke-security-group-egress --group-id $sg --region ${self.triggers.region} \
            --ip-permissions file:///dev/stdin 2>/dev/null || true
          
          aws ec2 delete-security-group --group-id $sg --region ${self.triggers.region} 2>/dev/null || true
        done
        
        sleep 3
      done
      
      echo "=== Regional Security Group Cleanup Completed ==="
    EOT
  }
}
