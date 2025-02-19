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
