# 🔒 Security Guidelines - N8N MCP Server

## Network Security Audit Results

This document outlines the security improvements implemented in the N8N MCP Server following a comprehensive network security audit.

---

## 🛡️ Security Features Implemented

### 1. SSL/TLS Certificate Verification

**Issue**: HTTP client did not explicitly verify SSL/TLS certificates.

**Solution**: 
- Enforced `verify=True` in httpx.AsyncClient configuration
- All HTTPS connections now validate server certificates
- Prevents man-in-the-middle (MITM) attacks

```python
self.client = httpx.AsyncClient(
    verify=True,  # Enforce SSL/TLS certificate verification
    # ... other settings
)
```

### 2. HTTPS-Only Connections

**Issue**: No validation that API URL uses secure HTTPS protocol.

**Solution**:
- Added `validate_https_url()` function to enforce HTTPS
- API URL validation on server startup
- Rejects HTTP connections to prevent credential exposure

```python
def validate_https_url(url: str) -> str:
    """Validate that URL uses HTTPS protocol for security"""
    parsed = urlparse(url)
    if parsed.scheme != 'https':
        raise ValueError("API URL must use HTTPS protocol")
    return url
```

### 3. Path Traversal Protection

**Issue**: No sanitization of API endpoints could allow path traversal attacks.

**Solution**:
- Implemented `_validate_endpoint()` method
- Checks for `..` and `//` patterns
- Endpoint length validation (max 500 chars)
- Whitelist-based endpoint validation

```python
ALLOWED_ENDPOINT_PATTERNS = [
    r'^/workflows$',
    r'^/workflows/[a-zA-Z0-9_-]+$',
    r'^/workflows/[a-zA-Z0-9_-]+/execute$',
    r'^/executions$',
    r'^/executions/[a-zA-Z0-9_-]+$',
]
```

### 4. Input Validation and Sanitization

**Issue**: Workflow IDs and execution IDs not validated before use.

**Solution**:
- Added `validate_id()` function for all user inputs
- Alphanumeric + hyphen/underscore validation
- Length limits (max 100 chars)
- Protection against injection attacks

```python
def validate_id(value: str, id_type: str = "ID") -> str:
    """Validate and sanitize ID inputs"""
    if not re.match(r'^[a-zA-Z0-9_-]+$', value):
        raise ValueError("Invalid ID format")
    return value.strip()
```

### 5. Rate Limiting

**Issue**: No rate limiting exposed server to DDoS attacks.

**Solution**:
- Implemented token bucket algorithm
- Default: 100 requests per 60 seconds
- Configurable via class constants
- Prevents API abuse and resource exhaustion

```python
RATE_LIMIT_REQUESTS = 100  # Maximum requests per window
RATE_LIMIT_WINDOW = 60     # Time window in seconds
```

### 6. Enhanced Timeout Configuration

**Issue**: Only global timeout, no granular control.

**Solution**:
- Separate timeouts for connect, read, write, and pool
- Connect: 10s, Read: 30s, Write: 10s, Pool: 5s
- Prevents resource hanging and DoS

```python
timeout = httpx.Timeout(
    connect=10.0,  # Connection timeout
    read=30.0,     # Read timeout
    write=10.0,    # Write timeout
    pool=5.0       # Pool timeout
)
```

### 7. Cache Size Limits (LRU Eviction)

**Issue**: Unbounded cache could lead to memory exhaustion.

**Solution**:
- Maximum 100 cached items
- LRU (Least Recently Used) eviction policy
- Prevents memory-based DoS attacks

```python
MAX_CACHE_SIZE = 100  # Maximum number of cached items

# LRU cache implementation
self._cache: OrderedDict[str, tuple[Any, datetime]] = OrderedDict()
```

### 8. Secure Headers

**Issue**: Missing security-related HTTP headers.

**Solution**:
- Added User-Agent identification
- Accept header specification
- Proper Content-Type headers

```python
self.headers = {
    "X-N8N-API-KEY": N8N_API_KEY,
    "Content-Type": "application/json",
    "User-Agent": "n8n-mcp-server/2.0.0",
    "Accept": "application/json",
}
```

### 9. Credential Protection in Logs

**Issue**: API keys and sensitive data could leak in error messages.

**Solution**:
- Sanitized log messages (removed endpoint/URL details)
- Generic error messages for users
- Detailed technical errors only in logs
- No credential exposure in exceptions

```python
# Before: Exposed endpoint details
logger.error(f"Erro HTTP {status_code} em {endpoint}: {error_detail}")

# After: Sanitized
logger.error(f"Erro HTTP {status_code} em requisição")
```

### 10. Redirect Protection

**Issue**: Automatic redirects could lead to security vulnerabilities.

**Solution**:
- Disabled automatic redirect following
- Prevents open redirect attacks
- Explicit URL control

```python
self.client = httpx.AsyncClient(
    follow_redirects=False,  # Prevent redirect-based attacks
)
```

### 11. Connection Limits

**Issue**: Unlimited connections could exhaust resources.

**Solution**:
- Max 10 total connections
- Max 5 keep-alive connections
- 5-second keep-alive expiry

```python
limits=httpx.Limits(
    max_keepalive_connections=5,
    max_connections=10,
    keepalive_expiry=5.0
)
```

---

## 🔍 Security Best Practices

### For Developers

1. **Always use HTTPS**: Never connect to N8N over HTTP
2. **Validate all inputs**: Use provided validation functions
3. **Don't log sensitive data**: Use generic error messages
4. **Keep dependencies updated**: Regularly update httpx and other packages
5. **Monitor rate limits**: Watch for unusual request patterns

### For Users

1. **Secure API Keys**: 
   - Never share your N8N API key
   - Use environment variables or .env files
   - Rotate keys regularly

2. **HTTPS Only**:
   - Ensure N8N_API_URL starts with `https://`
   - Never use HTTP connections

3. **Network Security**:
   - Use VPN when accessing N8N over public networks
   - Keep your N8N instance updated
   - Use firewall rules to restrict access

---

## 🚨 Security Configurations

### Environment Variables

```bash
# Required - Must use HTTPS
N8N_API_URL=https://your-instance.n8n.io/api/v1
N8N_API_KEY=your_secure_api_key_here
```

### Rate Limit Configuration

To adjust rate limits, modify the class constants in `N8NClient`:

```python
MAX_CACHE_SIZE = 100           # Cache size limit
RATE_LIMIT_REQUESTS = 100      # Requests per window
RATE_LIMIT_WINDOW = 60         # Window in seconds
MAX_ENDPOINT_LENGTH = 500      # Max endpoint length
```

---

## 📊 Security Audit Summary

| Vulnerability | Severity | Status |
|--------------|----------|---------|
| No SSL/TLS verification | HIGH | ✅ Fixed |
| HTTP connections allowed | HIGH | ✅ Fixed |
| Path traversal possible | HIGH | ✅ Fixed |
| No input validation | HIGH | ✅ Fixed |
| Missing rate limiting | HIGH | ✅ Fixed |
| Unbounded cache | MEDIUM | ✅ Fixed |
| Credential exposure in logs | MEDIUM | ✅ Fixed |
| Generic timeouts | MEDIUM | ✅ Fixed |
| No redirect protection | MEDIUM | ✅ Fixed |
| Missing security headers | LOW | ✅ Fixed |

---

## 🔐 Compliance

This implementation follows security best practices from:

- **OWASP Top 10** - Protection against injection, SSRF, and security misconfigurations
- **CWE-22** - Path Traversal Prevention
- **CWE-295** - Certificate Validation
- **CWE-400** - Resource Exhaustion Prevention
- **CWE-798** - Credential Protection

---

## 📝 Security Reporting

If you discover a security vulnerability, please:

1. **Do NOT** open a public issue
2. Email the maintainer directly
3. Include:
   - Vulnerability description
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

---

## 🔄 Regular Security Maintenance

### Recommended Actions

- [ ] Update dependencies monthly
- [ ] Review logs for suspicious activity
- [ ] Rotate API keys quarterly
- [ ] Audit rate limit thresholds
- [ ] Test SSL/TLS configuration
- [ ] Review and update endpoint whitelist

### Dependencies to Monitor

```
httpx >= 0.24.0      # HTTP client security
python-dotenv >= 1.0.0  # Credential management
tenacity >= 8.2.0    # Retry logic
```

---

## 📚 References

- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [httpx Security Documentation](https://www.python-httpx.org/)
- [N8N Security Best Practices](https://docs.n8n.io/hosting/security/)

---

**Last Updated**: 2025-12-26  
**Audit Version**: 1.0  
**Next Review**: 2026-03-26
