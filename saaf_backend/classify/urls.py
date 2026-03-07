# classify/urls.py  — /api/
from django.urls import path
from . import views

urlpatterns = [
    path('classify/', views.classify, name='classify'),
]
