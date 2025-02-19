#!/bin/bash
set -e

echo "Creating project structure..."

# Create directories
mkdir -p packages/core/lib
mkdir -p packages/api/controllers
mkdir -p packages/okta/lib
mkdir -p packages/o365

# ----------------------------
# Root package.json
# ----------------------------
cat > package.json <<'EOF'
{
  "name": "log-collector-sdk",
  "private": true,
  "workspaces": [
    "packages/core",
    "packages/okta",
    "packages/o365",
    "packages/api"
  ]
}
EOF

# ----------------------------
# packages/core/package.json
# ----------------------------
cat > packages/core/package.json <<'EOF'
{
  "name": "@log-collector-sdk/core",
  "version": "1.0.0",
  "main": "lib/index.js"
}
EOF

# ----------------------------
# packages/core/lib/Poller.js
# ----------------------------
cat > packages/core/lib/Poller.js <<'EOF'
const axios = require('axios');

class Poller {
  constructor(customerId, config) {
    this.customerId = customerId;
    this.config = config;
    this.paginationToken = null;
  }

  async fetchLogs() {
    let response;
    try {
      response = await axios.get(this.config.endpoint, {
        params: { token: this.paginationToken },
      });
      this.paginationToken = this.getNextPageToken(response.data);
      return response.data.logs;
    } catch (error) {
      this.handleRateLimit(error);
      throw error;
    }
  }

  getNextPageToken(data) {
    // Base implementation – vendors should override as needed.
    return data.nextPageToken || null;
  }

  handleRateLimit(error) {
    // Generic rate-limit handling logic.
    if (error.response && error.response.status === 429) {
      console.warn(`Rate limited for customer ${this.customerId}. Retrying after delay...`);
      // implement retry logic or delay
    }
  }
}

module.exports = Poller;
EOF

# ----------------------------
# packages/core/lib/LogCollector.js
# ----------------------------
cat > packages/core/lib/LogCollector.js <<'EOF'
const { Worker } = require('worker_threads');

class LogCollector {
  constructor(customerId, config, VendorPoller) {
    this.customerId = customerId;
    this.config = config;
    this.VendorPoller = VendorPoller; // the vendor-specific poller class
  }

  start() {
    // Launch a new worker thread per customer
    const worker = new Worker('./worker.js', {
      workerData: {
        customerId: this.customerId,
        config: this.config,
      },
    });
    worker.on('message', (msg) => console.log(`Customer ${this.customerId}:`, msg));
    worker.on('error', (err) => console.error(`Worker error for ${this.customerId}:`, err));
  }
}

module.exports = LogCollector;
EOF

# ----------------------------
# packages/core/lib/LogSender.js
# ----------------------------
cat > packages/core/lib/LogSender.js <<'EOF'
class LogSender {
  constructor(destinationUrl) {
    this.destinationUrl = destinationUrl;
  }

  async send(logs) {
    // Implementation to send logs (e.g., using HTTP POST)
    console.log(`Sending logs to ${this.destinationUrl}`, logs);
  }
}

module.exports = LogSender;
EOF

# ----------------------------
# packages/core/lib/ErrorHandler.js
# ----------------------------
cat > packages/core/lib/ErrorHandler.js <<'EOF'
class ErrorHandler {
  static report(error) {
    // Report error to a monitoring service or log it
    console.error('Reporting error:', error);
  }
}

module.exports = ErrorHandler;
EOF

# ----------------------------
# packages/core/lib/CustomerState.js
# ----------------------------
cat > packages/core/lib/CustomerState.js <<'EOF'
class CustomerState {
  constructor() {
    this.customers = new Map();
  }

  register(customerId, state) {
    this.customers.set(customerId, state);
  }

  update(customerId, newState) {
    this.customers.set(customerId, { ...this.customers.get(customerId), ...newState });
  }

  get(customerId) {
    return this.customers.get(customerId);
  }
}

module.exports = new CustomerState();
EOF

# ----------------------------
# packages/core/worker.js
# ----------------------------
cat > packages/core/worker.js <<'EOF'
const { parentPort, workerData } = require('worker_threads');
const OktaPoller = require('@log-collector-sdk/okta/lib/OktaLogCollector');

async function pollLogs() {
  const { customerId, config } = workerData;
  // Example for Okta; you would determine vendor dynamically
  const poller = new OktaPoller(customerId, config);
  while (true) {
    try {
      const logs = await poller.fetchLogs();
      parentPort.postMessage({ customerId, logs });
    } catch (err) {
      parentPort.postMessage({ customerId, error: err.message });
    }
    // Wait a specified interval before next poll (could be vendor/config specific)
    await new Promise((resolve) => setTimeout(resolve, config.pollInterval || 5000));
  }
}

pollLogs();
EOF

# ----------------------------
# packages/okta/package.json
# ----------------------------
cat > packages/okta/package.json <<'EOF'
{
  "name": "okta",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "@log-collector-sdk/core": "*"
  }
}
EOF

# ----------------------------
# packages/okta/lib/OktaLogCollector.js
# ----------------------------
cat > packages/okta/lib/OktaLogCollector.js <<'EOF'
const Poller = require('@log-collector-sdk/core/lib/Poller');

class OktaPoller extends Poller {
  getNextPageToken(data) {
    // Okta-specific token extraction
    return data.nextCursor || null;
  }

  handleRateLimit(error) {
    // Okta-specific rate limit logic, e.g., reading Retry-After header
    if (error.response && error.response.headers['retry-after']) {
      const delay = parseInt(error.response.headers['retry-after'], 10) * 1000;
      console.warn(`Okta rate limit hit. Waiting ${delay} ms before retrying...`);
      // add vendor-specific wait logic
    }
  }
}

module.exports = OktaPoller;
EOF

# ----------------------------
# packages/okta/Dockerfile
# ----------------------------
cat > packages/okta/Dockerfile <<'EOF'
FROM node:20

WORKDIR /usr/src/app

# Copy only the Okta package and install dependencies
COPY package.json ./
RUN npm install

COPY . .

CMD ["node", "index.js"]
EOF

# ----------------------------
# packages/api/package.json
# ----------------------------
cat > packages/api/package.json <<'EOF'
{
  "name": "api",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.17.1",
    "@log-collector-sdk/core": "*"
  }
}
EOF

# ----------------------------
# packages/api/server.js
# ----------------------------
cat > packages/api/server.js <<'EOF'
const express = require('express');
const customerState = require('@log-collector-sdk/core/lib/CustomerState');
const registrationController = require('./controllers/registration');
const healthController = require('./controllers/health');

const app = express();
app.use(express.json());

app.post('/register', registrationController.register);
app.delete('/unregister', registrationController.unregister);
app.get('/health', healthController.check);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`API running on port ${PORT}`));
EOF

# ----------------------------
# packages/api/controllers/registration.js
# ----------------------------
cat > packages/api/controllers/registration.js <<'EOF'
const customerState = require('@log-collector-sdk/core/lib/CustomerState');

exports.register = (req, res) => {
  const { customerId, vendor, config } = req.body;
  // Initialize customer state
  customerState.register(customerId, { config, vendor, active: true });

  // Depending on vendor, create a new collector (for instance, Okta)
  // This is where you’d spawn a worker thread or start a process
  console.log(`Registered customer ${customerId} for vendor ${vendor}`);

  res.status(200).json({ message: 'Customer registered successfully' });
};

exports.unregister = (req, res) => {
  const { customerId } = req.body;
  // Remove customer state and stop collector logic if needed.
  customerState.customers.delete(customerId);
  console.log(`Unregistered customer ${customerId}`);
  res.status(200).json({ message: 'Customer unregistered successfully' });
};
EOF

# ----------------------------
# packages/api/controllers/health.js
# ----------------------------
cat > packages/api/controllers/health.js <<'EOF'
const customerState = require('@log-collector-sdk/core/lib/CustomerState');

exports.check = (req, res) => {
  // You could iterate through customers and check the status of each collector.
  res.status(200).json({ status: 'ok', customers: Array.from(customerState.customers.keys()) });
};
EOF

# ----------------------------
# Root docker-compose.yml
# ----------------------------
cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  okta:
    build: ./packages/okta
    ports:
      - "4000:4000"
  o365:
    build: ./packages/o365
    ports:
      - "4001:4001"
  api:
    build: ./packages/api
    ports:
      - "3000:3000"
EOF

echo "Project structure and files created successfully."
