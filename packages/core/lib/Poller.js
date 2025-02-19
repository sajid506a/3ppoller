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
