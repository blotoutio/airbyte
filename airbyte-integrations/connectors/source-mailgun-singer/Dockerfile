FROM python:3.7-slim

# Bash is installed for more convenient debugging.
RUN apt-get update \
    && apt-get install -y git \
    && apt-get install -y bash \
    && apt-get install -y gcc \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /airbyte/integration_code
COPY source_mailgun_singer ./source_mailgun_singer
COPY main.py ./
COPY setup.py ./
RUN pip install .

ENV AIRBYTE_ENTRYPOINT "python /airbyte/integration_code/main.py"
ENTRYPOINT ["python", "/airbyte/integration_code/main.py"]

LABEL io.airbyte.version=0.1.2
LABEL io.airbyte.name=blotout/source-mailgun-singer
