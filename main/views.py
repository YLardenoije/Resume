from django.shortcuts import render
from django.http import HttpResponse, request

# Create your views here.

def index(response):
    return render(response, 'main/JS_CSS_PortfolioProject-master/index.html',{})