function fn() {
  var env = karate.env;
  var baseUrl = karate.properties['baseUrl'];
  
  karate.log('karate.env system property was:', env);
  
  if (!env) {
    env = 'local';
  }
  
  var config = {
    env: env,
    baseUrl: baseUrl || '',
    timeoutMs: 5000
  };
  
  karate.configure('connectTimeout', config.timeoutMs);
  karate.configure('readTimeout', config.timeoutMs);
  
  return config;
}
