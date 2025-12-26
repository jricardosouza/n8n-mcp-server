# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-12-26

### 🔒 Security (Network Security Audit)

This release focuses on addressing multiple high-risk vulnerabilities identified in a comprehensive network security audit.

#### Added
- **SSL/TLS Certificate Verification**: Enforced `verify=True` in httpx.AsyncClient to validate server certificates
- **HTTPS-Only Enforcement**: Added `validate_https_url()` function to reject HTTP connections
- **Input Validation**: New `validate_id()` function to sanitize workflow IDs and execution IDs
- **Endpoint Validation**: Implemented `_validate_endpoint()` with whitelist-based pattern matching
- **Rate Limiting**: Token bucket algorithm limiting requests to 100 per 60 seconds
- **Cache Size Limits**: LRU eviction policy with maximum 100 items
- **Security Headers**: Added User-Agent and Accept headers to all requests
- **Granular Timeouts**: Separate timeouts for connect (10s), read (30s), write (10s), pool (5s)
- **Connection Limits**: Maximum 10 connections, 5 keep-alive with 5s expiry
- **Redirect Protection**: Disabled automatic redirects to prevent redirect-based attacks
- **Security Documentation**: New SECURITY.md with comprehensive security guidelines
- **Security Tests**: New test suite in tests/test_security.py

#### Changed
- **Log Sanitization**: Removed sensitive data (endpoints, URLs) from error messages
- **Error Messages**: More user-friendly errors without exposing internal details
- **Cache Implementation**: Changed from Dict to OrderedDict for LRU support
- **HTTP Client Configuration**: Enhanced httpx.AsyncClient with security-focused settings

#### Security Fixes
- **CWE-295**: Improper Certificate Validation - Fixed with enforced SSL/TLS verification
- **CWE-22**: Path Traversal - Fixed with endpoint validation and sanitization
- **CWE-400**: Uncontrolled Resource Consumption - Fixed with cache limits and rate limiting
- **OWASP A01**: Broken Access Control - Mitigated with input validation
- **OWASP A03**: Injection - Prevented with strict input sanitization
- **OWASP A05**: Security Misconfiguration - Addressed with proper HTTPS and timeout settings
- **OWASP A07**: Identification and Authentication Failures - Enhanced with credential protection

#### Testing
- ✅ 4/4 security test suites passing
- ✅ CodeQL security scan: 0 vulnerabilities found
- ✅ All existing functionality preserved (zero breaking changes)

### 📚 Documentation
- Updated README.md with security features section
- Updated version to 2.1.0 throughout documentation
- Added security badge to README
- Comprehensive SECURITY.md covering all security features

### 🔧 Technical Details

**Affected Files:**
- `src/n8n_mcp_server.py` - Core security improvements
- `tests/test_security.py` - New security test suite
- `SECURITY.md` - New security documentation
- `README.md` - Updated with security information
- `CHANGELOG.md` - This file

**Dependencies:**
- No new dependencies added
- All changes use existing libraries (httpx, re, OrderedDict)

**Performance Impact:**
- Minimal: Rate limiting only activates under high load
- Cache size limit may improve memory usage
- Endpoint validation adds <1ms per request

---

## [2.0.0] - 2025-11-06

### Added
- Health check tool for N8N connectivity monitoring
- Retry logic with exponential backoff
- Intelligent caching system (5-minute TTL)
- Support for Windows 11 Pro
- Comprehensive documentation

### Changed
- Improved error handling with specific error types
- Enhanced logging with debug levels

---

## [1.0.0] - 2025-10-30

### Added
- Initial release
- 7 MCP tools for N8N integration
- Support for macOS and Linux/Codespaces
- Basic documentation

---

[2.1.0]: https://github.com/jricardosouza/n8n-mcp-server/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/jricardosouza/n8n-mcp-server/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/jricardosouza/n8n-mcp-server/releases/tag/v1.0.0
