from django.shortcuts import render
from django.http import HttpResponse, request

# Create your views here.

def index(response):
    # Updated to use the new modular template structure
    return render(response, 'main/index.html',{})