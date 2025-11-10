# 🔒 Network Security Guide - n8n-MCP-Server

## Overview

This document describes the network security measures implemented in the n8n-MCP-Server application to protect against common security vulnerabilities and ensure secure communication with the n8n API.

**Last Updated:** November 10, 2025  
**Version:** 1.0

---

## Security Features Implemented

### 1. HTTPS Enforcement

#### What it does
- Validates that API URLs use HTTPS protocol for encrypted communication
- Allows HTTP only for localhost/development environments
- Warns when HTTP is used for non-localhost connections

#### Configuration
```bash
# .env file
N8N_API_URL=https://your-n8n-instance.com/api/v1  # ✅ Secure
# N8N_API_URL=http://localhost:5678/api/v1        # ✅ OK for local dev
# N8N_API_URL=http://example.com/api/v1           # ⚠️  Warning issued
```

#### Why it matters
- Prevents man-in-the-middle (MITM) attacks
- Protects sensitive data (API keys, credentials) in transit
- Industry best practice for production environments

---

### 2. SSL/TLS Certificate Validation

#### What it does
- Validates SSL/TLS certificates by default
- Enforces minimum TLS version 1.2
- Can be disabled for development/testing (not recommended for production)

#### Configuration
```bash
# .env file
VALIDATE_SSL=true   # Default - validates certificates (recommended)
# VALIDATE_SSL=false  # Disable validation (use only for testing)
```

#### Why it matters
- Prevents connection to servers with invalid or self-signed certificates
- Protects against MITM attacks
- Ensures connection authenticity

---

### 3. Request/Response Size Limits

#### What it does
- Limits maximum request payload size (default: 5MB)
- Limits maximum response size (default: 10MB)
- Prevents memory exhaustion attacks

#### Configuration
```bash
# .env file
MAX_REQUEST_SIZE=5242880    # 5MB in bytes
MAX_RESPONSE_SIZE=10485760  # 10MB in bytes
```

#### Error Messages
```
Error: Payload muito grande. Verifique MAX_REQUEST_SIZE.
Error: Resposta muito grande. Verifique MAX_RESPONSE_SIZE.
```

#### Why it matters
- Prevents DoS (Denial of Service) attacks via large payloads
- Protects server memory from exhaustion
- Sets reasonable boundaries for API communication

---

### 4. Timeout Controls

#### What it does
- Enforces connection and request timeouts
- Validates timeout values are within safe ranges (1s - 5min)
- Prevents indefinite hanging connections

#### Configuration
```bash
# .env file
REQUEST_TIMEOUT=30000  # 30 seconds (default)
# Range: 1000 (1s) to 300000 (5min)
```

#### Why it matters
- Prevents resource exhaustion from hanging connections
- Ensures timely failure detection
- Improves application responsiveness

---

### 5. Sensitive Data Sanitization

#### What it does
- Automatically redacts sensitive information in logs
- Sanitizes API keys, passwords, tokens, and credentials
- Protects sensitive data in error messages

#### Protected Fields
- `password`
- `apiKey` / `api_key`
- `token`
- `secret`
- `authorization`
- `x-n8n-api-key`
- `credential` / `credentials`

#### Example Log Output
```
Before: Authorization: Bearer sk-1234567890abcdef
After:  Authorization: [REDACTED]

Before: { apiKey: "n8n_api_xyz123", username: "admin" }
After:  { apiKey: "[REDACTED]", username: "admin" }
```

#### Why it matters
- Prevents credential leakage in logs
- Protects against log file exposure
- Compliance with security best practices

---

### 6. Security Headers

#### What it does
- Adds security headers to all HTTP requests
- Protects against common web vulnerabilities

#### Headers Added
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Type: application/json
```

#### Why it matters
- Prevents MIME-type sniffing attacks
- Protects against clickjacking
- Adds defense-in-depth layers

---

### 7. URL Validation

#### What it does
- Validates URL format and structure
- Sanitizes URLs in logs to remove credentials
- Supports allowlist for permitted hosts (optional)

#### Configuration
```bash
# Optional: restrict to specific hosts
ALLOWED_HOSTS=n8n.example.com,localhost,127.0.0.1
```

#### Why it matters
- Prevents Server-Side Request Forgery (SSRF)
- Ensures only trusted hosts are contacted
- Adds control over external connections

---

## Security Best Practices

### For Production Deployments

1. **Always use HTTPS**
   ```bash
   N8N_API_URL=https://your-n8n-instance.com/api/v1
   ```

2. **Keep SSL validation enabled**
   ```bash
   VALIDATE_SSL=true
   ```

3. **Use API keys instead of basic auth**
   ```bash
   N8N_API_KEY=n8n_api_xxxxxxxxxxxxx
   # Avoid: N8N_USERNAME and N8N_PASSWORD
   ```

4. **Set appropriate timeouts**
   ```bash
   REQUEST_TIMEOUT=30000  # 30 seconds
   ```

5. **Configure size limits based on your needs**
   ```bash
   MAX_REQUEST_SIZE=5242880   # 5MB
   MAX_RESPONSE_SIZE=10485760 # 10MB
   ```

6. **Use INFO or WARN log level in production**
   ```bash
   LOG_LEVEL=info  # Don't use 'debug' in production
   ```

7. **Protect your .env file**
   ```bash
   chmod 600 .env
   # Add .env to .gitignore
   ```

### For Development/Testing

1. **Localhost is allowed with HTTP**
   ```bash
   N8N_API_URL=http://localhost:5678/api/v1
   ```

2. **Use DEBUG log level for troubleshooting**
   ```bash
   LOG_LEVEL=debug
   ```

3. **Can disable SSL for self-signed certs (temporary)**
   ```bash
   VALIDATE_SSL=false  # Only for testing!
   ```

---

## Security Checklist

### Before Deployment
- [ ] Using HTTPS for production API URL
- [ ] SSL validation enabled (`VALIDATE_SSL=true`)
- [ ] API key configured (not username/password)
- [ ] Appropriate timeout values set
- [ ] Size limits configured
- [ ] Log level set to `info` or `warn`
- [ ] `.env` file permissions set to 600
- [ ] `.env` is in `.gitignore`

### Regular Maintenance
- [ ] Review logs for security warnings
- [ ] Update dependencies regularly (`npm audit`)
- [ ] Monitor for unusual API activity
- [ ] Rotate API keys periodically
- [ ] Review and update timeout/size limits as needed

---

## Common Security Issues and Solutions

### Issue 1: "Must use HTTPS" Error

**Error Message:**
```
API URL must use HTTPS or be localhost for security
```

**Solution:**
Update your API URL to use HTTPS:
```bash
N8N_API_URL=https://your-n8n-instance.com/api/v1
```

For local development, use:
```bash
N8N_API_URL=http://localhost:5678/api/v1
```

---

### Issue 2: SSL Certificate Validation Fails

**Error Message:**
```
Error: unable to verify the first certificate
```

**Solutions:**

1. **Recommended:** Fix your SSL certificate on the n8n server

2. **Temporary (dev only):** Disable SSL validation
   ```bash
   VALIDATE_SSL=false
   ```

---

### Issue 3: Request Timeout

**Error Message:**
```
Timeout na requisição. Verifique REQUEST_TIMEOUT.
```

**Solution:**
Increase the timeout value:
```bash
REQUEST_TIMEOUT=60000  # 60 seconds
```

---

### Issue 4: Payload Too Large

**Error Message:**
```
Payload muito grande. Verifique MAX_REQUEST_SIZE.
```

**Solution:**
Increase the request size limit:
```bash
MAX_REQUEST_SIZE=10485760  # 10MB
```

---

### Issue 5: Response Too Large

**Error Message:**
```
Resposta muito grande. Verifique MAX_RESPONSE_SIZE.
```

**Solution:**
Increase the response size limit:
```bash
MAX_RESPONSE_SIZE=20971520  # 20MB
```

---

## Security Testing

### Test HTTPS Enforcement
```bash
# Should work
N8N_API_URL=https://example.com/api npm start

# Should work (localhost)
N8N_API_URL=http://localhost:5678/api npm start

# Should show warning
N8N_API_URL=http://example.com/api npm start
```

### Test Size Limits
```bash
# Set small limits for testing
MAX_REQUEST_SIZE=1024    # 1KB
MAX_RESPONSE_SIZE=1024   # 1KB

npm start
# Try to create a large workflow to test limits
```

### Test SSL Validation
```bash
# Test with self-signed certificate
VALIDATE_SSL=true npm start
# Should fail with certificate error

VALIDATE_SSL=false npm start
# Should work but show warning
```

---

## Vulnerability Reporting

If you discover a security vulnerability, please:

1. **DO NOT** open a public issue
2. Email the security team at: [security contact]
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

---

## Compliance

These security measures help meet requirements for:
- **OWASP Top 10** protection
- **SOC 2** compliance
- **GDPR** data protection
- **PCI DSS** (if handling payment data)

---

## Additional Resources

### Related Documentation
- [Security Documentation](/security/SECURITY-DOCUMENTATION.md) - Infrastructure security
- [README.md](/README.md) - General project documentation

### External Resources
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [Mozilla Web Security Guidelines](https://infosec.mozilla.org/guidelines/web_security)
- [n8n Security Documentation](https://docs.n8n.io/hosting/security/)

---

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-10 | 1.0 | Initial network security implementation |

---

**Security Contact:** jricardosouza  
**Next Review:** 2025-12-10
