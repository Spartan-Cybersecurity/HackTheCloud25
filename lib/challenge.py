"""
Challenge class for managing individual CTF challenges
"""

import os
from pathlib import Path
from typing import Dict, Any, List, Optional
from enum import Enum
from .logger import get_logger


class ChallengeStatus(Enum):
    """Challenge deployment status"""
    NOT_DEPLOYED = "not_deployed"
    DEPLOYING = "deploying"
    DEPLOYED = "deployed"
    DESTROYING = "destroying"
    FAILED = "failed"
    UNKNOWN = "unknown"


class Challenge:
    """Represents a single CTF challenge with its configuration and state"""
    
    def __init__(self, name: str, config: Dict[str, Any], base_path: Path = None):
        self.name = name
        self.config = config
        self.base_path = base_path or Path.cwd()
        self.logger = get_logger()
        
        # Extract key properties from config
        self.provider = config.get('provider')
        self.difficulty = config.get('difficulty')
        self.description = config.get('description', '')
        self.directory = config.get('directory')
        self.backend_config = config.get('backend_config')
        self.web_content = config.get('web_content')
        self.variables = config.get('variables', {})
        self.outputs = config.get('outputs', [])
        self.tags = config.get('tags', [])
        
        # Computed properties
        self.full_directory_path = self.base_path / self.directory if self.directory else None
        self.full_backend_config_path = self.base_path / self.backend_config if self.backend_config else None
        self.full_web_content_path = self.base_path / self.web_content if self.web_content else None
    
    def validate(self) -> tuple[bool, List[str]]:
        """
        Validate challenge configuration and file paths
        
        Returns:
            Tuple of (is_valid, list_of_errors)
        """
        errors = []
        
        # Required fields
        if not self.name:
            errors.append("Challenge name is required")
        
        if not self.provider:
            errors.append("Provider is required")
        elif self.provider not in ['aws', 'azure', 'gcp']:
            errors.append(f"Invalid provider: {self.provider}")
        
        if not self.directory:
            errors.append("Directory is required")
        elif self.full_directory_path and not self.full_directory_path.exists():
            errors.append(f"Challenge directory not found: {self.full_directory_path}")
        
        if not self.backend_config:
            errors.append("Backend config is required")
        elif self.full_backend_config_path and not self.full_backend_config_path.exists():
            errors.append(f"Backend config file not found: {self.full_backend_config_path}")
        
        # Check for main.tf file
        if self.full_directory_path:
            main_tf = self.full_directory_path / "main.tf"
            if not main_tf.exists():
                errors.append(f"main.tf not found in challenge directory: {main_tf}")
        
        # Check web content if specified
        if self.web_content and self.full_web_content_path and not self.full_web_content_path.exists():
            errors.append(f"Web content directory not found: {self.full_web_content_path}")
        
        return len(errors) == 0, errors
    
    def get_terraform_files(self) -> List[Path]:
        """
        Get list of Terraform files in challenge directory
        
        Returns:
            List of Terraform file paths
        """
        if not self.full_directory_path or not self.full_directory_path.exists():
            return []
        
        tf_files = []
        for pattern in ['*.tf', '*.tfvars', '*.tf.json']:
            tf_files.extend(self.full_directory_path.glob(pattern))
        
        return sorted(tf_files)
    
    def get_web_content_files(self) -> List[Path]:
        """
        Get list of web content files
        
        Returns:
            List of web content file paths
        """
        if not self.full_web_content_path or not self.full_web_content_path.exists():
            return []
        
        web_files = []
        for pattern in ['*']:
            web_files.extend(self.full_web_content_path.glob(pattern))
        
        return [f for f in web_files if f.is_file()]
    
    def get_status_from_terraform_state(self) -> ChallengeStatus:
        """
        Determine challenge status using Terraform CLI commands
        
        Returns:
            Current challenge status
        """
        if not self.full_directory_path:
            return ChallengeStatus.UNKNOWN
        
        # Check if Terraform is initialized
        terraform_dir = self.full_directory_path / '.terraform'
        if not terraform_dir.exists():
            return ChallengeStatus.NOT_DEPLOYED
        
        try:
            import subprocess
            
            # Use 'terraform state list' to check for resources
            result = subprocess.run(
                ['terraform', 'state', 'list'],
                cwd=self.full_directory_path,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                # If we have output, there are resources in state
                if result.stdout.strip():
                    return ChallengeStatus.DEPLOYED
                else:
                    return ChallengeStatus.NOT_DEPLOYED
            else:
                # Check if it's because no state file exists
                if "No state file was found" in result.stderr or "Failed to load state" in result.stderr:
                    return ChallengeStatus.NOT_DEPLOYED
                else:
                    self.logger.warning(f"Terraform state list failed: {result.stderr}")
                    return ChallengeStatus.UNKNOWN
                    
        except subprocess.TimeoutExpired:
            self.logger.warning("Terraform state list command timed out")
            return ChallengeStatus.UNKNOWN
        except FileNotFoundError:
            self.logger.warning("Terraform command not found")
            return ChallengeStatus.UNKNOWN
        except Exception as e:
            self.logger.warning(f"Error checking Terraform state: {e}")
            return ChallengeStatus.UNKNOWN
    
    def get_terraform_variables_file_content(self) -> str:
        """
        Generate terraform.tfvars content for this challenge
        Resolves environment variable references in format ${VAR_NAME}
        
        Returns:
            Terraform variables file content
        """
        lines = [
            "# Auto-generated variables file for CTF Manager",
            f"# Challenge: {self.name}",
            f"# Provider: {self.provider}",
            ""
        ]
        
        # Get credentials for this provider to resolve variables
        try:
            from .credential_manager import CredentialManager
            from .config_loader import ConfigLoader
            config_loader = ConfigLoader(self.base_path / "config")
            cred_manager = CredentialManager(config_loader)
            provider_creds = cred_manager.get_provider_credentials(self.provider)
        except Exception as e:
            self.logger.warning(f"Could not get credentials for variable resolution: {e}")
            provider_creds = {}
        
        for key, value in self.variables.items():
            resolved_value = self._resolve_variable_value(value, provider_creds)
            
            if isinstance(resolved_value, str):
                lines.append(f'{key} = "{resolved_value}"')
            elif isinstance(resolved_value, bool):
                lines.append(f'{key} = {str(resolved_value).lower()}')
            elif isinstance(resolved_value, (int, float)):
                lines.append(f'{key} = {resolved_value}')
            else:
                lines.append(f'{key} = "{str(resolved_value)}"')
        
        return '\n'.join(lines) + '\n'
    
    def _resolve_variable_value(self, value: Any, provider_creds: Dict[str, Any]) -> Any:
        """
        Resolve variable value, handling environment variables and challenge dependencies
        
        Args:
            value: Original value from config
            provider_creds: Provider credentials dictionary
            
        Returns:
            Resolved value
        """
        if not isinstance(value, str):
            return value
        
        # Check if value is in format ${VAR_NAME}
        if value.startswith('${') and value.endswith('}'):
            var_name = value[2:-1]  # Remove ${ and }
            
            # Check if this is a challenge dependency (pattern: challenge-name.output-name)
            if '.' in var_name:
                return self._resolve_challenge_dependency(var_name)
            
            # Map common variable names to credential keys
            var_mapping = {
                'AZURE_SUBSCRIPTION_ID': 'subscription_id',
                'AZURE_TENANT_ID': 'tenant_id', 
                'AZURE_CLIENT_ID': 'client_id',
                'AZURE_CLIENT_SECRET': 'client_secret',
                'AWS_ACCESS_KEY_ID': 'access_key_id',
                'AWS_SECRET_ACCESS_KEY': 'secret_access_key',
                'GCP_PROJECT_ID': 'project_id',
                'GCP_REGION': 'region',
                'GCP_USER_EMAIL': 'user_email'
            }
            
            # Try to get from provider credentials first
            if var_name in var_mapping:
                cred_key = var_mapping[var_name]
                if cred_key in provider_creds:
                    resolved = provider_creds[cred_key]
                    self.logger.info(f"Resolved {var_name} from provider credentials")
                    return resolved
            
            # Fall back to environment variable
            import os
            resolved = os.getenv(var_name)
            if resolved:
                self.logger.info(f"Resolved {var_name} from environment variable")
                return resolved
            
            # If still not found, log warning but return original
            self.logger.warning(f"Could not resolve variable {var_name}, using original value")
            return value
        
        return value

    def _resolve_challenge_dependency(self, dependency: str) -> str:
        """
        Resolve a challenge dependency in format 'challenge-name.output-name'
        
        Args:
            dependency: Dependency string like 'challenge-01-azure-only.azure_ad_app_display_name'
            
        Returns:
            Resolved output value or original dependency if resolution fails
        """
        try:
            parts = dependency.split('.', 1)
            if len(parts) != 2:
                self.logger.warning(f"Invalid dependency format: {dependency}")
                return f"${{{dependency}}}"
            
            challenge_name, output_name = parts
            
            # Import here to avoid circular imports
            from .terraform_manager import TerraformManager
            from .credential_manager import CredentialManager
            from .config_loader import ConfigLoader
            
            # Initialize managers
            config_loader = ConfigLoader(self.base_path / "config")
            credential_manager = CredentialManager(config_loader)
            terraform_manager = TerraformManager(credential_manager)
            
            # Get the dependency challenge
            dependency_config = config_loader.get_challenge_config(challenge_name)
            if not dependency_config:
                self.logger.error(f"Dependency challenge not found: {challenge_name}")
                return f"${{{dependency}}}"
            
            dependency_challenge = Challenge(challenge_name, dependency_config, self.base_path)
            
            # Check if dependency is deployed
            if dependency_challenge.get_status_from_terraform_state() != ChallengeStatus.DEPLOYED:
                self.logger.error(f"Dependency challenge {challenge_name} is not deployed")
                return f"${{{dependency}}}"
            
            # Get outputs from dependency challenge
            success, outputs = terraform_manager.get_outputs(dependency_challenge)
            if not success or output_name not in outputs:
                self.logger.error(f"Could not get output {output_name} from {challenge_name}")
                return f"${{{dependency}}}"
            
            resolved_value = outputs[output_name]
            self.logger.info(f"✅ Resolved dependency {dependency} = '{resolved_value}'")
            return str(resolved_value)
            
        except Exception as e:
            self.logger.error(f"Error resolving challenge dependency {dependency}: {e}")
            return f"${{{dependency}}}"
    
    def create_terraform_variables_file(self) -> Path:
        """
        Create terraform.tfvars file in challenge directory
        
        Returns:
            Path to created variables file
        """
        if not self.full_directory_path:
            raise ValueError("Challenge directory not set")
        
        tfvars_path = self.full_directory_path / "terraform.tfvars"
        
        content = self.get_terraform_variables_file_content()
        
        with open(tfvars_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        self.logger.debug(f"Created terraform.tfvars for {self.name}: {tfvars_path}")
        return tfvars_path
    
    def get_summary(self) -> Dict[str, Any]:
        """
        Get challenge summary information
        
        Returns:
            Challenge summary dictionary
        """
        is_valid, errors = self.validate()
        
        return {
            'name': self.name,
            'provider': self.provider,
            'difficulty': self.difficulty,
            'description': self.description,
            'status': self.get_status_from_terraform_state().value,
            'directory': str(self.directory),
            'backend_config': str(self.backend_config),
            'web_content': str(self.web_content) if self.web_content else None,
            'tags': self.tags,
            'variables': self.variables,
            'outputs': self.outputs,
            'valid': is_valid,
            'errors': errors,
            'terraform_files': [str(f.name) for f in self.get_terraform_files()],
            'web_content_files': [str(f.name) for f in self.get_web_content_files()]
        }
    
    def __str__(self) -> str:
        """String representation of challenge"""
        status = self.get_status_from_terraform_state().value
        return f"Challenge(name='{self.name}', provider='{self.provider}', status='{status}')"
    
    def __repr__(self) -> str:
        """Detailed string representation"""
        return (f"Challenge(name='{self.name}', provider='{self.provider}', "
                f"difficulty='{self.difficulty}', directory='{self.directory}')")
