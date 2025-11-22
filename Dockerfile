FROM debian:trixie as builder
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
	apt-get install -q -y golang git-core && \
	apt-get clean

ENV GOPATH=/root/go
RUN mkdir -p /root/go/src
COPY rest-api /root/go/src/dyndns

WORKDIR /root/go/src/dyndns

RUN go mod init dyndns && \
    go get -d -v && \
    go test -v

RUN go build -o /root/go/bin/dyndns .

FROM debian:trixie-slim
MAINTAINER David Prandzioch <hello+ddns@davd.eu>

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
	apt-get install -q -y bind9 dnsutils && \
	apt-get clean

RUN chmod 770 /var/cache/bind
COPY setup.sh /root/setup.sh
RUN chmod +x /root/setup.sh
COPY named.conf.options /etc/bind/named.conf.options
COPY --from=builder /root/go/bin/dyndns /root/dyndns

EXPOSE 53 8080
CMD ["sh", "-c", "/root/setup.sh ; service named start ; /root/dyndns"]
