# Release Notes

This page documents the release history and changes for the IBM Cloud Pacemaker Plugin.

## Version History

### Version 1.0.0 (2024-03-20)

#### Features
- Initial release of IBM Cloud Pacemaker Plugin
- Support for Custom Route VIP resource agent
- Support for Floating IP Failover resource agent
- Integration with IBM Cloud VPC API
- Support for API key authentication
- Support for Trusted Profile IAM authentication

#### Resource Agents
- `ibm-cloud-vpc-cr-vip`: Custom Route VIP resource agent
- `ibm-cloud-vpc-move-fip`: Floating IP Failover resource agent

#### Configuration
- Support for same-zone and cross-zone deployments
- Configurable resource stickiness
- Customizable operation timeouts
- Flexible resource constraints

#### Documentation
- Comprehensive installation guide
- Detailed configuration guide
- API reference documentation
- Troubleshooting guide

## Upcoming Releases

### Version 1.1.0 (Planned)

#### Planned Features
- Enhanced monitoring capabilities
- Additional resource agents
- Improved error handling
- Performance optimizations

#### Planned Improvements
- Better documentation
- More examples
- Enhanced testing
- Additional features

## Version Compatibility

### IBM Cloud VPC
- Compatible with current IBM Cloud VPC API
- Supports all VPC regions
- Works with VPE endpoints

### Pacemaker
- Compatible with Pacemaker 2.0.0 and later
- Works with Corosync 3.0.0 and later
- Supports standard Pacemaker features

### Operating Systems
- Ubuntu 20.04 LTS and later
- RHEL 8 and later
- CentOS 8 and later

## Migration Guide

### Upgrading from Previous Versions

1. **Backup Configuration**
   ```bash
   pcs cluster cib > cluster_backup.xml
   ```

2. **Update Software**
   ```bash
   make install
   ```

3. **Verify Configuration**
   ```bash
   pcs config
   pcs resource show
   ```

4. **Test Functionality**
   ```bash
   pcs resource cleanup <resource>
   pcs status
   ```

## Known Issues

### Version 1.0.0

1. **Resource Agent Issues**
   - None reported

2. **Configuration Issues**
   - None reported

3. **Performance Issues**
   - None reported

## Deprecated Features

### Version 1.0.0
- No deprecated features

## Breaking Changes

### Version 1.0.0
- No breaking changes

## Security Updates

### Version 1.0.0
- Initial security implementation
- API key authentication
- Trusted Profile IAM support
- Secure communication

## Bug Fixes

### Version 1.0.0
- Initial release, no bug fixes

## Documentation Updates

### Version 1.0.0
- Initial documentation release
- Installation guide
- Configuration guide
- API reference
- Troubleshooting guide

## Support

### Version Support
- Current version: 1.0.0
- Supported versions: 1.0.0 and later

### Support Resources
- GitHub Issues
- Documentation
- Community Support
- IBM Cloud Support

## Contributing

### How to Contribute
- Follow Contributing Guide
- Submit Pull Requests
- Report Issues
- Improve Documentation

### Development
- Use development branch
- Follow coding standards
- Write tests
- Update documentation 