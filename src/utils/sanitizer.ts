/**
 * Utility functions for sanitizing sensitive data in logs and errors
 */

const SENSITIVE_KEYS = [
  'password',
  'apiKey',
  'api_key',
  'token',
  'secret',
  'authorization',
  'x-n8n-api-key',
  'auth',
  'credential',
  'credentials',
];

/**
 * Sanitize an object by redacting sensitive fields
 */
export function sanitizeObject(obj: any, depth = 0): any {
  if (depth > 10) return '[Max Depth Reached]';
  
  if (obj === null || obj === undefined) {
    return obj;
  }

  if (typeof obj !== 'object') {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map(item => sanitizeObject(item, depth + 1));
  }

  const sanitized: any = {};
  
  for (const [key, value] of Object.entries(obj)) {
    const lowerKey = key.toLowerCase();
    
    if (SENSITIVE_KEYS.some(sensitive => lowerKey.includes(sensitive))) {
      sanitized[key] = '[REDACTED]';
    } else if (typeof value === 'object' && value !== null) {
      sanitized[key] = sanitizeObject(value, depth + 1);
    } else {
      sanitized[key] = value;
    }
  }

  return sanitized;
}

/**
 * Sanitize a URL by removing sensitive query parameters and credentials
 */
export function sanitizeUrl(url: string): string {
  try {
    const urlObj = new URL(url);
    
    // Remove password from URL if present
    if (urlObj.password) {
      urlObj.password = '[REDACTED]';
    }
    
    // Redact sensitive query parameters
    const params = urlObj.searchParams;
    SENSITIVE_KEYS.forEach(key => {
      if (params.has(key)) {
        params.set(key, '[REDACTED]');
      }
    });
    
    return urlObj.toString();
  } catch {
    // If URL parsing fails, just return as is
    return url;
  }
}

/**
 * Sanitize headers by redacting sensitive values
 */
export function sanitizeHeaders(headers: Record<string, any>): Record<string, any> {
  const sanitized: Record<string, any> = {};
  
  for (const [key, value] of Object.entries(headers)) {
    const lowerKey = key.toLowerCase();
    
    if (SENSITIVE_KEYS.some(sensitive => lowerKey.includes(sensitive))) {
      sanitized[key] = '[REDACTED]';
    } else {
      sanitized[key] = value;
    }
  }
  
  return sanitized;
}
