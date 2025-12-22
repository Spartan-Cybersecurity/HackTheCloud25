# Data source to get the root volume of the Domain Controller
data "aws_ebs_volume" "dc_root_volume" {
  most_recent = true

  filter {
    name   = "attachment.instance-id"
    values = [aws_instance.domain_controller.id]
  }

  filter {
    name   = "attachment.device"
    values = ["/dev/sda1"]
  }

  depends_on = [aws_instance.domain_controller]
}

# Create snapshot of the Domain Controller's root volume
resource "aws_ebs_snapshot" "dc_snapshot" {
  volume_id   = data.aws_ebs_volume.dc_root_volume.id
  description = "MediCloudX backup snapshot - Weekly automated backup"

  tags = {
    Name        = "MediCloudX-DC-Backup-${random_string.suffix.result}"
    Environment = "Production"
    BackupType  = "Weekly"
    Application = "MediCloudX"
    Owner       = "IT-Operations"
  }

  # Ensure the DC has had time to fully configure before taking snapshot
  depends_on = [aws_instance.domain_controller]

  # Use a local-exec provisioner to wait for DC setup completion
  provisioner "local-exec" {
    command = "echo 'Snapshot created for Domain Controller with NTDS database'"
  }
}

# Make the snapshot public for CTF environment (intentional vulnerability)
resource "null_resource" "make_snapshot_public" {
  count      = var.make_snapshot_public ? 1 : 0
  depends_on = [aws_ebs_snapshot.dc_snapshot]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Making snapshot public for CTF challenge..."
      aws ec2 modify-snapshot-attribute \
        --snapshot-id ${aws_ebs_snapshot.dc_snapshot.id} \
        --attribute createVolumePermission \
        --operation-type add \
        --group-names all \
        --region ${var.aws_region} \
        --profile ${var.aws_profile}
      echo "Snapshot ${aws_ebs_snapshot.dc_snapshot.id} is now public"
    EOT
  }

  # Trigger recreation if snapshot changes
  triggers = {
    snapshot_id = aws_ebs_snapshot.dc_snapshot.id
  }
}
