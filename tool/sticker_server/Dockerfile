FROM public.ecr.aws/docker/library/python:3.13-alpine
WORKDIR /app
COPY --chmod=0644 server.py /app/server.py
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz', timeout=3).read()"
CMD ["python", "/app/server.py"]
