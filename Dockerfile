FROM python:3.7.3

WORKDIR /app

COPY . /app

RUN pip3 --no-cache-dir install -r requirements.txt                                                                            
