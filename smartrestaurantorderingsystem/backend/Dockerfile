FROM python:3.11-slim

WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the simple backend
COPY main.py .

# Expose port
EXPOSE 8000

# Use shell form so $PORT env variable is expanded at runtime
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
