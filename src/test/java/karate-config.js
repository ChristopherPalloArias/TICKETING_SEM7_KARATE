function fn() {
  var env = karate.env;
  
  karate.log('karate.env system property was:', env);
  
  if (!env) {
    env = 'local';
  }
  
  var config = {
    env: env,
    baseUrlEvents: karate.properties['baseUrlEvents'] || 'http://localhost:8081',
    baseUrlTicketing: karate.properties['baseUrlTicketing'] || 'http://localhost:8082',
    baseUrlNotifications: karate.properties['baseUrlNotifications'] || 'http://localhost:8083',
    ticketingDb: karate.properties['ticketingDb'] || 'jdbc:postgresql://localhost:5434/ticketing_db',
    eventsDb: karate.properties['eventsDb'] || 'jdbc:postgresql://localhost:5433/events_db',
    dbUser: karate.properties['dbUser'] || 'postgres',
    dbPass: karate.properties['dbPass'] || 'postgres',
    timeoutMs: 30000
  };
  
  karate.configure('connectTimeout', config.timeoutMs);
  karate.configure('readTimeout', config.timeoutMs);
  
  return config;
}
