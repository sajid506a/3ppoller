FROM node:20

# Set the working directory to the repository root
WORKDIR /usr/src/app

# Copy the entire repository
COPY . .

# Install dependencies for all workspaces
RUN npm install --production

# Switch to the Okta service directory
WORKDIR /usr/src/app/packages/okta

# Expose the port if your collector listens on one (adjust port if needed)
EXPOSE 4000

# Start the Okta collector
CMD ["node", "index.js"]
