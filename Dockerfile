# Utiliser une image Python légère et compatible Heroku
FROM python:3.11-slim

# Variables d'environnement
# PYTHONUNBUFFERED=1 pour que les logs Python s'affichent en temps réel
# PORT=5000 pour Heroku
ENV PYTHONUNBUFFERED=1
ENV PORT=5000

# Installer bash et dépendances système nécessaires
# curl est utilisé si besoin pour télécharger des fichiers
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
 && rm -rf /var/lib/apt/lists/*   # Nettoyer le cache apt pour réduire la taille de l'image

# Copier le fichier requirements.txt et installer les dépendances Python
COPY ./webapp/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Copier le code de l'application dans le conteneur
COPY ./webapp /opt/webapp
WORKDIR /opt/webapp  # Définir le répertoire de travail

# Créer un utilisateur non-root pour exécuter l'application en sécurité
RUN useradd -m myuser
USER myuser

# Exposer le port 5000 pour que Heroku puisse accéder à l'application
EXPOSE 5000

# Lancer l'application avec gunicorn sur toutes les interfaces et le port défini
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "wsgi"]
