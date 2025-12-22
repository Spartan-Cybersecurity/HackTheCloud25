"""
Configuration loader for CTF Manager
Handles loading and parsing of challenges.yaml and credentials.yaml
"""

import os
import yaml
from pathlib import Path
from typing import Dict, List, Any, Optional
from .logger import get_logger


class ConfigLoader:
    """Loads and manages configuration files for CTF challenges"""
    
    def __init__(self, config_dir: str = "config"):
        self.config_dir = Path(config_dir)
        self.logger = get_logger()
        self.challenges_config = None
        self.credentials_config = None
    
    def load_challenges_config(self, config_file: str = "challenges.yaml") -> Dict[str, Any]:
        """
        Load challenges configuration
        
        Args:
            config_file: Configuration file name
            
        Returns:
            Parsed challenges configuration
        """
        config_path = self.config_dir / config_file
        
        if not config_path.exists():
            raise FileNotFoundError(f"Challenges config file not found: {config_path}")
        
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                self.challenges_config = yaml.safe_load(f)
            
            self.logger.info(f"Loaded challenges config from {config_path}")
            return self.challenges_config
            
        except yaml.YAMLError as e:
            self.logger.error(f"Error parsing YAML config: {e}")
            raise
        except Exception as e:
            self.logger.error(f"Error loading config file: {e}")
            raise
    
    def load_credentials_config(self, config_file: str = "credentials.yaml") -> Dict[str, Any]:
        """
        Load credentials configuration
        
        Args:
            config_file: Credentials file name
            
        Returns:
            Parsed credentials configuration
        """
        config_path = self.config_dir / config_file
        
        if not config_path.exists():
            self.logger.warning(f"Credentials file not found: {config_path}")
            self.logger.info("Using environment variables and defaults")
            return {}
        
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                self.credentials_config = yaml.safe_load(f)
            
            self.logger.info(f"Loaded credentials config from {config_path}")
            return self.credentials_config
            
        except yaml.YAMLError as e:
            self.logger.error(f"Error parsing credentials YAML: {e}")
            raise
        except Exception as e:
            self.logger.error(f"Error loading credentials file: {e}")
            raise
    
    def get_challenge_config(self, challenge_name: str) -> Optional[Dict[str, Any]]:
        """
        Get configuration for a specific challenge
        
        Args:
            challenge_name: Name of the challenge
            
        Returns:
            Challenge configuration or None if not found
        """
        if not self.challenges_config:
            self.load_challenges_config()
        
        challenges = self.challenges_config.get('challenges', {})
        return challenges.get(challenge_name)
    
    def get_all_challenges(self) -> Dict[str, Dict[str, Any]]:
        """
        Get all challenge configurations
        
        Returns:
            Dictionary of all challenge configurations
        """
        if not self.challenges_config:
            self.load_challenges_config()
        
        return self.challenges_config.get('challenges', {})
    
    def get_challenges_by_provider(self, provider: str) -> Dict[str, Dict[str, Any]]:
        """
        Get challenges filtered by cloud provider
        
        Args:
            provider: Cloud provider (aws, azure, gcp)
            
        Returns:
            Dictionary of challenges for the specified provider
        """
        all_challenges = self.get_all_challenges()
        return {
            name: config for name, config in all_challenges.items()
            if config.get('provider') == provider
        }
    
    def get_challenges_by_difficulty(self, difficulty: str) -> Dict[str, Dict[str, Any]]:
        """
        Get challenges filtered by difficulty level
        
        Args:
            difficulty: Difficulty level (basic, intermediate, advanced)
            
        Returns:
            Dictionary of challenges for the specified difficulty
        """
        all_challenges = self.get_all_challenges()
        return {
            name: config for name, config in all_challenges.items()
            if config.get('difficulty') == difficulty
        }
    
    def get_global_config(self) -> Dict[str, Any]:
        """
        Get global configuration settings
        
        Returns:
            Global configuration dictionary
        """
        if not self.challenges_config:
            self.load_challenges_config()
        
        return self.challenges_config.get('global', {})
    
    def get_provider_config(self, provider: str) -> Dict[str, Any]:
        """
        Get provider-specific configuration
        
        Args:
            provider: Cloud provider name
            
        Returns:
            Provider configuration dictionary
        """
        if not self.challenges_config:
            self.load_challenges_config()
        
        providers = self.challenges_config.get('providers', {})
        return providers.get(provider, {})
    
    def validate_challenge_config(self, challenge_name: str) -> List[str]:
        """
        Validate challenge configuration
        
        Args:
            challenge_name: Name of the challenge to validate
            
        Returns:
            List of validation errors (empty if valid)
        """
        errors = []
        config = self.get_challenge_config(challenge_name)
        
        if not config:
            errors.append(f"Challenge '{challenge_name}' not found in configuration")
            return errors
        
        # Required fields
        required_fields = ['name', 'provider', 'directory', 'backend_config']
        for field in required_fields:
            if not config.get(field):
                errors.append(f"Missing required field '{field}' for challenge '{challenge_name}'")
        
        # Validate provider
        valid_providers = ['aws', 'azure', 'gcp']
        provider = config.get('provider')
        if provider and provider not in valid_providers:
            errors.append(f"Invalid provider '{provider}'. Must be one of: {valid_providers}")
        
        # Check if directories exist
        if config.get('directory'):
            challenge_dir = Path(config['directory'])
            if not challenge_dir.exists():
                errors.append(f"Challenge directory not found: {challenge_dir}")
        
        if config.get('backend_config'):
            backend_path = Path(config['backend_config'])
            if not backend_path.exists():
                errors.append(f"Backend config file not found: {backend_path}")
        
        return errors
    
    def substitute_variables(self, config: Dict[str, Any]) -> Dict[str, Any]:
        """
        Substitute environment variables in configuration values
        
        Args:
            config: Configuration dictionary
            
        Returns:
            Configuration with environment variables substituted
        """
        def substitute_value(value):
            if isinstance(value, str) and value.startswith('${') and value.endswith('}'):
                env_var = value[2:-1]
                return os.getenv(env_var, value)
            elif isinstance(value, dict):
                return {k: substitute_value(v) for k, v in value.items()}
            elif isinstance(value, list):
                return [substitute_value(item) for item in value]
            return value
        
        return substitute_value(config)
