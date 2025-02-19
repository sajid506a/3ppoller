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
