
# Nginx 💖 with Auto SSL
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/xiaojun207/nginx?sort=semver)](https://hub.docker.com/r/xiaojun207/nginx)
[![Docker Image Size (latest semver)](https://img.shields.io/docker/image-size/xiaojun207/nginx?sort=semver)](https://hub.docker.com/r/xiaojun207/nginx)
[![Docker Image Size (latest semver)](https://img.shields.io/docker/pulls/xiaojun207/nginx)](https://hub.docker.com/r/xiaojun207/nginx)

arch: linux/amd64, linux/arm64

# 描述(Desc)
这是一个可以自动申请（并自动更新）ssl证书的nginx镜像。证书申请和更新使用的是开源工具acme.sh。
你可以设置证书服务商：zerossl, letsencrypt，buypass，ssl等等，或是地址，如Letsencrypt测试地址：https://acme-staging-v02.api.letsencrypt.org/directory
nginx with auto ssl image，use acme.sh ， you can set default-ca,like: zerossl, letsencrypt，buypass，ssl ...


# 快速启动(Quick Start)

```shell
  docker pull  xiaojun207/nginx:latest
```

使用例子，如下(eg.)：
```shell

 docker run -d -p 80:80 -p 443:443 -v "/data/web":/data/web \
      -v "/data/nginx/nginx/ssl":/etc/nginx/ssl \
      -v "/data/nginx/nginx/conf.d":/etc/nginx/conf.d \
      -v "/data/nginx/acme_cert":/acme_cert \
      -e DOMAINS="example.com www.example.com test.example.com test2.example.com" \
      -e SslServer="zerossl" \
      -e mail="youmail@example.com" \
      --name nginx xiaojun207/nginx:latest
```
注意：建议把路径/etc/nginx/ssl、/acme_cert中的内容都持久化到宿主机保存，避免容器删除后，启动后会自动再次获取（频繁申请证书会被服务商限制）。

# 使用说明
默认情况下, 使用的是服务器验证，所以请确保，被申请ssl的域名可以访问到nginx容器。

# 参数说明

| 参数         | 是否必填 | 说明                                                                                                                                     |
|------------|------|----------------------------------------------------------------------------------------------------------------------------------------|
| DOMAINS    | 必填   | 域名列表参数是acme用来自动获取ssl，多域名以空格分隔。如果为空或不填，这就是个普通的nginx镜像，哈哈。                                                                               |
| mail       | 必填   | 你的邮箱，用于获取ssl时配置                                                                                                                        |
| SslServer  | 否    | 证书服务商（名字或地址），默认：zerossl，你还可以使用：letsencrypt，buypass，ssl等等，<br>或者letsencrypt的测试地址：https://acme-staging-v02.api.letsencrypt.org/directory |

# 证书路径和nginx配置方法
容器启动，会创建一个默认证书，避免nginx启动失败。 证书获取成功后，将会被安装到/etc/nginx/ssl/app/，

nginx配置方法如下：
```shell
    server {
        # 80端口必须可以正常访问，用来验证你的域名
        listen      80;
        server_name example.com;
        # ...
    }
    
    server {
        listen      443 ssl;
        server_name example.com;
        root /data/web/www;
    
        ssl_stapling off;
        ssl_certificate /etc/nginx/ssl/app/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/app/key.pem;
    
        # ...
    }

```

# 证书更新
证书会定期检查是否快要过期，如果快要过期，会自动更新并安装证书，你可以高枕无忧了（理论上的，我的证书还没到期，哈哈）。

# 非常感谢，参考连接

https://github.com/neilpang/acme.sh.git

https://github.com/akeylimepie/docker-nginx-letsencrypt

https://blog.csdn.net/dancen/article/details/121044863


