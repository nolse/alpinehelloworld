FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1

# Copier tout le code
ADD ./webapp /opt/webapp/
WORKDIR /opt/webapp

# Installer dépendances
RUN apt-get update && apt-get install -y --no-install-recommends bash curl \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir -r requirements.txt

# Non-root user
RUN adduser -D myuser
USER myuser

# Gunicorn démarrant sur $PORT dynamique Heroku
CMD ["gunicorn", "--bind", "0.0.0.0:$PORT", "wsgi:app"]
