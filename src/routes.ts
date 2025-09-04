import { Router } from 'express';
import { config } from './config';

export function createRoutes() {
  const router = Router();

  // Home route
  router.get('/', (req, res) => {
    res.json({
      message: '🐳 Docker Build Cache Test Application',
      buildInfo: config.buildInfo,
      features: config.features,
      links: {
        health: '/health',
        info: '/info',
        simulate: '/simulate'
      }
    });
  });

  // Application info
  router.get('/info', (req, res) => {
    res.json({
      name: 'test-build-cache',
      description: 'Application for testing Docker build caching strategies',
      buildInfo: config.buildInfo,
      features: config.features,
      system: {
        nodeVersion: process.version,
        platform: process.platform,
        arch: process.arch,
        uptime: process.uptime(),
        memoryUsage: process.memoryUsage()
      }
    });
  });

  // Simulate some work (useful for testing)
  router.get('/simulate/:task', (req, res) => {
    const { task } = req.params;
    const startTime = Date.now();
    
    // Simulate different types of work
    switch (task) {
      case 'cpu':
        // CPU intensive task
        let result = 0;
        for (let i = 0; i < 1000000; i++) {
          result += Math.random();
        }
        break;
        
      case 'memory':
        // Memory allocation
        const data = new Array(100000).fill(0).map((_, i) => ({
          id: i,
          value: Math.random(),
          timestamp: new Date()
        }));
        break;
        
      case 'io':
        // Simulate I/O delay
        setTimeout(() => {
          res.json({
            task,
            duration: Date.now() - startTime,
            message: 'I/O simulation completed'
          });
        }, 100);
        return;
        
      default:
        res.status(400).json({ error: 'Unknown task. Use: cpu, memory, or io' });
        return;
    }
    
    res.json({
      task,
      duration: Date.now() - startTime,
      message: `${task} simulation completed`
    });
  });

  return router;
}