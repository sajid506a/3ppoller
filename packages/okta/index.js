const OktaPoller = require('./lib/OktaLogCollector');

const config = {
  endpoint: 'https://example.okta.com/api/v1/logs', // Replace with your Okta logs endpoint
  pollInterval: 5000  // Adjust as needed
};

const customerId = 'customer_123';

async function runCollector() {
  const poller = new OktaPoller(customerId, config);
  while (true) {
    try {
      const logs = await poller.fetchLogs();
      console.log(`Logs for ${customerId}:`, logs);
    } catch (error) {
      console.error(`Error fetching logs for ${customerId}:`, error.message);
    }
    await new Promise(resolve => setTimeout(resolve, config.pollInterval));
  }
}

runCollector();
