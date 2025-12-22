"""
Terraform manager for CTF Manager
Handles Terraform operations: init, plan, apply, destroy, output
"""

import os
import subprocess
import time
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple
from .challenge import Challenge, ChallengeStatus
from .credential_manager import CredentialManager
from .logger import get_logger, TerraformLogFilter


class TerraformManager:
    """Manages Terraform operations for CTF challenges"""
    
    def __init__(self, credential_manager: CredentialManager):
        self.credential_manager = credential_manager
        self.logger = get_logger()
        self.tf_logger = TerraformLogFilter(self.logger)
        
    def _run_terraform_command(self, command: List[str], working_dir: Path, 
                              env_vars: Dict[str, str] = None, 
                              timeout: int = 600) -> Tuple[bool, str, str]:
        """
        Execute a Terraform command
        
        Args:
            command: Terraform command as list of strings
            working_dir: Working directory for command execution
            env_vars: Additional environment variables
            timeout: Command timeout in seconds
            
        Returns:
            Tuple of (success, stdout, stderr)
        """
        # Setup environment
        env = os.environ.copy()
        if env_vars:
            env.update(env_vars)
        
        # Log command execution
        cmd_str = ' '.join(command)
        self.tf_logger.log_command(cmd_str, str(working_dir))
        
        start_time = time.time()
        
        try:
            # For interactive commands, don't capture stdin
            if ('apply' in command or 'destroy' in command) and '-auto-approve' not in command:
                # Interactive mode - let user see and respond to prompts
                result = subprocess.run(
                    command,
                    cwd=working_dir,
                    env=env,
                    text=True,
                    timeout=timeout
                )
                # Since we don't capture output in interactive mode, return basic info
                success = result.returncode == 0
                return success, "", ""
            else:
                # Non-interactive mode - capture output
                result = subprocess.run(
                    command,
                    cwd=working_dir,
                    env=env,
                    capture_output=True,
                    text=True,
                    timeout=timeout
                )
            
            duration = time.time() - start_time
            success = result.returncode == 0
            
            # Log output
            if result.stdout:
                self.tf_logger.log_terraform_output(result.stdout)
            if result.stderr:
                self.tf_logger.log_terraform_output(result.stderr)
            
            # Log result
            self.tf_logger.log_result(cmd_str, success, duration)
            
            return success, result.stdout, result.stderr
            
        except subprocess.TimeoutExpired:
            duration = time.time() - start_time
            self.logger.error(f"Terraform command timed out after {timeout}s: {cmd_str}")
            self.tf_logger.log_result(cmd_str, False, duration)
            return False, "", f"Command timed out after {timeout}s"
            
        except Exception as e:
            duration = time.time() - start_time
            self.logger.error(f"Error executing terraform command: {e}")
            self.tf_logger.log_result(cmd_str, False, duration)
            return False, "", str(e)
    
    def init(self, challenge: Challenge, force_reconfigure: bool = False) -> bool:
        """
        Initialize Terraform for a challenge
        
        Args:
            challenge: Challenge instance
            force_reconfigure: Force backend reconfiguration
            
        Returns:
            True if successful, False otherwise
        """
        if not challenge.full_directory_path or not challenge.full_backend_config_path:
            self.logger.error(f"Invalid paths for challenge {challenge.name}")
            return False
        
        # Setup environment variables
        env_vars = self.credential_manager.setup_environment_variables(
            challenge.provider, challenge.variables
        )
        
        # Build command
        command = ['terraform', 'init', f'-backend-config={challenge.full_backend_config_path}']
        
        if force_reconfigure:
            command.append('-reconfigure')
        
        success, stdout, stderr = self._run_terraform_command(
            command, challenge.full_directory_path, env_vars
        )
        
        if success:
            self.logger.info(f"Terraform init successful for {challenge.name}")
        else:
            self.logger.error(f"Terraform init failed for {challenge.name}")
            self.logger.error(f"Error: {stderr}")
        
        return success
    
    def plan(self, challenge: Challenge, var_file: bool = True) -> Tuple[bool, str]:
        """
        Run Terraform plan for a challenge
        
        Args:
            challenge: Challenge instance
            var_file: Whether to use terraform.tfvars file
            
        Returns:
            Tuple of (success, plan_output)
        """
        if not challenge.full_directory_path:
            self.logger.error(f"Invalid directory path for challenge {challenge.name}")
            return False, ""
        
        # Create variables file if requested
        if var_file:
            try:
                challenge.create_terraform_variables_file()
            except Exception as e:
                self.logger.warning(f"Could not create variables file: {e}")
        
        # Setup environment variables
        env_vars = self.credential_manager.setup_environment_variables(
            challenge.provider, challenge.variables
        )
        
        # Build command
        command = ['terraform', 'plan']
        if var_file:
            tfvars_file = challenge.full_directory_path / "terraform.tfvars"
            if tfvars_file.exists():
                command.extend(['-var-file', str(tfvars_file)])
        
        success, stdout, stderr = self._run_terraform_command(
            command, challenge.full_directory_path, env_vars
        )
        
        if success:
            self.logger.info(f"Terraform plan successful for {challenge.name}")
        else:
            self.logger.error(f"Terraform plan failed for {challenge.name}")
            self.logger.error(f"Error: {stderr}")
        
        return success, stdout
    
    def apply(self, challenge: Challenge, auto_approve: bool = False, 
             var_file: bool = True) -> bool:
        """
        Apply Terraform configuration for a challenge
        
        Args:
            challenge: Challenge instance
            auto_approve: Skip confirmation prompt
            var_file: Whether to use terraform.tfvars file
            
        Returns:
            True if successful, False otherwise
        """
        if not challenge.full_directory_path:
            self.logger.error(f"Invalid directory path for challenge {challenge.name}")
            return False
        
        # Create variables file if requested
        if var_file:
            try:
                challenge.create_terraform_variables_file()
            except Exception as e:
                self.logger.warning(f"Could not create variables file: {e}")
        
        # Setup environment variables
        env_vars = self.credential_manager.setup_environment_variables(
            challenge.provider, challenge.variables
        )
        
        # Build command
        command = ['terraform', 'apply']
        if auto_approve:
            command.append('-auto-approve')
        if var_file:
            tfvars_file = challenge.full_directory_path / "terraform.tfvars"
            if tfvars_file.exists():
                command.extend(['-var-file', str(tfvars_file)])
        
        success, stdout, stderr = self._run_terraform_command(
            command, challenge.full_directory_path, env_vars, 
            timeout=2400 if challenge.name == 'challenge-04-aws-only' else 1200  # 40 min for Windows DC, 20 min for others
        )
        
        if success:
            self.logger.info(f"Terraform apply successful for {challenge.name}")
        else:
            self.logger.error(f"Terraform apply failed for {challenge.name}")
            self.logger.error(f"Error: {stderr}")
        
        return success
    
    def destroy(self, challenge: Challenge, auto_approve: bool = False,
               var_file: bool = True) -> bool:
        """
        Destroy Terraform resources for a challenge
        
        Args:
            challenge: Challenge instance
            auto_approve: Skip confirmation prompt
            var_file: Whether to use terraform.tfvars file
            
        Returns:
            True if successful, False otherwise
        """
        if not challenge.full_directory_path:
            self.logger.error(f"Invalid directory path for challenge {challenge.name}")
            return False
        
        # Setup environment variables
        env_vars = self.credential_manager.setup_environment_variables(
            challenge.provider, challenge.variables
        )
        
        # Build command
        command = ['terraform', 'destroy']
        if auto_approve:
            command.append('-auto-approve')
        if var_file:
            tfvars_file = challenge.full_directory_path / "terraform.tfvars"
            if tfvars_file.exists():
                command.extend(['-var-file', str(tfvars_file)])
        
        success, stdout, stderr = self._run_terraform_command(
            command, challenge.full_directory_path, env_vars, 
            timeout=2400 if challenge.name == 'challenge-04-aws-only' else 1200  # 40 min for Windows DC, 20 min for others
        )
        
        if success:
            self.logger.info(f"Terraform destroy successful for {challenge.name}")
        else:
            self.logger.error(f"Terraform destroy failed for {challenge.name}")
            self.logger.error(f"Error: {stderr}")
        
        return success
    
    def get_outputs(self, challenge: Challenge, output_format: str = 'json') -> Tuple[bool, Dict[str, Any]]:
        """
        Get Terraform outputs for a challenge
        
        Args:
            challenge: Challenge instance
            output_format: Output format (json, raw)
            
        Returns:
            Tuple of (success, outputs_dict)
        """
        if not challenge.full_directory_path:
            self.logger.error(f"Invalid directory path for challenge {challenge.name}")
            return False, {}
        
        # Setup environment variables
        env_vars = self.credential_manager.setup_environment_variables(
            challenge.provider, challenge.variables
        )
        
        # Build command
        command = ['terraform', 'output']
        if output_format == 'json':
            command.append('-json')
        
        success, stdout, stderr = self._run_terraform_command(
            command, challenge.full_directory_path, env_vars
        )
        
        if not success:
            self.logger.error(f"Failed to get outputs for {challenge.name}: {stderr}")
            return False, {}
        
        if output_format == 'json' and stdout:
            try:
                import json
                outputs = json.loads(stdout)
                # Terraform outputs have 'value' field, extract just the values
                return True, {k: v.get('value', v) for k, v in outputs.items()}
            except json.JSONDecodeError as e:
                self.logger.error(f"Failed to parse JSON outputs: {e}")
                return False, {}
        
        return True, {'raw_output': stdout}
    
    def get_state_info(self, challenge: Challenge) -> Dict[str, Any]:
        """
        Get Terraform state information using CLI commands
        
        Args:
            challenge: Challenge instance
            
        Returns:
            State information dictionary
        """
        if not challenge.full_directory_path:
            return {'error': 'Invalid directory path'}
        
        # Check if terraform is initialized
        terraform_dir = challenge.full_directory_path / '.terraform'
        if not terraform_dir.exists():
            return {
                'state_exists': False,
                'terraform_initialized': False,
                'resources': [],
                'resource_count': 0
            }
        
        try:
            # Get resource list using terraform state list
            result = subprocess.run(
                ['terraform', 'state', 'list'],
                cwd=challenge.full_directory_path,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                resource_lines = [line.strip() for line in result.stdout.split('\n') if line.strip()]
                
                return {
                    'state_exists': True,
                    'terraform_initialized': True,
                    'resources': [{'name': resource} for resource in resource_lines],
                    'resource_count': len(resource_lines),
                    'resource_list': resource_lines
                }
            else:
                # No state or error
                return {
                    'state_exists': False,
                    'terraform_initialized': True,
                    'resources': [],
                    'resource_count': 0,
                    'error': result.stderr.strip() if result.stderr else 'No resources found'
                }
                
        except Exception as e:
            self.logger.error(f"Error getting state info: {e}")
            return {
                'state_exists': False,
                'terraform_initialized': True,
                'error': str(e)
            }
    
    def validate_challenge_deployment(self, challenge: Challenge) -> Dict[str, Any]:
        """
        Validate that a challenge is properly deployed
        
        Args:
            challenge: Challenge instance
            
        Returns:
            Validation results dictionary
        """
        results = {
            'challenge': challenge.name,
            'provider': challenge.provider,
            'terraform_initialized': False,
            'state_exists': False,
            'resources_deployed': False,
            'outputs_available': False,
            'validation_errors': []
        }
        
        # Check if Terraform is initialized
        if challenge.full_directory_path:
            terraform_dir = challenge.full_directory_path / '.terraform'
            results['terraform_initialized'] = terraform_dir.exists()
        
        # Check state
        state_info = self.get_state_info(challenge)
        results['state_exists'] = state_info.get('state_exists', False)
        results['resources_deployed'] = state_info.get('resource_count', 0) > 0
        
        # Check outputs
        outputs_success, outputs = self.get_outputs(challenge)
        results['outputs_available'] = outputs_success and bool(outputs)
        
        # Collect validation errors
        if not results['terraform_initialized']:
            results['validation_errors'].append("Terraform not initialized")
        
        if not results['state_exists']:
            results['validation_errors'].append("No Terraform state found")
        
        if not results['resources_deployed']:
            results['validation_errors'].append("No resources deployed")
        
        return results
    
    def cleanup_terraform_files(self, challenge: Challenge, 
                               cleanup_state: bool = False) -> bool:
        """
        Clean up Terraform working files
        
        Args:
            challenge: Challenge instance
            cleanup_state: Whether to also remove state files (dangerous!)
            
        Returns:
            True if successful, False otherwise
        """
        if not challenge.full_directory_path:
            return False
        
        try:
            # Remove .terraform directory
            terraform_dir = challenge.full_directory_path / '.terraform'
            if terraform_dir.exists():
                import shutil
                shutil.rmtree(terraform_dir)
                self.logger.info(f"Removed .terraform directory for {challenge.name}")
            
            # Remove lock file
            lock_file = challenge.full_directory_path / '.terraform.lock.hcl'
            if lock_file.exists():
                lock_file.unlink()
                self.logger.info(f"Removed .terraform.lock.hcl for {challenge.name}")
            
            # Remove generated tfvars
            tfvars_file = challenge.full_directory_path / "terraform.tfvars"
            if tfvars_file.exists():
                tfvars_file.unlink()
                self.logger.info(f"Removed terraform.tfvars for {challenge.name}")
            
            # Remove state files if requested (dangerous!)
            if cleanup_state:
                state_file = challenge.full_directory_path / "terraform.tfstate"
                backup_file = challenge.full_directory_path / "terraform.tfstate.backup"
                
                if state_file.exists():
                    state_file.unlink()
                    self.logger.warning(f"Removed terraform.tfstate for {challenge.name}")
                
                if backup_file.exists():
                    backup_file.unlink()
                    self.logger.warning(f"Removed terraform.tfstate.backup for {challenge.name}")
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error cleaning up Terraform files: {e}")
            return False
