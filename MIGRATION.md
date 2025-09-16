# WordPress Migration Guide

This guide will help you migrate your existing WordPress site to this Docker Compose setup.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Pre-Migration Checklist](#pre-migration-checklist)
- [Step-by-Step Migration Process](#step-by-step-migration-process)
- [Database Migration](#database-migration)
- [File Migration](#file-migration)
- [Configuration Updates](#configuration-updates)
- [URL and Domain Changes](#url-and-domain-changes)
- [Post-Migration Tasks](#post-migration-tasks)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before starting the migration, ensure you have:

- Docker and Docker Compose installed
- Access to your existing WordPress files
- Database backup or access to export your database
- Administrative access to your current WordPress installation

## Pre-Migration Checklist

1. **Backup your existing site completely**
   - Create a full database dump
   - Download all WordPress files, including wp-content
   - Note down your current site URL and WordPress settings

2. **Prepare your environment**
   ```bash
   # Clone this repository or copy the files to your project directory
   git clone https://github.com/kanghaov/wordpress-docker-compose.git
   cd wordpress-docker-compose
   
   # Copy environment configuration
   cp env.example .env
   ```

3. **Configure environment variables**
   Edit the `.env` file to match your requirements:
   ```bash
   IP=127.0.0.1
   PORT=80
   DB_ROOT_PASSWORD=your_secure_password
   DB_NAME=wordpress
   ```

## Step-by-Step Migration Process

### 1. Database Migration

#### Export your existing database
From your current WordPress installation:

```bash
# If using MySQL/MariaDB directly
mysqldump -u username -p database_name > backup.sql

# If using phpMyAdmin, export via the web interface
# If using WP-CLI
wp db export backup.sql
```

#### Prepare the database dump for Docker
1. Create the `wp-data` directory if it doesn't exist:
   ```bash
   mkdir -p wp-data
   ```

2. Copy your database dump to the `wp-data` directory:
   ```bash
   cp backup.sql wp-data/
   ```

3. **Important**: Clean the SQL dump to ensure compatibility:
   ```bash
   # Remove any CREATE DATABASE statements that might conflict
   sed -i '/CREATE DATABASE/d' wp-data/backup.sql
   sed -i '/USE `/d' wp-data/backup.sql
   ```

### 2. File Migration

#### Copy WordPress files
1. Create the WordPress application directory:
   ```bash
   mkdir -p wp-app
   ```

2. Copy your existing WordPress files:
   ```bash
   # Copy all files from your existing WordPress installation
   cp -r /path/to/your/existing/wordpress/* wp-app/
   
   # Ensure proper permissions
   sudo chown -R www-data:www-data wp-app/
   chmod -R 755 wp-app/
   chmod -R 644 wp-app/wp-content/
   ```

3. **Remove or backup the existing wp-config.php**:
   ```bash
   # Backup the existing wp-config.php for reference
   cp wp-app/wp-config.php wp-app/wp-config-backup.php
   
   # Remove it to let WordPress generate a new one with Docker environment variables
   rm wp-app/wp-config.php
   ```

### 3. Configuration Updates

#### Start the containers
```bash
docker compose up -d
```

#### Configure WordPress with WP-CLI
If you removed wp-config.php, WordPress will automatically create a new one with the Docker environment variables. However, you may need to run the installation:

```bash
# If this is a fresh setup, install WordPress
docker compose run --rm wpcli core install \
  --url=http://localhost \
  --title="Your Site Title" \
  --admin_user=admin \
  --admin_password=your_admin_password \
  --admin_email=your@email.com

# If you're importing an existing database, skip the installation
# and just verify the configuration
docker compose run --rm wpcli core is-installed
```

### 4. URL and Domain Changes

If your site URL is changing, you'll need to update the WordPress database:

```bash
# Update site URL in the database
docker compose run --rm wpcli option update home 'http://localhost'
docker compose run --rm wpcli option update siteurl 'http://localhost'

# If you have a custom domain, update accordingly
docker compose run --rm wpcli option update home 'http://your-domain.local'
docker compose run --rm wpcli option update siteurl 'http://your-domain.local'

# Search and replace URLs in content (if needed)
docker compose run --rm wpcli search-replace 'https://old-domain.com' 'http://localhost' --dry-run
# Remove --dry-run when you're ready to execute
docker compose run --rm wpcli search-replace 'https://old-domain.com' 'http://localhost'
```

### 5. Update wp-config.php (if needed)

If you need to customize wp-config.php, you can edit it directly or override specific settings:

```php
// Add to wp-app/wp-config.php if you need to override URLs
define('WP_HOME','http://localhost');
define('WP_SITEURL','http://localhost');

// For development, you might want to enable debug mode
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
```

## Post-Migration Tasks

### 1. Verify the migration
- Visit your site at `http://localhost` (or your configured IP/domain)
- Login to the admin area and verify all content is present
- Check that themes and plugins are working correctly
- Test functionality like forms, e-commerce, etc.

### 2. Update permalinks
```bash
# Flush permalink structure
docker compose run --rm wpcli rewrite flush
```

### 3. Update file permissions (if needed)
```bash
# Ensure WordPress can write to necessary directories
docker compose exec wp chown -R www-data:www-data /var/www/html/wp-content/uploads
docker compose exec wp chmod -R 755 /var/www/html/wp-content/uploads
```

### 4. Clear any caches
If your site uses caching plugins:
```bash
# Example for common caching plugins
docker compose run --rm wpcli cache flush
docker compose run --rm wpcli plugin is-active w3-total-cache && docker compose run --rm wpcli w3-total-cache flush all
```

## Troubleshooting

### Database Connection Issues
- Verify your `.env` file settings match the database configuration
- Ensure the database container is running: `docker compose ps`
- Check database logs: `docker compose logs db`

### File Permission Issues
```bash
# Fix WordPress file permissions
docker compose exec wp find /var/www/html -type d -exec chmod 755 {} \;
docker compose exec wp find /var/www/html -type f -exec chmod 644 {} \;
docker compose exec wp chmod 644 /var/www/html/wp-config.php
```

### Plugin/Theme Issues
- Deactivate all plugins and reactivate one by one to identify problematic ones
- Switch to a default theme temporarily if theme issues occur
- Check for plugin compatibility with your PHP version

### URL/Domain Issues
- Verify your site URL settings in WordPress admin or via WP-CLI
- Check your hosts file if using a custom local domain
- Ensure your `.env` configuration matches your intended setup

### Memory or Performance Issues
Edit `config/wp_php.ini` to increase PHP limits:
```ini
memory_limit = 256M
upload_max_filesize = 50M
post_max_size = 50M
max_execution_time = 300
```

### Import Large Databases
For large databases, you might need to:
1. Split the SQL file into smaller chunks
2. Increase MySQL settings in docker-compose.yml:
   ```yaml
   command: [
     '--character-set-server=utf8mb4',
     '--collation-server=utf8mb4_unicode_ci',
     '--max_allowed_packet=64M',
     '--innodb_buffer_pool_size=256M'
   ]
   ```

## Getting Help

If you encounter issues during migration:
1. Check the [main README](README.md) for basic usage
2. Review Docker and Docker Compose logs: `docker compose logs`
3. Verify your environment configuration
4. Search for similar issues in the repository's issue tracker

Remember to always test your migration in a development environment before applying to production!