resource "aws_instance" "web" {
    ami = var.ami_id
    instance_type = var.instance_type

    security_groups = [aws_security_group.web_sg.name]

    tags = {
        Name : "Terraform-ec2"
        Environment : var.environment
    }



}