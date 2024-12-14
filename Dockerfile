# Utiliser une image de base
FROM python:3.10-slim

# Définir le répertoire de travail
# WORKDIR /app

# Copier les fichiers dans l'image
COPY . /app

# Installer les dépendances
# RUN pip install -r requirements.txt

# Exposer le port de l'application
EXPOSE 5000

# Commande pour démarrer l'application
CMD ["python", "app.py"]
