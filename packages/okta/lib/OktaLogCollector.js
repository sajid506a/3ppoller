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
