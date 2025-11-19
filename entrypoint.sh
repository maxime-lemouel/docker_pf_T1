#!/bin/sh

set -e

echo "Démarrage du service PHP..."

# Attendre que MySQL soit prêt

until nc -z -v -w30 mysql 3306
do
  echo "Attente de MySQL..."
  sleep 2
done
echo "MySQL prêt"

# Installation des dépendances Composer
echo "Installation des dépendances Composer"
composer update --no-interaction --no-dev --prefer-dist
composer install --no-interaction --no-dev --prefer-dist --optimize-autoloader

# Installation des dépendances npm et build
echo "Installation des dépendances npm"
npm install --silent

echo "Build des assets"
npm run build

# Configuration Laravel (premier démarrage uniquement)
if [ ! -f .env ]; then
    echo "Configuration Laravel"
    cp .env.example .env

    # Configuration de la base de données
    sed -i "s/DB_HOST=.*/DB_HOST=${DB_HOST}/" .env
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" .env
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" .env
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" .env
    sed -i "s/MAIL_MAILER=.*/MAIL_MAILER=${MAIL_MAILER}/" .env
    sed -i "s/MAIL_HOST=.*/MAIL_HOST=${MAIL_HOST}/" .env
    sed -i "s/MAIL_PORT=.*/MAIL_PORT=${MAIL_PORT}/" .env
    sed -i "s/MAIL_USERNAME=.*/MAIL_USERNAME=${MAIL_USERNAME}/" .env
    sed -i "s/MAIL_PASSWORD=.*/MAIL_PASSWORD=${MAIL_PASSWORD}/" .env
    sed -i "s/MAIL_ENCRYPTION=.*/MAIL_ENCRYPTION=${MAIL_ENCRYPTION}/" .env


    echo "Génération de la clé d'application..."
    php artisan key:generate --force

if [ -n "$RUN_MIGRATIONS" ] && [ "$RUN_MIGRATIONS" = "true" ]; then
    echo "Migration de la base de données..."
    php artisan migrate:fresh --seed --force
fi

    echo "Configuration terminée!"
else
    echo "Laravel déjà configuré"
fi

# Optimisation Laravel pour la production
echo "Optimisation de Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Permissions
echo "Configuration des permissions..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

echo "Démarrage de PHP-FPM..."
exec php-fpm