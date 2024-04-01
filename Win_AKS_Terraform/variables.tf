variable "resource_group" {
    type = string
    description = "Resource group name"
    default = "1-49bb2a13-playground-sandbox"
}

variable "location" {
    type = string
    description = "RG and resources location"
    default = "South Central US"
}

variable "node_count_linux" {
    type = number
    description = "Linux nodes count"
    default = 1
}

variable "node_count_windows" {
    type = number
    description = "Windows nodes count"
    default = 2
}