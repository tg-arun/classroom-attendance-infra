output "state_bucket" {
  description = "Bucket name to put in backend.hcl for the root stack."
  value       = aws_s3_bucket.state.id
}

output "backend_hcl" {
  description = "Copy this into ../backend.hcl."
  value       = "bucket = \"${aws_s3_bucket.state.id}\""
}
