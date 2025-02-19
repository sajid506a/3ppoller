FROM node:20

WORKDIR /usr/src/app

# Copy the package files for the Okta service
COPY package.json ./

# Install dependencies (this assumes the workspace is already set up; adjust if needed)
RUN npm install

# Copy the entire project (or just the Okta service files)
COPY . .

WORKDIR /usr/src/app/packages/okta

# Expose the port if the service listens on one (adjust port number as needed)
EXPOSE 4000

# Start the Okta collector
CMD ["node", "index.js"]
