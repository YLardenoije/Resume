source venv/bin/activate

git pull
export $(cat .env | grep -v ^# | xargs)
python3 manage.py collectstatic --noinput

sudo systemctl restart portfolio
