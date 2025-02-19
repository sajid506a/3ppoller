FROM node:20

# Set the working directory to the repository root
WORKDIR /usr/src/app

# Copy the entire repository
COPY . .

# Install dependencies for all workspaces (using npm ci or npm install)
RUN npm install --production

# Switch to the API service directory
WORKDIR /usr/src/app/packages/api

# Expose the API port
EXPOSE 3000

# Start the API server
CMD ["node", "server.js"]
