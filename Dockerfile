FROM python:3.12-alpine

WORKDIR /opt/webapp

# Copy requirements first for better caching
COPY ./webapp/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY ./webapp .

# Run as non-root user
RUN adduser -D myuser
USER myuser

# Run the app
CMD gunicorn --bind 0.0.0.0:$PORT wsgi
