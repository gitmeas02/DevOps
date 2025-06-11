#!/bin/bash

# Laravel Dual Environment Deployment Script
# This script sets up and deploys both production and staging Laravel applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR=$(pwd)
ANSIBLE_DIR="${PROJECT_DIR}/ansible"
HTML_DIR="${PROJECT_DIR}/html"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create directory structure
create_directories() {
    log_info "Creating directory structure..."
    
    mkdir -p "${ANSIBLE_DIR}"
    mkdir -p "${HTML_DIR}/production"
    mkdir -p "${HTML_DIR}/staging"
    
    log_success "Directory structure created"
}

# Setup Ansible files
setup_ansible() {
    log_info "Setting up Ansible configuration..."
    
    # Create ansible.cfg
    cat > "${ANSIBLE_DIR}/ansible.cfg" << EOF
[defaults]
inventory = inventory
host_key_checking = False
timeout = 30
gathering = smart
fact_caching = memory

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
pipelining = True
EOF

    log_success "Ansible configuration created"
}

# Check if Laravel projects exist
check_laravel_projects() {
    log_info "Checking Laravel projects..."
    
    if [ ! -f "${HTML_DIR}/production/composer.json" ]; then
        log_warning "Production Laravel project not found in ${HTML_DIR}/production"
        log_info "Please ensure your Laravel production code is in the html/production directory"
    fi
    
    if [ ! -f "${HTML_DIR}/staging/composer.json" ]; then
        log_warning "Staging Laravel project not found in ${HTML_DIR}/staging"
        log_info "Please ensure your Laravel staging code is in the html/staging directory"
    fi
}

# Build and start containers
build_containers() {
    log_info "Building and starting Docker containers..."
    
    # Stop existing containers
    docker compose down 2>/dev/null || true
    
    # Build and start
    docker compose up -d --build
    
    log_success "Docker containers started"
}

# Wait for containers to be ready
wait_for_containers() {
    log_info "Waiting for containers to be ready..."
    
    # Wait for SSH to be available
    for i in {1..30}; do
        if docker exec control-machine-i4c ansible myservers -m ping 2>/dev/null; then
            log_success "Containers are ready"
            return 0
        fi
        sleep 2
    done
    
    log_error "Containers failed to start properly"
    exit 1
}

# Run Ansible deployment
run_deployment() {
    log_info "Running Ansible deployment..."
    
    # Copy deployment files to control machine
    docker cp "${ANSIBLE_DIR}/." control-machine-i4c:/ansible/
    
    # Run the deployment playbook
    docker exec -it control-machine-i4c ansible-playbook -i /ansible/inventory /ansible/playbook.yml -v
    
    log_success "Deployment completed"
}

# Display access information
show_access_info() {
    log_success "=== Deployment Complete ==="
    echo ""
    log_info "Access your applications:"
    echo "  Production:  http://localhost:8080 (or http://gici4c2025.com:8080)"
    echo "  Staging:     http://localhost:8080 (or http://gici4c2025.staging:8080)"
    echo ""
    log_info "SSH Access:"
    echo "  ssh root@localhost -p 2222"
    echo "  Password: P@ssw0rd1"
    echo ""
    log_info "Container Management:"
    echo "  View logs:     docker compose logs -f"
    echo "  Stop:          docker compose down"
    echo "  Restart:       docker compose restart"
    echo ""
    log_warning "Note: Add the following to your /etc/hosts file for domain access:"
    echo "  127.0.0.1 gici4c2025.com"
    echo "  127.0.0.1 gici4c2025.staging"
}

# Main execution
main() {
    log_info "Starting Laravel Dual Environment Deployment..."
    
    # Check if docker-compose is available
    if ! command -v docker compose &> /dev/null; then
        log_error "docker compose is not installed. Please install it first."
        exit 1
    fi
    
    create_directories
    setup_ansible
    check_laravel_projects
    build_containers
    wait_for_containers
    run_deployment
    show_access_info
}

# Run main function
main "$@"