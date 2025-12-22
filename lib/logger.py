"""
Logging configuration for CTF Manager
"""

import logging
import os
from datetime import datetime
from pathlib import Path


def setup_logger(name: str = "ctf-manager", log_level: str = "INFO", log_dir: str = "logs") -> logging.Logger:
    """
    Set up logger with file and console handlers
    
    Args:
        name: Logger name
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR)
        log_dir: Directory for log files
        
    Returns:
        Configured logger instance
    """
    # Create logs directory if it doesn't exist
    log_path = Path(log_dir)
    log_path.mkdir(exist_ok=True)
    
    # Create logger
    logger = logging.getLogger(name)
    logger.setLevel(getattr(logging, log_level.upper()))
    
    # Clear existing handlers
    logger.handlers.clear()
    
    # Create formatters
    file_formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s'
    )
    console_formatter = logging.Formatter(
        '%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%H:%M:%S'
    )
    
    # File handler
    log_file = log_path / f"{name}.log"
    file_handler = logging.FileHandler(log_file, encoding='utf-8')
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(file_formatter)
    logger.addHandler(file_handler)
    
    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(getattr(logging, log_level.upper()))
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)
    
    return logger


def get_logger(name: str = "ctf-manager") -> logging.Logger:
    """
    Get existing logger or create new one with default settings
    
    Args:
        name: Logger name
        
    Returns:
        Logger instance
    """
    return logging.getLogger(name)


class TerraformLogFilter:
    """Filter and capture Terraform output for structured logging"""
    
    def __init__(self, logger: logging.Logger):
        self.logger = logger
        self.terraform_patterns = [
            ("Apply complete!", logging.INFO),
            ("Destroy complete!", logging.INFO),
            ("Error:", logging.ERROR),
            ("Warning:", logging.WARNING),
            ("Plan:", logging.INFO),
            ("Refreshing state...", logging.DEBUG)
        ]
    
    def log_terraform_output(self, output: str):
        """Parse and log Terraform output with appropriate log levels"""
        lines = output.split('\n')
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
                
            # Determine log level based on content
            log_level = logging.INFO
            for pattern, level in self.terraform_patterns:
                if pattern.lower() in line.lower():
                    log_level = level
                    break
            
            # Log with appropriate level
            self.logger.log(log_level, f"[TERRAFORM] {line}")
    
    def log_command(self, command: str, working_dir: str):
        """Log executed Terraform commands"""
        self.logger.info(f"[TERRAFORM] Executing: {command}")
        self.logger.debug(f"[TERRAFORM] Working directory: {working_dir}")
    
    def log_result(self, command: str, success: bool, duration: float):
        """Log command execution results"""
        status = "SUCCESS" if success else "FAILED"
        self.logger.info(f"[TERRAFORM] Command '{command}' {status} in {duration:.2f}s")
