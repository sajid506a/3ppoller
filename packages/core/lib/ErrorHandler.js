class ErrorHandler {
  static report(error) {
    // Report error to a monitoring service or log it
    console.error('Reporting error:', error);
  }
}

module.exports = ErrorHandler;
