FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
ENV PORT=5000

# Copier le code
ADD ./webapp /opt/webapp/
WORKDIR /opt/webapp

# Installer dépendances système
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl \
    && rm -rf /var/lib/apt/lists/*

# Installer dépendances Python
RUN pip install --no-cache-dir -r requirements.txt

# Créer un utilisateur non-root (Debian)
RUN useradd -m -s /bin/bash myuser
USER myuser

# CMD pour Heroku / docker run -e PORT=5000
CMD ["gunicorn", "--bind", "0.0.0.0:$PORT", "wsgi:app"]
