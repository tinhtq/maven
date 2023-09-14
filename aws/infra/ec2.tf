resource "aws_key_pair" "example" {
  key_name   = "examplekey"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_ami" "amazon-ubuntu" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
data "aws_vpc" "default" {
  default = true
}
resource "aws_security_group" "instance" {
  name = "security-group-test"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = data.aws_vpc.default.id
}

resource "aws_instance" "example" {
  key_name               = aws_key_pair.example.key_name
  ami                    = data.aws_ami.amazon-ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
  tags = {
    Application = "Test"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install git -y",
      "git clone https://github.com/AkshayaPk/aws-project-1-microservices.git student",
      "mv student/* .",
      "sudo yum install wget -y",
      "wget --no-check-certificate --no-cookies --header \"Cookie: oraclelicense=accept-securebackup-cookie\" http://download.oracle.com/otn-pub/java/jdk/8u141-b15/336fa29ff2bb4ef291e347e091f7f4a7/jdk-8u141-linux-x64.rpm",
      "sudo rpm -i jdk-8u141-linux-x64.rpm",
      "java -version",
      "echo 'export JAVA_HOME=\"/usr/java/jdk1.8.0_141\"' >> ~/.bashrc ",
      "echo 'PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc",
      "source ~/.bashrc",
      "sudo wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo",
      "sudo sed -i s/\\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo",
      "sudo yum install -y apache-maven",
      "mvn --version",
      "mvn install"
    ]
  }
}
