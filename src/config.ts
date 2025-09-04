export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  environment: process.env.NODE_ENV || 'development',
  
  // Simulated build-time configuration that might change
  buildInfo: {
    version: '1.0.0',
    buildTime: new Date().toISOString(),
    gitCommit: process.env.GIT_COMMIT || 'unknown'
  },
  
  // Feature flags that might be toggled
  features: {
    enableMetrics: process.env.ENABLE_METRICS === 'true',
    enableDebugMode: process.env.DEBUG === 'true',
    enableCaching: process.env.ENABLE_CACHING !== 'false'
  }
};