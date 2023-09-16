# Use a more recent version of Alpine
FROM alpine:3.14

# Install terraform, git, curl in a single step
RUN apk add --no-cache terraform git curl --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community

# Install Infracost using the official method
RUN curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh -s -- -b /usr/local/bin v0.10.29

# Downloads the CLI based on your OS/arch and puts it in /usr/local/bin


# Install curl github-cli
RUN apk add git curl github-cli
# Set up the working directory and add the entrypoint script
WORKDIR /app
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]