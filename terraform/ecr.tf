# Immutable tags: every pushed tag names exactly one image, forever.
# force_delete lets `terraform destroy` remove the repo even with images in it.
resource "aws_ecr_repository" "hello_service" {
  name                 = "hello-service"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true
}
