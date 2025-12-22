#!/usr/bin/env python3
"""
HackTheCloud25 CTF Manager

Main CLI script for managing Terraform-based cloud security challenges
across AWS, Azure, and GCP platforms.
"""

import sys
import argparse
import json
from pathlib import Path
from typing import List, Optional

# Add lib directory to Python path
sys.path.insert(0, str(Path(__file__).parent / "lib"))

from lib import (
    TerraformManager,
    ConfigLoader, 
    CredentialManager,
    Challenge,
    get_logger
)
from lib.logger import setup_logger
from lib.challenge import ChallengeStatus


class CTFManager:
    """Main CTF Manager class that orchestrates all operations"""
    
    def __init__(self):
        self.base_path = Path(__file__).parent
        self.logger = setup_logger("ctf-manager", "INFO")
        
        # Initialize components
        self.config_loader = ConfigLoader(self.base_path / "config")
        self.credential_manager = CredentialManager(self.config_loader)
        self.terraform_manager = TerraformManager(self.credential_manager)
        
        # Load configuration
        try:
            self.config_loader.load_challenges_config()
            self.logger.info("CTF Manager initialized successfully")
        except Exception as e:
            self.logger.error(f"Failed to initialize CTF Manager: {e}")
            sys.exit(1)
    
    def get_challenge(self, challenge_name: str) -> Optional[Challenge]:
        """Get a challenge by name"""
        config = self.config_loader.get_challenge_config(challenge_name)
        if not config:
            return None
        
        return Challenge(challenge_name, config, self.base_path)
    
    def get_all_challenges(self) -> List[Challenge]:
        """Get all configured challenges"""
        all_configs = self.config_loader.get_all_challenges()
        return [
            Challenge(name, config, self.base_path) 
            for name, config in all_configs.items()
        ]
    
    def get_challenges_by_provider(self, provider: str) -> List[Challenge]:
        """Get challenges filtered by provider"""
        provider_configs = self.config_loader.get_challenges_by_provider(provider)
        return [
            Challenge(name, config, self.base_path)
            for name, config in provider_configs.items()
        ]
    
    def list_challenges(self, provider: Optional[str] = None, 
                       difficulty: Optional[str] = None, 
                       show_details: bool = False) -> None:
        """List all challenges with optional filtering"""
        challenges = self.get_all_challenges()
        
        # Apply filters
        if provider:
            challenges = [c for c in challenges if c.provider == provider]
        
        if difficulty:
            challenges = [c for c in challenges if c.difficulty == difficulty]
        
        if not challenges:
            print("No challenges found matching the criteria")
            return
        
        # Display challenges
        print(f"\n{'='*80}")
        print(f" HackTheCloud25 - Available Challenges ({len(challenges)} found)")
        print(f"{'='*80}")
        
        for challenge in challenges:
            status = challenge.get_status_from_terraform_state()
            status_color = self._get_status_color(status)
            
            print(f"\n📋 {challenge.name}")
            print(f"   Provider: {challenge.provider.upper()}")
            print(f"   Difficulty: {challenge.difficulty.capitalize()}")
            print(f"   Status: {status_color}{status.value.upper()}\033[0m")
            print(f"   Description: {challenge.description}")
            
            if show_details:
                print(f"   Directory: {challenge.directory}")
                print(f"   Backend Config: {challenge.backend_config}")
                print(f"   Tags: {', '.join(challenge.tags)}")
                
                # Show validation
                is_valid, errors = challenge.validate()
                if not is_valid:
                    print(f"   ⚠️  Validation Errors: {', '.join(errors)}")
        
        print(f"\n{'='*80}")
    
    def deploy_challenge(self, challenge_name: str, auto_approve: bool = False) -> bool:
        """Deploy a specific challenge"""
        challenge = self.get_challenge(challenge_name)
        if not challenge:
            self.logger.error(f"Challenge not found: {challenge_name}")
            return False
        
        # Validate challenge
        is_valid, errors = challenge.validate()
        if not is_valid:
            self.logger.error(f"Challenge validation failed: {', '.join(errors)}")
            return False
        
        # Validate environment
        env_validation = self.credential_manager.validate_environment(challenge.provider)
        if not env_validation['environment_ready']:
            self.logger.error(f"Environment not ready for {challenge.provider}")
            if not env_validation['terraform_installed']:
                self.logger.error("Terraform is not installed")
            if env_validation['missing_credentials']:
                self.logger.error(f"Missing credentials: {', '.join(env_validation['missing_credentials'])}")
            return False
        
        print(f"\n🚀 Deploying challenge: {challenge.name}")
        print(f"   Provider: {challenge.provider.upper()}")
        print(f"   Directory: {challenge.directory}")
        
        # Initialize Terraform
        print("\n📦 Initializing Terraform...")
        if not self.terraform_manager.init(challenge):
            self.logger.error("Terraform initialization failed")
            return False
        
        # Handle preparation scripts
        if not self._handle_preparation_scripts(challenge):
            self.logger.error("Preparation script execution failed")
            return False
        
        # Apply configuration
        print("\n🔨 Applying Terraform configuration...")
        if not self.terraform_manager.apply(challenge, auto_approve=auto_approve):
            self.logger.error("Terraform apply failed")
            return False
        
        # Get outputs
        print("\n📄 Getting deployment outputs...")
        success, outputs = self.terraform_manager.get_outputs(challenge)
        if success and outputs:
            print("\n✅ Deployment successful! Outputs:")
            self._display_outputs(outputs)
        
        print(f"\n🎉 Challenge '{challenge.name}' deployed successfully!")
        return True
    
    def deploy_provider_challenges(self, provider: str, auto_approve: bool = False) -> bool:
        """Deploy all challenges for a specific provider"""
        challenges = self.get_challenges_by_provider(provider)
        
        if not challenges:
            self.logger.error(f"No challenges found for provider: {provider}")
            return False
        
        print(f"\n🚀 Deploying all {provider.upper()} challenges ({len(challenges)} found)")
        
        success_count = 0
        for challenge in challenges:
            print(f"\n{'='*60}")
            if self.deploy_challenge(challenge.name, auto_approve):
                success_count += 1
            else:
                self.logger.error(f"Failed to deploy {challenge.name}")
        
        print(f"\n{'='*60}")
        print(f"✅ Deployed {success_count}/{len(challenges)} challenges successfully")
        return success_count == len(challenges)
    
    def destroy_challenge(self, challenge_name: str, auto_approve: bool = False) -> bool:
        """Destroy a specific challenge"""
        challenge = self.get_challenge(challenge_name)
        if not challenge:
            self.logger.error(f"Challenge not found: {challenge_name}")
            return False
        
        status = challenge.get_status_from_terraform_state()
        if status == ChallengeStatus.NOT_DEPLOYED:
            print(f"Challenge '{challenge.name}' is not deployed")
            return True
        
        print(f"\n💥 Destroying challenge: {challenge.name}")
        print(f"   Provider: {challenge.provider.upper()}")
        
        # Destroy resources
        if not self.terraform_manager.destroy(challenge, auto_approve=auto_approve):
            self.logger.error("Terraform destroy failed")
            return False
        
        print(f"\n🗑️  Challenge '{challenge.name}' destroyed successfully!")
        return True
    
    def destroy_all_challenges(self, auto_approve: bool = False) -> bool:
        """Destroy all deployed challenges"""
        challenges = self.get_all_challenges()
        deployed_challenges = [
            c for c in challenges 
            if c.get_status_from_terraform_state() == ChallengeStatus.DEPLOYED
        ]
        
        if not deployed_challenges:
            print("No deployed challenges found")
            return True
        
        print(f"\n💥 Destroying all challenges ({len(deployed_challenges)} deployed)")
        
        if not auto_approve:
            response = input("\n⚠️  This will destroy ALL deployed challenges. Continue? (yes/no): ")
            if response.lower() != 'yes':
                print("Operation cancelled")
                return False
        
        success_count = 0
        for challenge in deployed_challenges:
            print(f"\n{'='*60}")
            if self.destroy_challenge(challenge.name, auto_approve=True):
                success_count += 1
            else:
                self.logger.error(f"Failed to destroy {challenge.name}")
        
        print(f"\n{'='*60}")
        print(f"🗑️  Destroyed {success_count}/{len(deployed_challenges)} challenges")
        return success_count == len(deployed_challenges)
    
    def show_status(self, challenge_name: Optional[str] = None) -> None:
        """Show status of challenges"""
        if challenge_name:
            challenges = [self.get_challenge(challenge_name)]
            if not challenges[0]:
                self.logger.error(f"Challenge not found: {challenge_name}")
                return
        else:
            challenges = self.get_all_challenges()
        
        print(f"\n{'='*80}")
        print(f" HackTheCloud25 - Challenge Status")
        print(f"{'='*80}")
        
        status_counts = {}
        
        for challenge in challenges:
            status = challenge.get_status_from_terraform_state()
            status_color = self._get_status_color(status)
            
            print(f"\n📋 {challenge.name}")
            print(f"   Provider: {challenge.provider.upper()}")
            print(f"   Status: {status_color}{status.value.upper()}\033[0m")
            
            # Get validation info
            validation = self.terraform_manager.validate_challenge_deployment(challenge)
            
            if status == ChallengeStatus.DEPLOYED:
                print(f"   Resources: {validation.get('resource_count', 0)}")
                print(f"   Outputs Available: {'✅' if validation.get('outputs_available') else '❌'}")
            
            # Count statuses
            status_counts[status.value] = status_counts.get(status.value, 0) + 1
        
        # Summary
        print(f"\n{'='*80}")
        print("📊 Summary:")
        for status, count in status_counts.items():
            print(f"   {status.upper()}: {count}")
        print(f"{'='*80}")
    
    def get_outputs(self, challenge_name: str, output_format: str = "table") -> None:
        """Get outputs from a deployed challenge"""
        challenge = self.get_challenge(challenge_name)
        if not challenge:
            self.logger.error(f"Challenge not found: {challenge_name}")
            return
        
        status = challenge.get_status_from_terraform_state()
        if status != ChallengeStatus.DEPLOYED:
            self.logger.error(f"Challenge '{challenge_name}' is not deployed")
            return
        
        success, outputs = self.terraform_manager.get_outputs(challenge)
        
        if not success:
            self.logger.error("Failed to get outputs")
            return
        
        if not outputs:
            print(f"No outputs available for challenge '{challenge_name}'")
            return
        
        print(f"\n📄 Outputs for challenge: {challenge.name}")
        print(f"{'='*60}")
        
        if output_format == "json":
            print(json.dumps(outputs, indent=2))
        else:
            self._display_outputs(outputs)
    
    def _display_outputs(self, outputs: dict) -> None:
        """Display outputs in a formatted table"""
        for key, value in outputs.items():
            if isinstance(value, dict):
                print(f"\n🔑 {key}:")
                for sub_key, sub_value in value.items():
                    print(f"   {sub_key}: {sub_value}")
            else:
                print(f"🔑 {key}: {value}")
    
    def _get_status_color(self, status) -> str:
        """Get color code for challenge status"""
        # Avoid import issues by using string values directly
        if hasattr(status, 'value'):
            status_value = status.value
        else:
            status_value = str(status)
            
        colors = {
            "deployed": "\033[32m",  # Green
            "not_deployed": "\033[31m",  # Red
            "unknown": "\033[33m"  # Yellow
        }
        return colors.get(status_value, "\033[37m")
    
    def _detect_preparation_scripts(self, challenge) -> list:
        """Detect preparation scripts in challenge directory"""
        if not challenge.full_directory_path:
            return []
            
        common_prep_scripts = [
            "install_dependencies.sh",
            "setup.sh", 
            "prepare.sh",
            "build.sh"
        ]
        
        detected_scripts = []
        for script in common_prep_scripts:
            script_path = challenge.full_directory_path / script
            if script_path.exists() and script_path.is_file():
                detected_scripts.append(script)
        
        return detected_scripts
    
    def _execute_preparation_script(self, challenge, script_name: str) -> bool:
        """Execute preparation script in challenge directory"""
        try:
            import subprocess
            import os
            
            script_path = challenge.full_directory_path / script_name
            
            # Make script executable
            os.chmod(script_path, 0o755)
            
            # Execute script
            self.logger.info(f"Executing preparation script: {script_name}")
            result = subprocess.run(
                ["bash", str(script_path)],
                cwd=challenge.full_directory_path,
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )
            
            if result.returncode == 0:
                self.logger.info(f"Preparation script {script_name} executed successfully")
                if result.stdout:
                    print(result.stdout)
                return True
            else:
                self.logger.error(f"Preparation script {script_name} failed with return code {result.returncode}")
                if result.stderr:
                    self.logger.error(f"Error output: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            self.logger.error(f"Preparation script {script_name} timed out after 5 minutes")
            return False
        except Exception as e:
            self.logger.error(f"Error executing preparation script {script_name}: {e}")
            return False
    
    def _confirm_preparation_script(self, script_name: str) -> bool:
        """Ask user for confirmation to execute preparation script"""
        print(f"\n⚠️  **PREPARATION REQUIRED**")
        print(f"   Detected preparation script: {script_name}")
        
        # Provide context based on script name
        if script_name == "install_dependencies.sh":
            print(f"   This script creates Lambda deployment packages required for this challenge.")
            print(f"   ")
            print(f"   📦 Script will:")
            print(f"   - Install Python dependencies for Lambda functions")
            print(f"   - Create deployment packages (*.zip files)")
            print(f"   - Prepare challenge dependencies")
        else:
            print(f"   This script prepares necessary dependencies for the challenge.")
        
        print(f"   ")
        response = input(f"❓ Execute preparation script before deployment? [Y/n]: ").strip().lower()
        
        return response in ['', 'y', 'yes']
    
    def _handle_preparation_scripts(self, challenge) -> bool:
        """Handle detection and execution of preparation scripts"""
        detected_scripts = self._detect_preparation_scripts(challenge)
        
        if not detected_scripts:
            return True  # No preparation needed
        
        for script in detected_scripts:
            if self._confirm_preparation_script(script):
                print(f"\n🔧 Executing preparation script: {script}")
                if not self._execute_preparation_script(challenge, script):
                    self.logger.error(f"Preparation script {script} failed")
                    return False
                print(f"✅ Preparation script {script} completed successfully")
            else:
                print(f"\n⏭️  Skipping preparation script: {script}")
                print(f"   ⚠️  Warning: This may cause deployment failures if dependencies are missing")
        
        return True

    def show_credits(self) -> None:
        """Show credits information about Cloud Security Space and sponsors"""
        print(f"\n{'='*80}")
        print(f" 🏆 HackTheCloud25 - Credits & Acknowledgments")
        print(f"{'='*80}")
        
        # Cloud Security Space Info
        print(f"\n🌐 **Cloud Security Space - EkoParty 2025**")
        print(f"   📅 October 22-24, 2025")
        print(f"   📍 CEC - Buenos Aires, Argentina")
        print(f"   🎯 Explore, Learn and Master Cloud Security")
        print(f"")
        print(f"   A comprehensive cybersecurity experience focused on cloud environments where")
        print(f"   professionals and enthusiasts immerse themselves in real attack and defense")
        print(f"   scenarios across AWS, Azure and GCP. The Cloud Security Village at EkoParty")
        print(f"   2025 offers hands-on labs, specialized conferences and a comprehensive CTF")
        print(f"   challenge focused on cloud security.")
        print(f"")
        print(f"   🔗 https://cloudsecurityspace.org/")
        
        # MediCloudX Info
        print(f"\n🏥 **MediCloudX - The Fictional Company**")
        print(f"   An innovative digital health platform that migrated its critical")
        print(f"   infrastructure to the cloud to provide cutting-edge medical services.")
        print(f"   As the protagonist of HackTheCloud25, MediCloudX represents the real")
        print(f"   security challenges faced by modern organizations:")
        print(f"")
        print(f"   • 🔐 Identity and access management")
        print(f"   • 💾 Protection of sensitive patient data")
        print(f"   • 🌉 Multi-cloud hybrid architectures") 
        print(f"   • 📊 Compliance with healthcare regulations")
        print(f"   • 🚨 Real-time incident response")
        print(f"")
        print(f"   Through MediCloudX challenges, participants experience real attack")
        print(f"   vectors and learn to strengthen security posture in critical cloud")
        print(f"   environments.")
        
        # Hack The Cloud CTF Info
        print(f"\n🚩 **Hack The Cloud CTF 2025**")
        print(f"   A cloud cybersecurity challenge at EkoParty 2025")
        print(f"   • 👥 Teams of 3 members")
        print(f"   • ☁️  15 challenges distributed across AWS, Azure and GCP (5 per provider)")
        print(f"   • 🏅 Prizes and scholarships for participating teams")
        print(f"   • 🎖️  Electronic badges and recognition")
        print(f"")
        print(f"   🔗 https://ctf.ekocloudsec.com/")
        
        # Sponsors
        print(f"\n💼 **Sponsors - Cloud Security Village**")
        print(f"")
        
        # Village Core Sponsor
        print(f"   🌟 **Village Core Sponsor**")
        print(f"   • InterBank (Peru)")
        print(f"")
        
        # Village Guardian
        print(f"   🛡️  **Village Guardian**")
        print(f"   • Orca Security (USA)")
        print(f"")
        
        # Village Partners
        print(f"   🤝 **Village Partners**")
        sponsors_partner = [
            ("OZ Digital Consulting", "USA"),
            ("Semilla Cyber", "Puerto Rico"), 
            ("Offensive Security", "USA"),
            ("Altered Security", "India"),
            ("Spartan-Cybersecurity", "Colombia"),
            ("Electronic Cats", "Mexico"),
            ("CyberWarFare Labs", "India"),
            ("GISAC", "Colombia"),
            ("UqBar", "Colombia")
        ]
        for name, country in sponsors_partner:
            print(f"   • {name} ({country})")
        print(f"")
        
        # Village Builders  
        print(f"   🏗️  **Village Builders**")
        sponsors_builder = [
            ("PlainText", "Dominican Republic"),
            ("RedTeamRD", "Dominican Republic"),
            ("AWS Security Latam", "Mexico")
        ]
        for name, country in sponsors_builder:
            print(f"   • {name} ({country})")
        print(f"")
        
        # Village Allies
        print(f"   🤝 **Village Allies**") 
        sponsors_ally = [
            ("ASC IT GROUP", "Colombia"),
            ("NicaSecurity", "Nicaragua"),
            ("nuvem", "Peru")
        ]
        for name, country in sponsors_ally:
            print(f"   • {name} ({country})")
        
        print(f"\n{'='*80}")
        print(f" 🙏 **Acknowledgments**")
        print(f"{'='*80}")
        print(f"   Thanks to all sponsors, organizers and participants who made")
        print(f"   possible this unique learning and professional growth experience")
        print(f"   in cloud cybersecurity.")
        print(f"")
        print(f"   Framework developed by EkoCloudSec Community")
        print(f"   🔗 https://github.com/Spartan-Cybersecurity/HackTheCloud25")
        print(f"")
        print(f"   See you in the next edition! 🚀")
        print(f"\n{'='*80}")


def create_parser() -> argparse.ArgumentParser:
    """Create argument parser for CLI"""
    parser = argparse.ArgumentParser(
        prog='ctf-manager',
        description='HackTheCloud25 CTF Manager - Manage Terraform-based cloud security challenges',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s list                              # List all challenges
  %(prog)s list --provider aws               # List AWS challenges only
  %(prog)s deploy challenge-01-aws-only      # Deploy specific challenge
  %(prog)s deploy --provider azure          # Deploy all Azure challenges
  %(prog)s destroy challenge-01-aws-only    # Destroy specific challenge
  %(prog)s destroy --all                    # Destroy all challenges
  %(prog)s status                           # Show status of all challenges
  %(prog)s output challenge-01-aws-only     # Get outputs from challenge
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List available challenges')
    list_parser.add_argument('--provider', choices=['aws', 'azure', 'gcp'], 
                           help='Filter by cloud provider')
    list_parser.add_argument('--difficulty', choices=['basic', 'intermediate', 'advanced'],
                           help='Filter by difficulty level')
    list_parser.add_argument('--details', action='store_true',
                           help='Show detailed information')
    
    # Deploy command
    deploy_parser = subparsers.add_parser('deploy', help='Deploy challenges')
    deploy_group = deploy_parser.add_mutually_exclusive_group(required=True)
    deploy_group.add_argument('challenge_name', nargs='?', help='Challenge name to deploy')
    deploy_group.add_argument('--provider', choices=['aws', 'azure', 'gcp'],
                            help='Deploy all challenges for provider')
    deploy_parser.add_argument('--auto-approve', action='store_true',
                             help='Skip confirmation prompts')
    
    # Destroy command
    destroy_parser = subparsers.add_parser('destroy', help='Destroy challenges')
    destroy_group = destroy_parser.add_mutually_exclusive_group(required=True)
    destroy_group.add_argument('challenge_name', nargs='?', help='Challenge name to destroy')
    destroy_group.add_argument('--all', action='store_true',
                             help='Destroy all deployed challenges')
    destroy_parser.add_argument('--auto-approve', action='store_true',
                               help='Skip confirmation prompts')
    
    # Status command
    status_parser = subparsers.add_parser('status', help='Show challenge status')
    status_parser.add_argument('challenge_name', nargs='?', 
                             help='Show status for specific challenge')
    
    # Output command
    output_parser = subparsers.add_parser('output', help='Get challenge outputs')
    output_parser.add_argument('challenge_name', help='Challenge name')
    output_parser.add_argument('--format', choices=['table', 'json'], default='table',
                             help='Output format')
    
    # Credits command
    credits_parser = subparsers.add_parser('credits', help='Show credits and acknowledgments')
    
    return parser


def main():
    """Main entry point"""
    parser = create_parser()
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    try:
        ctf_manager = CTFManager()
        
        if args.command == 'list':
            ctf_manager.list_challenges(
                provider=args.provider,
                difficulty=args.difficulty,
                show_details=args.details
            )
        
        elif args.command == 'deploy':
            if args.provider:
                success = ctf_manager.deploy_provider_challenges(
                    args.provider, 
                    auto_approve=args.auto_approve
                )
            else:
                success = ctf_manager.deploy_challenge(
                    args.challenge_name,
                    auto_approve=args.auto_approve
                )
            return 0 if success else 1
        
        elif args.command == 'destroy':
            if args.all:
                success = ctf_manager.destroy_all_challenges(
                    auto_approve=args.auto_approve
                )
            else:
                success = ctf_manager.destroy_challenge(
                    args.challenge_name,
                    auto_approve=args.auto_approve
                )
            return 0 if success else 1
        
        elif args.command == 'status':
            ctf_manager.show_status(args.challenge_name)
        
        elif args.command == 'output':
            ctf_manager.get_outputs(args.challenge_name, args.format)
        
        elif args.command == 'credits':
            ctf_manager.show_credits()
        
        return 0
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Operation cancelled by user")
        return 1
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return 1


if __name__ == '__main__':
    sys.exit(main())
