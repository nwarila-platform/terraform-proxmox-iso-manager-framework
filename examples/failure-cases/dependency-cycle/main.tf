resource "terraform_data" "left" {
  input = terraform_data.right.output
}

resource "terraform_data" "right" {
  input = terraform_data.left.output
}
