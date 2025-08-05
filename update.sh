source venv/bin/activate

git pull

python3 manage.py collectstatic --noinput

sudo systemctl restart portfolio
