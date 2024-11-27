# Use the official Python 3.9 image based on Alpine 3.13 as the base image
# Alpine is a minimal Docker image, which reduces the image size.
FROM python:3.9-alpine3.13

# Label the image with the maintainer's information
LABEL maintainer="leslienarh.com"

# Set the environment variable PYTHONUNBUFFERED to 1 to ensure Python output is not buffered
# This is useful for real-time logs when the container is running
ENV PYTHONUNBUFFERED 1

# Copy the requirements.txt file into the container's /tmp directory
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
# Copy the application files from the host machine into the container’s /app directory
COPY ./app /app

# Set the working directory to /app where the application files are copied
WORKDIR /app

# Expose port 8000 to allow the application to communicate with the outside world
EXPOSE 8000

# Create a Python virtual environment in the /py directory
# Upgrade pip to the latest version and install the dependencies from requirements.txt
# Remove the temporary requirements file after installation
# Add a non-root user called 'django-user' for better security practices
ARG DEV=false
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    apk del .tmp-build-deps && \
    adduser \
        --disabled-password \
        --no-create-home \
        django-user

# Modify the PATH environment variable to include the virtual environment's bin directory
# This ensures that the installed Python packages are used by default
ENV PATH="/py/bin:$PATH"

# Switch to the non-root user 'django-user' to run the application with lower privileges
USER django-user
