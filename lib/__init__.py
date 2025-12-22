"""
HackTheCloud25 CTF Manager Library

This library provides tools for managing Terraform-based cloud security challenges
across AWS, Azure, and GCP platforms.
"""

__version__ = "1.0.0"
__author__ = "EkoCloudSec"

from .terraform_manager import TerraformManager
from .config_loader import ConfigLoader
from .credential_manager import CredentialManager
from .challenge import Challenge
from .logger import get_logger

__all__ = [
    'TerraformManager',
    'ConfigLoader', 
    'CredentialManager',
    'Challenge',
    'get_logger'
]
