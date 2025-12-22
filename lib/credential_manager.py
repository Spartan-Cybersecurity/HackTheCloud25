"""
Credential manager for CTF Manager
Handles cloud provider credentials and environment variables
"""

import os
from typing import Dict, Any, Optional
from pathlib import Path
from .config_loader import ConfigLoader
from .logger import get_logger


class CredentialManager:
    """Manages cloud provider credentials and environment setup"""
    
    def __init__(self, config_loader: ConfigLoader):
        self.config_loader = config_loader
        self.logger = get_logger()
        self.credentials = {}
        self._load_credentials()
    
    def _load_credentials(self):
        """Load credentials from configuration and environment"""
        try:
            self.credentials = self.config_loader.load_credentials_config()
            self.logger.debug("Credentials loaded from configuration file")
        except Exception as e:
            self.logger.warning(f"Could not load credentials file: {e}")
            self.credentials = {}
    
    def get_aws_credentials(self) -> Dict[str, Any]:
        """
        Get AWS credentials and configuration
        
        Returns:
            AWS credentials dictionary
        """
        aws_config = self.credentials.get('aws', {})
        
        # Merge with environment variables
        credentials = {
            'profile': aws_config.get('profile', os.getenv('AWS_PROFILE', 'default')),
            'region': aws_config.get('region', os.getenv('AWS_DEFAULT_REGION', 'us-east-1')),
            'access_key_id': os.getenv('AWS_ACCESS_KEY_ID'),
            'secret_access_key': os.getenv('AWS_SECRET_ACCESS_KEY'),
            'session_token': os.getenv('AWS_SESSION_TOKEN')
        }
        
        return {k: v for k, v in credentials.items() if v is not None}
    
    def get_azure_credentials(self) -> Dict[str, Any]:
        """
        Get Azure credentials and configuration
        Automatically detects Azure CLI credentials if environment variables aren't set
        
        Returns:
            Azure credentials dictionary
        """
        azure_config = self.credentials.get('azure', {})
        
        # Try to get from config/env first
        subscription_id = azure_config.get('subscription_id', os.getenv('AZURE_SUBSCRIPTION_ID'))
        tenant_id = azure_config.get('tenant_id', os.getenv('AZURE_TENANT_ID'))
        
        # If subscription_id or tenant_id not found, try Azure CLI
        if not subscription_id or not tenant_id:
            try:
                import subprocess
                import json
                
                result = subprocess.run(
                    ['az', 'account', 'show', '--output', 'json'],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                if result.returncode == 0:
                    account_info = json.loads(result.stdout)
                    if not subscription_id:
                        subscription_id = account_info.get('id')
                        self.logger.info("Detected Azure subscription ID from Azure CLI")
                    if not tenant_id:
                        tenant_id = account_info.get('tenantId')
                        self.logger.info("Detected Azure tenant ID from Azure CLI")
                else:
                    self.logger.warning("Azure CLI not authenticated or available")
                    
            except (subprocess.TimeoutExpired, FileNotFoundError, json.JSONDecodeError) as e:
                self.logger.warning(f"Could not get Azure CLI credentials: {e}")
            except Exception as e:
                self.logger.warning(f"Unexpected error getting Azure CLI credentials: {e}")
        
        credentials = {
            'subscription_id': subscription_id,
            'tenant_id': tenant_id,
            'client_id': azure_config.get('client_id', os.getenv('AZURE_CLIENT_ID')),
            'client_secret': azure_config.get('client_secret', os.getenv('AZURE_CLIENT_SECRET')),
            'location': azure_config.get('location', 'East US')
        }
        
        return {k: v for k, v in credentials.items() if v is not None}
    
    def get_gcp_credentials(self) -> Dict[str, Any]:
        """
        Get GCP credentials and configuration
        Automatically detects GCP project from gcloud CLI if environment variables aren't set
        
        Returns:
            GCP credentials dictionary
        """
        gcp_config = self.credentials.get('gcp', {})
        
        # Try to get from config/env first
        project_id = gcp_config.get('project_id', os.getenv('GCP_PROJECT_ID'))
        region = gcp_config.get('region', os.getenv('GCP_REGION', 'us-central1'))
        
        # Try to get user email from environment or gcloud CLI
        user_email = gcp_config.get('user_email', os.getenv('GCP_USER_EMAIL'))
        
        # If project_id or user_email not found, try gcloud CLI
        if not project_id or not user_email:
            try:
                import subprocess
                
                # Get project ID if not set
                if not project_id:
                    result = subprocess.run(
                        ['gcloud', 'config', 'get-value', 'project'],
                        capture_output=True,
                        text=True,
                        timeout=10
                    )
                    
                    if result.returncode == 0:
                        detected_project = result.stdout.strip()
                        if detected_project and detected_project != '(unset)':
                            project_id = detected_project
                            self.logger.info("Detected GCP project ID from gcloud CLI")
                
                # Get user email if not set
                if not user_email:
                    result = subprocess.run(
                        ['gcloud', 'config', 'get-value', 'account'],
                        capture_output=True,
                        text=True,
                        timeout=10
                    )
                    
                    if result.returncode == 0:
                        detected_email = result.stdout.strip()
                        if detected_email and detected_email != '(unset)':
                            user_email = detected_email
                            self.logger.info("Detected GCP user email from gcloud CLI")
                
                if not project_id and not user_email:
                    self.logger.warning("gcloud CLI not configured or authenticated")
                    
            except (subprocess.TimeoutExpired, FileNotFoundError) as e:
                self.logger.warning(f"Could not get GCP CLI credentials: {e}")
            except Exception as e:
                self.logger.warning(f"Unexpected error getting GCP CLI credentials: {e}")
        
        credentials = {
            'project_id': project_id,
            'region': region,
            'user_email': user_email,
            'credentials_file': gcp_config.get('credentials_file', os.getenv('GOOGLE_APPLICATION_CREDENTIALS'))
        }
        
        return {k: v for k, v in credentials.items() if v is not None}
    
    def get_provider_credentials(self, provider: str) -> Dict[str, Any]:
        """
        Get credentials for a specific cloud provider
        
        Args:
            provider: Cloud provider name (aws, azure, gcp)
            
        Returns:
            Provider credentials dictionary
        """
        if provider == 'aws':
            return self.get_aws_credentials()
        elif provider == 'azure':
            return self.get_azure_credentials()
        elif provider == 'gcp':
            return self.get_gcp_credentials()
        else:
            raise ValueError(f"Unsupported provider: {provider}")
    
    def validate_provider_credentials(self, provider: str) -> tuple[bool, list[str]]:
        """
        Validate that required credentials are available for a provider
        
        Args:
            provider: Cloud provider name
            
        Returns:
            Tuple of (is_valid, list_of_missing_credentials)
        """
        missing = []
        
        if provider == 'aws':
            creds = self.get_aws_credentials()
            # AWS can use profile OR access keys
            if not creds.get('profile') and not (creds.get('access_key_id') and creds.get('secret_access_key')):
                missing.append("AWS_PROFILE or (AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY)")
        
        elif provider == 'azure':
            creds = self.get_azure_credentials()
            required = ['subscription_id', 'tenant_id']
            for req in required:
                if not creds.get(req):
                    missing.append(f"AZURE_{req.upper()}")
        
        elif provider == 'gcp':
            creds = self.get_gcp_credentials()
            if not creds.get('project_id'):
                missing.append("GCP_PROJECT_ID")
        
        return len(missing) == 0, missing
    
    def setup_environment_variables(self, provider: str, challenge_variables: Dict[str, Any] = None) -> Dict[str, str]:
        """
        Setup environment variables for Terraform execution
        
        Args:
            provider: Cloud provider name
            challenge_variables: Additional variables from challenge config
            
        Returns:
            Dictionary of environment variables to set
        """
        env_vars = {}
        
        if provider == 'aws':
            aws_creds = self.get_aws_credentials()
            if aws_creds.get('profile'):
                env_vars['AWS_PROFILE'] = aws_creds['profile']
            if aws_creds.get('region'):
                env_vars['AWS_DEFAULT_REGION'] = aws_creds['region']
            if aws_creds.get('access_key_id'):
                env_vars['AWS_ACCESS_KEY_ID'] = aws_creds['access_key_id']
            if aws_creds.get('secret_access_key'):
                env_vars['AWS_SECRET_ACCESS_KEY'] = aws_creds['secret_access_key']
            if aws_creds.get('session_token'):
                env_vars['AWS_SESSION_TOKEN'] = aws_creds['session_token']
        
        elif provider == 'azure':
            azure_creds = self.get_azure_credentials()
            if azure_creds.get('subscription_id'):
                env_vars['AZURE_SUBSCRIPTION_ID'] = azure_creds['subscription_id']
            if azure_creds.get('tenant_id'):
                env_vars['AZURE_TENANT_ID'] = azure_creds['tenant_id']
            if azure_creds.get('client_id'):
                env_vars['AZURE_CLIENT_ID'] = azure_creds['client_id']
            if azure_creds.get('client_secret'):
                env_vars['AZURE_CLIENT_SECRET'] = azure_creds['client_secret']
        
        elif provider == 'gcp':
            gcp_creds = self.get_gcp_credentials()
            if gcp_creds.get('project_id'):
                env_vars['GCP_PROJECT_ID'] = gcp_creds['project_id']
            if gcp_creds.get('region'):
                env_vars['GCP_REGION'] = gcp_creds['region']
            if gcp_creds.get('user_email'):
                env_vars['GCP_USER_EMAIL'] = gcp_creds['user_email']
            if gcp_creds.get('credentials_file'):
                env_vars['GOOGLE_APPLICATION_CREDENTIALS'] = gcp_creds['credentials_file']
        
        # Add challenge-specific variables
        if challenge_variables:
            for key, value in challenge_variables.items():
                if isinstance(value, str) and value.startswith('${') and value.endswith('}'):
                    # Environment variable reference
                    env_var = value[2:-1]
                    if env_var in os.environ:
                        env_vars[f"TF_VAR_{key}"] = os.environ[env_var]
                else:
                    env_vars[f"TF_VAR_{key}"] = str(value)
        
        return env_vars
    
    def check_terraform_installation(self) -> tuple[bool, Optional[str]]:
        """
        Check if Terraform is installed and get version
        
        Returns:
            Tuple of (is_installed, version_string)
        """
        try:
            import subprocess
            result = subprocess.run(['terraform', 'version'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                version_line = result.stdout.split('\n')[0]
                return True, version_line
            else:
                return False, None
        except (subprocess.TimeoutExpired, FileNotFoundError, subprocess.SubprocessError):
            return False, None
    
    def validate_environment(self, provider: str) -> Dict[str, Any]:
        """
        Comprehensive environment validation
        
        Args:
            provider: Cloud provider to validate
            
        Returns:
            Validation results dictionary
        """
        results = {
            'provider': provider,
            'terraform_installed': False,
            'terraform_version': None,
            'credentials_valid': False,
            'missing_credentials': [],
            'environment_ready': False
        }
        
        # Check Terraform
        tf_installed, tf_version = self.check_terraform_installation()
        results['terraform_installed'] = tf_installed
        results['terraform_version'] = tf_version
        
        # Check credentials
        creds_valid, missing_creds = self.validate_provider_credentials(provider)
        results['credentials_valid'] = creds_valid
        results['missing_credentials'] = missing_creds
        
        # Overall readiness
        results['environment_ready'] = tf_installed and creds_valid
        
        return results
