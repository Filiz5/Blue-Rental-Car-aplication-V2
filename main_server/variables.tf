variable "mykey" {
  default = "Meliskey"   #change here
}

variable "instancetype" {
  default = "t3a.medium"
}
variable "tag" {
  default = "Main_Server_Techpro"
}
variable "devops-sg" {
  default = "devops-server-sec-gr"
}

variable "user" {
  default = "techpro"
}