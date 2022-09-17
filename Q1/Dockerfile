FROM python:alpine3.7
RUN apk add --no-cache py3-pip python3 && \
    pip3 install flask
COPY . /app
ENV FLASK_APP app.py
WORKDIR /app
CMD flask run --host=0.0.0.0 --port=8000