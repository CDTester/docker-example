# DOCKER

## Build Status
[![Test Status](https://github.com/CDTester/docker-example/actions/workflows/playwright.yml/badge.svg)](https://github.com/CDTester/docker-example/actions/workflows/playwright.yml)
[![Test Report](https://github.com/CDTester/docker-example/actions/workflows/pages/pages-build-deployment/badge.svg)](https://github.com/CDTester/docker-example/actions/workflows/pages/pages-build-deployment)

## Latest CI/CD Build Report
https://cdtester.github.io/docker-example/


To build the playwright tests and then execute the tests, run 

```bash
docker compose up --build
docker run --rm -p 4040:4040 playwright-tests
```

The allure reports can then be opened on http://localhost:4040


## Docker File
The Dockerfile are instructions for telling docker how to build the image.

```Dockerfile
# Use official Playwright image with pre-installed browsers
FROM mcr.microsoft.com/playwright:v1.58.2-jammy

# Install Java (required for Allure CLI)
RUN apt-get update && apt-get install -y \
    default-jre \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Install Allure CLI
RUN npm install -g allure-commandline

# Copy the rest of your application
COPY . .

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 4040

ENTRYPOINT ["./entrypoint.sh"]
```


### FROM
This bases your image on another image, in this case from node version 22

```dockerfile
FROM node:22-alpine
```

> [!NOTE] <br>
> -slim is a slim version of node <br>
> -alpine is an even slimmer version of node. But this can have very limited usage, like no bash

You can create multi stage builds. This is good for creating a builder and a runner. e.g.

```dockerfile
FROM node:22-alpine as builder
WORKDIR /app
COPY . .
RUN npm install

FROM node:22-alpine as runner
COPY --from=builder /app /app
RUN npm run test
EXPOSE 8000
```

### ARG
Arguments to be passed in to the build

```dockerfile
ARG PLAYWRIGHT_BROWSERS_PATH
```

### ENV
Environment variables.

```dockerfile
ENV PLAYWRIGHT_BROWSERS_PATH=${PLAYWRIGHT_BROWSERS_PATH}
```

### WORKDIR
Sets a working directory in your image. It is common practice to name your dir /app.

```dockerfile
WORKDIR /app
```

### COPY
Copy will copy a file from a location to another location. This can be used to copy e.g. package file from to the image build location. 

```dockerfile
COPY package*.json ./
COPY ./src ./src
COPY ./public ./public
```

### RUN
Runs a command inside the image

### EXPOSE
Expose the port that the application listens on. The EXPOSE command does not actually publish the port, it functions as a type of documentation between the person who builds the image and the person who runs the container about which ports are intended to be published.

```dockerfile
EXPOSE 3000
```

> [!NOTE] <br>
> You still need to use -p when you `docker run <containerName> -p 3000`


### CMD
Specifies the default command if none provided when you run the container. Can either be a sting or array of strings.

```dockerfile
CMD npm run dev
```

or

```dockerfile
CMD [ "serve", "-s", "build" ]
```

### ENTRYPOINT
Entrypoint overrides CMD. If you need the container to execute multiple CMD then you need to run a shell script, e.g. run tests then run allure reports 


## LAYERS
Like image diffs. Each command creates a layer. Immutable, even deletes create new layers. Images are made of layers.

```dockerfile
ENTRYPOINT ["./entrypoint.sh"]
```


## Entrypoint shell file
```bash
#!/bin/bash
set -e

# Run Playwright tests (will still continue even if tests fail)
npm run testChrome || true

# Generate Allure report
npx allure generate allure-results --clean -o allure-report

# Bind to 0.0.0.0 so it's accessible outside the container
npx allure open allure-report --port 4040 --host 0.0.0.0
```


## COMPOSE
When you application has multiple components (containers). For this you need a compose.yml.

### Compose.yml
Each container is listed under services. 

```yml
services:
  backend:
    image: mysite-backend
    container_name: mysite-backend
    build: 
      context: ./app                 # location the image will be built to
      dockerfile: Dockerfile         # location of containers dockerfile
      target: runner
    ports:
      - 8000:8000

  frontend:
    image: mysite-frontend
    container_name: mysite-frontend
    build: 
      context: ./app
      dockerfile: Dockerfile
    ports:
      - 80:80
```

To persist data in your containers from when they go up or down, can add mongodb e.g.

```yml
services:
  mongodb:
    image: mongo:7.0.12
    container_name: mysite-mongodb
    volumes: 
      - mongodb-data: /data/db
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: example

volumes:
  mongodb-data:
```

> [!NOTE] <br>
> This sets environment variables.  
>```yml 
> environment: 
>   MONGO_INITDB_ROOT_USERNAME: root
>   MONGO_INITDB_ROOT_PASSWORD: example
>``` 

you can take out username and password and put in a `.env` file.
> [!IMPORTANT] <br>
> add .env to you .gitignore file

```
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=example
```

i.e.
```yml
services:
  mongodb:
    image: mongo:7.0.12
    container_name: mysite-mongodb
    volumes: 
      - mongodb-data: /data/db
    env_file:
      - ./.env

volumes:
  mongodb-data:
```

Need to add mong d connection to backend .env and create mongo db functionality in you application to read .env variables.

> [!NOTE] <br>
> This will not pull someone elses image from dockerHub that might have the same name. 
> ```yml
> pull_policy: never
> ```
>
> NOT SURE ABOUT THIS
> ```yml
>develop:`
>  watch:
>    - path: ./app/package.json
>      action: rebuild
>    - path: ./app
>      target: /usr/src/app
>      action: sync
> ```
> ?


### build 
`docker compose build`

### start up all containers
`docker compose up -d`

> [!NOTE] <br>
> -d flag tells Docker Compose to run containers in detached mode, meaning they start in the background and immediately return control of your terminal while continuing to run. #

### shut down and delete all containers
`docker compose down -d`

### edit open containers using watch
`docker compose watch`


## Publishing your docker image
Need a docker registry. Most popular is dockerhub.
https://hub.docker.com

```yml
services:
  demo:
    image: docker.io/<accountName>/<image:version>
```


Build and tag the image
```bash
docker build -t ghcr.io/<github-username>/<repo-name>:latest .
```

2. Login to GHCR
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u <github-username> --password-stdin
```

3. Push the image
```bash
docker push ghcr.io/<github-username>/<repo-name>:latest
```

4. Use it in docker-compose
```yml
services:
  app:
    image: ghcr.io/<github-username>/<repo-name>:latest
```

then run 
`docker compose up`

## Docker commands

### lists iamges #
`docker image ls`

```shell
                                                                             i Info ?   U  In Use
IMAGE                                 ID          DISK USAGE   CONTENT SIZE   EXTRA
docker/welcome-to-docker:latest       c4d56       22.2MB         6.03MB    U   
hello-world:latest                    ef54e       25.9kB         9.52kB    U 
postgres:latest                       1090b        649MB          168MB    U 
```

### shows containers running
`docker ps`

```shell
CONTAINER ID   IMAGE                      COMMAND                  CREATED          STATUS          PORTS                           				NAMES
f8d0           welcome-to-docker:latest   "docker-entrypoint.s…"   34 seconds ago   Up 34 seconds   0.0.0.0:8089->3000/tcp, [::]:8089->3000/tcp   clever_mahavira
```

or
`docker ps -a`

```shell
CONTAINER ID   IMAGE    COMMAND                  CREATED              STATUS                        PORTS                                         NAMES
f8d0           docker:latest    "docker-entrypoint.s…"   About a minute ago   Up About a minute             0.0.0.0:8089->3000/tcp, [::]:8089->3000/tcp   clever_mahavira
3f38           hello-world      "/hello"                 10 minutes ago       Exited (0) 10 minutes ago                                                    cranky_poitras
6067           postgres:latest  "docker-entrypoint.s…"   51 minutes ago       Exited (1) 48 minutes ago                                                    postgres
```

### build docker image
`docker build -t welcome-to-docker . `
> [!NOTE] <br>
> -t flag tags your image with a name. <br>
> . tells docker the location to build from


### run docker image
`docker run <containerName> `

> [!NOTE] <br>
> -p 5000:80  This runs the containers port 80 on your port 5000 <br>
> -d run detached mode (in background) so you can use terminal #
> --name <myContainerName> this gives the container a name rather than a randomly generated name
> --rm this removes the container after running
> -i is for interactive
> -t is for tty allows terminal features


### docker logs
`docker logs <containerName>`
up 

### Stop and delete containers
`docker container prune <containerName>`


### Run commands on a docker container
`docker exec -it <containerName> <commands>`

> [!NOTE] <br>
> -i is for interactive
> -t is for tty allows terminal features