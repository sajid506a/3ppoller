FROM node:16

WORKDIR /usr/src/app

# Copy only the Okta package and install dependencies
COPY package.json ./
RUN npm install

COPY . .

CMD ["node", "index.js"]
