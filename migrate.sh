#!/bin/bash

# WordPress Migration Helper Script
# This script demonstrates the migration process described in MIGRATION.md

set -e

echo "=== WordPress Migration Helper ==="
echo "This script helps you migrate an existing WordPress site to this Docker setup."
echo "Please read MIGRATION.md for complete instructions."
echo ""

# Check if required files exist
if [ ! -f "docker-compose.yml" ]; then
    echo "Error: docker-compose.yml not found. Please run this script from the project root."
    exit 1
fi

if [ ! -f ".env" ]; then
    echo "Creating .env file from example..."
    cp env.example .env
    echo "Please edit .env file to configure your database settings."
fi

echo "Step 1: Creating required directories..."
mkdir -p wp-data wp-app

echo "Step 2: Checking for existing WordPress files..."
if [ -d "wp-app" ] && [ "$(ls -A wp-app)" ]; then
    echo "WordPress files already exist in wp-app/"
else
    echo "Place your existing WordPress files in the wp-app/ directory"
    echo "Place your database dump in the wp-data/ directory"
fi

echo ""
echo "Step 3: Database migration checklist:"
echo "  □ Export your existing database to a .sql file"
echo "  □ Copy the .sql file to wp-data/ directory"
echo "  □ Remove any CREATE DATABASE or USE statements from the SQL file"
echo ""
echo "Step 4: File migration checklist:"
echo "  □ Copy all WordPress files to wp-app/ directory"
echo "  □ Backup your existing wp-config.php (it will be regenerated)"
echo "  □ Ensure proper file permissions"
echo ""
echo "Step 5: Start migration:"
echo "  Run: docker compose up -d"
echo ""
echo "Step 6: Post-migration tasks:"
echo "  □ Update site URLs if they changed"
echo "  □ Test your site functionality"
echo "  □ Update permalinks: docker compose run --rm wpcli rewrite flush"
echo ""

# Offer to start the containers
read -p "Do you want to start the containers now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting containers..."
    docker compose up -d
    echo ""
    echo "Containers started! Your site should be available at:"
    echo "WordPress: http://$(grep IP .env | cut -d '=' -f2):$(grep PORT .env | cut -d '=' -f2)"
    echo "phpMyAdmin: http://$(grep IP .env | cut -d '=' -f2):8080"
    echo ""
    echo "For detailed migration instructions, see MIGRATION.md"
else
    echo "You can start the containers later with: docker compose up -d"
fi

echo ""
echo "=== Migration Helper Complete ==="
echo "For troubleshooting and detailed instructions, see MIGRATION.md"