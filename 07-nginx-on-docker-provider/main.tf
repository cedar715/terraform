provider "docker" {
  host = "tcp://127.0.0.1:2375"
}

resource "docker_image" "nginx" {
  name = "nginx:1.11-alpine"
}

resource "docker_container" "nginx-ctr" {
  image = docker_image.nginx.latest
  name = "nginx-server"
  ports {
    internal = 80
    external = 8089
  }
  volumes {
    container_path = "/usr/share/nginx/html"
    host_path = "/home/jai/scrapbook/tutorial/www"
  }
}

resource "docker_container" "nginx-multiple-ctrs" {
  count = 2
  image = docker_image.nginx.latest
  name = "nginx-server-${count.index+1}"
  ports {
    internal = 80
  }
  volumes {
    container_path = "/usr/share/nginx/html"
    host_path = "/home/jai/scrapbook/tutorial/www"
  }
}