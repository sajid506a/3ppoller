# Use Node.js official image as a base image
FROM node:20

# Set the working directory to the root of the monorepo
WORKDIR /usr/src/app

# Copy the root package files for npm workspaces
COPY package.json ./

# Install all dependencies defined in the workspaces
RUN npm install

# Copy all project files into the container
COPY . .

# Set the working directory to the API service
WORKDIR /usr/src/app/packages/api

# Expose the API port
EXPOSE 3000

# Start the API server
CMD ["node", "server.js"]
