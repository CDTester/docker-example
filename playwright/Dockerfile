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
